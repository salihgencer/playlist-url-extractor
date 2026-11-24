/**
 * Playlist URL Extractor — YouTube Data API v3 vekili.
 *
 * GET /playlist-url-extractor/playlist?id=<playlistId>[&pageToken=<token>]
 *   → 200 { playlist: { id, title }, items: [{ videoId, title }], unavailable, nextPageToken, totalResults }
 *   → 4xx/5xx { error: <KOD>, message }   (kodlar: Sources/PlaylistURLExtractorKit/ProxyPlaylistSource.swift)
 *
 * - API anahtarı (YT_API_KEY) yalnız burada, secret olarak durur; yanıtlara asla sızmaz.
 * - Yalnız video kimliği ve başlığı döner; açıklama, küçük resim vb. aktarılmaz.
 * - IP başına oran sınırı (Workers Rate Limiting) ve başarılı yanıtlar için kısa edge önbelleği.
 */

export interface Env {
  YT_API_KEY: string;
  CACHE_TTL_SECONDS?: string;
  RATE_LIMITER?: { limit(options: { key: string }): Promise<{ success: boolean }> };
}

/** Test için enjekte edilebilen bağımlılıklar. */
export interface Deps {
  fetch: typeof fetch;
  cache: Pick<Cache, "match" | "put"> | null;
}

export const PREFIX = "/playlist-url-extractor";
const YT_BASE = "https://www.googleapis.com/youtube/v3";
const ID_PATTERN = /^[A-Za-z0-9_-]{2,64}$/;
const TOKEN_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const UNAVAILABLE_TITLES = new Set(["Private video", "Deleted video"]);

export type ErrorCode =
  | "INVALID_ID"
  | "INVALID_PAGE_TOKEN"
  | "PLAYLIST_UNSUPPORTED"
  | "PLAYLIST_NOT_FOUND"
  | "PLAYLIST_PRIVATE"
  | "QUOTA_EXCEEDED"
  | "RATE_LIMITED"
  | "UPSTREAM_ERROR"
  | "NOT_FOUND"
  | "METHOD_NOT_ALLOWED"
  | "MISCONFIGURED";

const ERROR_STATUS: Record<ErrorCode, number> = {
  INVALID_ID: 400,
  INVALID_PAGE_TOKEN: 400,
  PLAYLIST_UNSUPPORTED: 400,
  PLAYLIST_NOT_FOUND: 404,
  PLAYLIST_PRIVATE: 403,
  QUOTA_EXCEEDED: 503,
  RATE_LIMITED: 429,
  UPSTREAM_ERROR: 502,
  NOT_FOUND: 404,
  METHOD_NOT_ALLOWED: 405,
  MISCONFIGURED: 500,
};

const ERROR_MESSAGE: Record<ErrorCode, string> = {
  INVALID_ID: "Invalid playlist id.",
  INVALID_PAGE_TOKEN: "Invalid page token.",
  PLAYLIST_UNSUPPORTED: "This kind of playlist cannot be listed.",
  PLAYLIST_NOT_FOUND: "Playlist not found.",
  PLAYLIST_PRIVATE: "Playlist is private.",
  QUOTA_EXCEEDED: "Daily quota exceeded.",
  RATE_LIMITED: "Too many requests.",
  UPSTREAM_ERROR: "Upstream service error.",
  NOT_FOUND: "Not found.",
  METHOD_NOT_ALLOWED: "Method not allowed.",
  MISCONFIGURED: "Service is not configured.",
};

export interface PlaylistResponse {
  playlist: { id: string; title: string | null };
  items: { videoId: string; title: string }[];
  unavailable: number;
  nextPageToken: string | null;
  totalResults: number | null;
}

function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      ...headers,
    },
  });
}

function fail(code: ErrorCode, headers: Record<string, string> = {}): Response {
  return json({ error: code, message: ERROR_MESSAGE[code] }, ERROR_STATUS[code], headers);
}

class UpstreamError extends Error {
  constructor(readonly code: ErrorCode) {
    super(code);
  }
}

/** YouTube hata gövdesindeki `reason` değerini istemci koduna çevirir (playlistItems.list belgesi). */
export function mapYouTubeError(status: number, body: unknown): ErrorCode {
  const errors = (body as { error?: { errors?: { reason?: string; domain?: string }[] } })?.error?.errors ?? [];
  const reasons = errors.map((e) => e.reason ?? "");
  const domains = errors.map((e) => e.domain ?? "");
  if (reasons.includes("playlistNotFound")) return "PLAYLIST_NOT_FOUND";
  if (reasons.includes("playlistItemsNotAccessible")) return "PLAYLIST_PRIVATE";
  if (
    reasons.includes("playlistOperationUnsupported") ||
    reasons.includes("watchHistoryNotAccessible") ||
    reasons.includes("watchLaterNotAccessible")
  ) {
    return "PLAYLIST_UNSUPPORTED";
  }
  if (reasons.includes("invalidPageToken")) return "INVALID_PAGE_TOKEN";
  if (
    reasons.some((r) => r === "quotaExceeded" || r === "dailyLimitExceeded" || r === "rateLimitExceeded") ||
    domains.includes("youtube.quota")
  ) {
    return "QUOTA_EXCEEDED";
  }
  if (status === 404) return "PLAYLIST_NOT_FOUND";
  return "UPSTREAM_ERROR";
}

