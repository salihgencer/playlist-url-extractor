import { describe, expect, it, vi } from "vitest";
import worker, { handle, mapYouTubeError, type Deps, type Env, type PlaylistResponse } from "../src/index";

const KEY = "test-secret-key";
const BASE = "https://api.salihgencer.com/playlist-url-extractor";

// YouTube Data API v3 hata gövdeleri (playlistItems.list belgesindeki reason/status değerleri).
const ytError = (code: number, reason: string, domain = "youtube.playlistItem") => ({
  error: { code, message: reason, errors: [{ message: reason, domain, reason }] },
});

const item = (videoId: string, title: string, published = true) => ({
  snippet: { title, resourceId: { videoId } },
  contentDetails: published ? { videoId, videoPublishedAt: "2026-05-20T17:00:00Z" } : { videoId },
});

const keyOf = (r: RequestInfo | URL) => (typeof r === "string" ? r : r instanceof URL ? r.href : r.url);

type Route = (url: URL) => { status: number; body: unknown };

function setup(route: Route, opts: { limiter?: boolean; allow?: boolean; cache?: boolean } = {}) {
  const calls: URL[] = [];
  const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
    const url = new URL(String(input));
    calls.push(url);
    const { status, body } = route(url);
    return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
  });
  const store = new Map<string, Response>();
  const cache: Deps["cache"] = opts.cache === false ? null : {
    match: async (req) => store.get(keyOf(req))?.clone(),
    put: async (req, res) => void store.set(keyOf(req), res.clone()),
  };
  const limit = vi.fn(async () => ({ success: opts.allow ?? true }));
  const env: Env = { YT_API_KEY: KEY, CACHE_TTL_SECONDS: "600", ...(opts.limiter ? { RATE_LIMITER: { limit } } : {}) };
  const pending: Promise<unknown>[] = [];
  const ctx = { waitUntil: (p: Promise<unknown>) => void pending.push(p) };
  const call = async (path: string, init?: RequestInit) => {
    const res = await handle(new Request(`${BASE}${path}`, init), env, ctx, { fetch: fetchMock as unknown as typeof fetch, cache });
    await Promise.all(pending);
    return res;
  };
  return { call, calls, fetchMock, limit, store, env };
}

const okRoute: Route = (url) => {
  if (url.pathname.endsWith("/playlists")) return { status: 200, body: { items: [{ snippet: { title: "Google I/O Keynotes" } }] } };
  const token = url.searchParams.get("pageToken");
  if (!token) {
    return {
      status: 200,
      body: {
        nextPageToken: "CDIQAA",
        pageInfo: { totalResults: 3 },
        items: [item("aaaaaaaaaaa", "Keynote"), item("ppppppppppp", "Private video", false)],
      },
    };
  }
  return { status: 200, body: { pageInfo: { totalResults: 3 }, items: [item("bbbbbbbbbbb", "Developer keynote")] } };
};

describe("GET /playlist", () => {
  it("returns only id/title, counts unavailable items and adds the title on page one", async () => {
    const { call, calls } = setup(okRoute);
    const res = await call("/playlist?id=PLabc_-123");
    expect(res.status).toBe(200);
    const body = (await res.json()) as PlaylistResponse;
    expect(body).toEqual({
      playlist: { id: "PLabc_-123", title: "Google I/O Keynotes" },
      items: [{ videoId: "aaaaaaaaaaa", title: "Keynote" }],
      unavailable: 1,
      nextPageToken: "CDIQAA",
      totalResults: 3,
    });
    const items = calls.find((u) => u.pathname.endsWith("/playlistItems"))!;
    expect(items.searchParams.get("playlistId")).toBe("PLabc_-123");
    expect(items.searchParams.get("maxResults")).toBe("50");
    expect(items.searchParams.get("key")).toBe(KEY);
    expect(calls.some((u) => u.pathname.endsWith("/playlists"))).toBe(true);
  });

  it("forwards pageToken and skips the title lookup on later pages", async () => {
    const { call, calls } = setup(okRoute);
    const res = await call("/playlist?id=PLabc&pageToken=CDIQAA");
    const body = (await res.json()) as PlaylistResponse;
    expect(body.items).toEqual([{ videoId: "bbbbbbbbbbb", title: "Developer keynote" }]);
    expect(body.nextPageToken).toBeNull();
    expect(body.playlist.title).toBeNull();
    expect(calls).toHaveLength(1);
    expect(calls[0]!.searchParams.get("pageToken")).toBe("CDIQAA");
  });

  it("walks a 100-page playlist without hitting the per-IP limit", async () => {
    const { call } = setup((url) => {
      const page = Number(url.searchParams.get("pageToken")?.slice(1) ?? "0");
      if (url.pathname.endsWith("/playlists")) return { status: 200, body: { items: [] } };
      return {
        status: 200,
        body: {
          nextPageToken: page < 99 ? `p${page + 1}` : undefined,
          items: Array.from({ length: 50 }, (_, i) => item(`v${String(page).padStart(3, "0")}_${String(i).padStart(5, "0")}`, "x")),
        },
      };
    });
    let token: string | null = null;
    let total = 0;
    for (let i = 0; i < 101; i++) {
      const res = await call(`/playlist?id=UUbig${token ? `&pageToken=${token}` : ""}`);
      expect(res.status).toBe(200);
      const body = (await res.json()) as PlaylistResponse;
      total += body.items.length;
      token = body.nextPageToken;
      if (!token) break;
    }
    expect(total).toBe(5000);
  });

  it("never leaks the API key in any response", async () => {
    const { call } = setup(() => ({ status: 400, body: { error: { code: 400, message: `bad key ${KEY}`, errors: [{ reason: "keyInvalid", domain: "usageLimits" }] } } }));
    const res = await call("/playlist?id=PLabc");
    expect(res.status).toBe(502);
    expect(await res.text()).not.toContain(KEY);
  });
});

