import { describe, it, expect } from "vitest";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, extname } from "node:path";
import { hasRequiredFrontmatter } from "../../src/utils/content-helpers";

const CONTENT_DIR = join(process.cwd(), "src", "content", "docs");

function walk(dir: string): string[] {
    let results: string[] = [];
    for (const entry of readdirSync(dir)) {
        const full = join(dir, entry);
        const stat = statSync(full);
        if (stat.isDirectory()) {
            results = results.concat(walk(full));
        } else if ([".md", ".mdx"].includes(extname(entry))) {
            results.push(full);
        }
    }
    return results;
}

function parseFrontmatter(raw: string): Record<string, unknown> {
    const clean = raw.replace(/^\uFEFF/, ""); // strip BOM some Word→Markdown exports add
    const match = clean.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!match) return {};
    const fm: Record<string, unknown> = {};
    let currentKey: string | null = null;
    for (const line of match[1].split(/\r?\n/)) {
        const kv = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
        if (kv) {
            currentKey = kv[1];
            fm[currentKey] = kv[2].replace(/^["']|["']$/g, "");
        } else if (currentKey && /^\s+\S/.test(line)) {
            // continuation of a YAML folded/multi-line scalar, e.g.:
            //   title:
            //     The actual title text
            fm[currentKey] = `${fm[currentKey]} ${line.trim()}`.trim();
        }
    }
    return fm;
}

describe("content frontmatter", () => {
    const files = walk(CONTENT_DIR);

    it("finds documentation pages to check", () => {
        expect(files.length).toBeGreaterThan(0);
    });

    it("every docs page declares a non-empty title", () => {
        const missing = files.filter((f) => {
            const fm = parseFrontmatter(readFileSync(f, "utf-8"));
            return !hasRequiredFrontmatter(fm);
        });
        expect(missing, `Pages missing a title: ${missing.join(", ")}`).toEqual([]);
    });
});
