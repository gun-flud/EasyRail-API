import { defineConfig } from "vitest/config";

export default defineConfig({
    test : {
        globals: true,
        environment: "node",
        fileParallelism: false,
        coverage : {
            provider: 'v8',
            reporter: ['text', 'html'],
            include: ['src/**/*.ts'],
            exclude: ['src/server.ts', 'src/db/schema.ts', '**/*.test.ts'],
        },
    }, 
});