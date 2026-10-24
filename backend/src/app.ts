import Fastify, { type FastifyServerOptions } from "fastify";

export default function buildApp(options: { logger?: FastifyServerOptions['logger'] } = {}) {
    const app = Fastify({
        logger: options.logger ?? false
    });

    app.get("/health", (request, reply) => {
        return {status: "ok"}
    });

    return app;
}
