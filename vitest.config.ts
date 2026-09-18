import { defineConfig } from "vitest/config";

export default defineConfig({
    test: {
        environment: "node",
        include: ["tests/**/*.test.ts"],
        reporters: process.env.CI ? ["default", "junit"] : ["default"],
        outputFile: { junit: "reports/junit.xml" },
        coverage: {
            provider: "v8",
            reporter: ["text", "lcov"],
            reportsDirectory: "coverage",
            include: ["src/utils/**/*.ts"],
        },
    },
});