async function callYouTube(deps: Deps, path: string, params: Record<string, string>, key: string): Promise<unknown> {
  const url = new URL(`${YT_BASE}/${path}`);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  url.searchParams.set("key", key);
  let res: Response;
  try {
    res = await deps.fetch(url.toString(), { headers: { Accept: "application/json" } });
  } catch {
    throw new UpstreamError("UPSTREAM_ERROR");
  }
  let body: unknown = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }
  if (!res.ok) throw new UpstreamError(mapYouTubeError(res.status, body));
  return body;
}

interface ItemsBody {
  nextPageToken?: string;
  pageInfo?: { totalResults?: number };
  items?: {
    snippet?: { title?: string; resourceId?: { videoId?: string } };
    contentDetails?: { videoId?: string; videoPublishedAt?: string };
  }[];
}

async function fetchPage(deps: Deps, env: Env, id: string, pageToken: string | null): Promise<PlaylistResponse> {
  const itemsParams: Record<string, string> = {
    part: "snippet,contentDetails",
    playlistId: id,
    maxResults: "50",
    fields:
      "nextPageToken,pageInfo/totalResults,items(snippet(title,resourceId/videoId),contentDetails(videoId,videoPublishedAt))",
  };
  if (pageToken) itemsParams.pageToken = pageToken;

  // Başlık yalnız ilk sayfada (playlists.list, 1 birim kota) istenir.
  const [itemsBody, titleBody] = await Promise.all([
    callYouTube(deps, "playlistItems", itemsParams, env.YT_API_KEY) as Promise<ItemsBody>,
    pageToken
      ? Promise.resolve(null)
      : (callYouTube(deps, "playlists", { part: "snippet", id, fields: "items(snippet/title)" }, env.YT_API_KEY).catch(
          () => null,
        ) as Promise<{ items?: { snippet?: { title?: string } }[] } | null>),
  ]);

  const items: PlaylistResponse["items"] = [];
  let unavailable = 0;
  for (const item of itemsBody.items ?? []) {
    const videoId = item.contentDetails?.videoId ?? item.snippet?.resourceId?.videoId;
    const title = item.snippet?.title ?? "";
    const available = Boolean(item.contentDetails?.videoPublishedAt) && !UNAVAILABLE_TITLES.has(title);
    if (!videoId || !ID_PATTERN.test(videoId) || !available) {
      unavailable += 1;
      continue;
    }
    items.push({ videoId, title });
  }

  return {
    playlist: { id, title: titleBody?.items?.[0]?.snippet?.title ?? null },
    items,
    unavailable,
    nextPageToken: itemsBody.nextPageToken ?? null,
    totalResults: itemsBody.pageInfo?.totalResults ?? null,
  };
}

function cacheTTL(env: Env): number {
  const parsed = Number.parseInt(env.CACHE_TTL_SECONDS ?? "", 10);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? Math.min(parsed, 3600) : 600;
}

export async function handle(request: Request, env: Env, ctx: Pick<ExecutionContext, "waitUntil">, deps: Deps): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, "");
  // workers.dev üzerinden önek olmadan da çalışır.
  const route = path.startsWith(PREFIX) ? path.slice(PREFIX.length) : path;

  if (route === "/health") return json({ ok: true });
  if (route !== "/playlist") return fail("NOT_FOUND");
  if (request.method !== "GET" && request.method !== "HEAD") return fail("METHOD_NOT_ALLOWED", { Allow: "GET, HEAD" });
  if (!env.YT_API_KEY) return fail("MISCONFIGURED");

  const id = url.searchParams.get("id") ?? "";
  const pageToken = url.searchParams.get("pageToken");
  if (!ID_PATTERN.test(id)) return fail("INVALID_ID");
  if (id.startsWith("RD") || ["WL", "LL", "HL"].includes(id)) return fail("PLAYLIST_UNSUPPORTED");
  if (pageToken !== null && !TOKEN_PATTERN.test(pageToken)) return fail("INVALID_PAGE_TOKEN");

  if (env.RATE_LIMITER) {
    const key = request.headers.get("CF-Connecting-IP") ?? "unknown";
    const { success } = await env.RATE_LIMITER.limit({ key });
    if (!success) return fail("RATE_LIMITED", { "Retry-After": "60" });
  }

  const cacheKey = new Request(
    `https://cache.invalid${PREFIX}/v1/playlist?id=${encodeURIComponent(id)}&pageToken=${encodeURIComponent(pageToken ?? "")}`,
  );
  const cached = await deps.cache?.match(cacheKey);
  if (cached) {
    const body = await cached.text();
    return new Response(body, { status: 200, headers: { ...Object.fromEntries(json(null).headers), "X-Cache": "HIT" } });
  }

  let page: PlaylistResponse;
  try {
    page = await fetchPage(deps, env, id, pageToken);
  } catch (error) {
    return fail(error instanceof UpstreamError ? error.code : "UPSTREAM_ERROR");
  }

  const ttl = cacheTTL(env);
  if (deps.cache && ttl > 0) {
    const toCache = json(page, 200, { "Cache-Control": `public, max-age=${ttl}` });
    ctx.waitUntil(deps.cache.put(cacheKey, toCache));
  }
  return json(page, 200, { "X-Cache": "MISS" });
}

export default {
  fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const cache = typeof caches !== "undefined" ? (caches as unknown as { default: Cache }).default : null;
    return handle(request, env, ctx, { fetch: (input, init) => fetch(input, init), cache });
  },
} satisfies ExportedHandler<Env>;
