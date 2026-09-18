/**
 * Small pure-function utilities used by the docs site, extracted so they are
 * independently unit-testable (the pipeline's Test stage needs real logic to
 * exercise, not just a placeholder).
 */

/** Estimated reading time in whole minutes, at 200 words/minute, minimum 1. */
export function getReadingTime(text: string): number {
    const words = text
        .trim()
        .split(/\s+/)
        .filter((w) => w.length > 0);
    if (words.length === 0) return 0;
    return Math.max(1, Math.round(words.length / 200));
}

/** URL-safe slug from a page title: lowercase, hyphenated, punctuation stripped. */
export function slugify(title: string): string {
    return title
        .toLowerCase()
        .trim()
        .replace(/['"]/g, "")
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "");
}

/** True if a frontmatter object has the minimum fields Starlight needs to render a page. */
export function hasRequiredFrontmatter(frontmatter: Record<string, unknown>): boolean {
    return typeof frontmatter.title === "string" && frontmatter.title.trim().length > 0;
}
