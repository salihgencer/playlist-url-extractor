import { defineConfig } from "vitest/config";

// Worker saf fetch/Response API'leri kullanır; Node 22'de doğrudan test edilir.
// Cache ve rate limiter bağımlılık olarak enjekte edilir (test/index.spec.ts).
export default defineConfig({
  test: { environment: "node" },
});