describe("validation", () => {
  it.each([
    ["/playlist", "INVALID_ID", 400],
    ["/playlist?id=a", "INVALID_ID", 400],
    ["/playlist?id=PL%3Cscript%3E", "INVALID_ID", 400],
    [`/playlist?id=${"x".repeat(65)}`, "INVALID_ID", 400],
    ["/playlist?id=RDdQw4w9WgXcQ", "PLAYLIST_UNSUPPORTED", 400],
    ["/playlist?id=WL", "PLAYLIST_UNSUPPORTED", 400],
    ["/playlist?id=PLabc&pageToken=bad%20token", "INVALID_PAGE_TOKEN", 400],
    ["/other", "NOT_FOUND", 404],
  ])("%s → %s", async (path, code, status) => {
    const { call, fetchMock } = setup(okRoute);
    const res = await call(path);
    expect(res.status).toBe(status);
    expect(((await res.json()) as { error: string }).error).toBe(code);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects non-GET methods", async () => {
    const { call } = setup(okRoute);
    const res = await call("/playlist?id=PLabc", { method: "POST" });
    expect(res.status).toBe(405);
  });

  it("reports misconfiguration when the secret is missing", async () => {
    const { call, env } = setup(okRoute);
    env.YT_API_KEY = "";
    expect((await call("/playlist?id=PLabc")).status).toBe(500);
  });

  it("serves /health", async () => {
    const { call } = setup(okRoute);
    expect(await (await call("/health")).json()).toEqual({ ok: true });
  });
});

describe("YouTube errors", () => {
  it.each([
    [404, ytError(404, "playlistNotFound"), 404, "PLAYLIST_NOT_FOUND"],
    [403, ytError(403, "playlistItemsNotAccessible"), 403, "PLAYLIST_PRIVATE"],
    [400, ytError(400, "playlistOperationUnsupported"), 400, "PLAYLIST_UNSUPPORTED"],
    [403, ytError(403, "watchLaterNotAccessible"), 400, "PLAYLIST_UNSUPPORTED"],
    [403, ytError(403, "quotaExceeded", "youtube.quota"), 503, "QUOTA_EXCEEDED"],
    [400, ytError(400, "invalidPageToken"), 400, "INVALID_PAGE_TOKEN"],
    [500, ytError(500, "backendError", "global"), 502, "UPSTREAM_ERROR"],
  ])("%i %j → %i", async (ytStatus, body, status, code) => {
    const { call, store } = setup((url) =>
      url.pathname.endsWith("/playlists") ? { status: 200, body: { items: [] } } : { status: ytStatus, body },
    );
    const res = await call("/playlist?id=PLabc");
    expect(res.status).toBe(status);
    expect(((await res.json()) as { error: string }).error).toBe(code);
    expect(store.size).toBe(0); // hata yanıtları önbelleğe alınmaz
  });

  it("maps network failures to UPSTREAM_ERROR", async () => {
    const env: Env = { YT_API_KEY: KEY };
    const res = await handle(new Request(`${BASE}/playlist?id=PLabc`), env, { waitUntil() {} }, {
      fetch: (async () => { throw new TypeError("network"); }) as unknown as typeof fetch,
      cache: null,
    });
    expect(res.status).toBe(502);
  });

  it("mapYouTubeError falls back on status", () => {
    expect(mapYouTubeError(404, null)).toBe("PLAYLIST_NOT_FOUND");
    expect(mapYouTubeError(500, null)).toBe("UPSTREAM_ERROR");
  });
});

describe("rate limit and cache", () => {
  it("returns 429 with Retry-After when the limiter refuses", async () => {
    const { call, limit, fetchMock } = setup(okRoute, { limiter: true, allow: false });
    const res = await call("/playlist?id=PLabc", { headers: { "CF-Connecting-IP": "203.0.113.7" } });
    expect(res.status).toBe(429);
    expect(res.headers.get("Retry-After")).toBe("60");
    expect(limit).toHaveBeenCalledWith({ key: "203.0.113.7" });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("serves the second identical request from cache", async () => {
    const { call, fetchMock } = setup(okRoute);
    const first = await call("/playlist?id=PLabc");
    expect(first.headers.get("X-Cache")).toBe("MISS");
    const callsAfterFirst = fetchMock.mock.calls.length;
    const second = await call("/playlist?id=PLabc");
    expect(second.headers.get("X-Cache")).toBe("HIT");
    expect(fetchMock.mock.calls.length).toBe(callsAfterFirst);
    expect(await second.json()).toEqual(await first.clone().json());
  });

  it("default export wires the handler", () => {
    expect(typeof worker.fetch).toBe("function");
  });
});
