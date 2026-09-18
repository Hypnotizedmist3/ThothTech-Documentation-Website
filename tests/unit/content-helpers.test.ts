import { describe, it, expect } from "vitest";
import { getReadingTime, slugify, hasRequiredFrontmatter } from "../../src/utils/content-helpers";

describe("getReadingTime", () => {
    it("returns 0 for empty text", () => {
        expect(getReadingTime("")).toBe(0);
        expect(getReadingTime("   ")).toBe(0);
    });

    it("returns at least 1 minute for short text", () => {
        expect(getReadingTime("just a few words here")).toBe(1);
    });

    it("scales at ~200 words per minute", () => {
        const text = Array(600).fill("word").join(" ");
        expect(getReadingTime(text)).toBe(3);
    });
});

describe("slugify", () => {
    it("lowercases and hyphenates", () => {
        expect(slugify("Getting Started With Doubtfire")).toBe("getting-started-with-doubtfire");
    });

    it("strips punctuation and quotes", () => {
        expect(slugify("Thoth Tech's FAQ: What's New?")).toBe("thoth-techs-faq-whats-new");
    });

    it("trims leading/trailing hyphens", () => {
        expect(slugify("  -- Leading & Trailing --  ")).toBe("leading-trailing");
    });
});

describe("hasRequiredFrontmatter", () => {
    it("accepts a page with a non-empty title", () => {
        expect(hasRequiredFrontmatter({ title: "Onboarding Hub" })).toBe(true);
    });

    it("rejects a missing title", () => {
        expect(hasRequiredFrontmatter({})).toBe(false);
    });

    it("rejects a blank title", () => {
        expect(hasRequiredFrontmatter({ title: "   " })).toBe(false);
    });
});
