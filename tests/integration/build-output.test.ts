/**
 * Integration test: verifies the actual Astro build output, not mocked
 * behaviour. Must run AFTER `npm run build` (the Jenkinsfile always runs
 * Build before Test, so `dist/` is guaranteed to exist in CI).
 */
import { describe, it, expect } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const DIST_DIR = join(process.cwd(), "dist");

describe("production build output", () => {
    it("produced a dist/ directory", () => {
        expect(existsSync(DIST_DIR)).toBe(true);
    });

    it("produced a home page with the site title", () => {
        const indexPath = join(DIST_DIR, "index.html");
        expect(existsSync(indexPath)).toBe(true);
        const html = readFileSync(indexPath, "utf-8");
        expect(html).toMatch(/Thoth Tech/i);
    });

    it("did not leak an unhandled server error page", () => {
        const indexPath = join(DIST_DIR, "index.html");
        const html = readFileSync(indexPath, "utf-8");
        expect(html).not.toMatch(/Internal Server Error/i);
    });
});
