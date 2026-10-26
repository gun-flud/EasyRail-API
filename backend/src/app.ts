import Fastify, { type FastifyServerOptions } from 'fastify';

export function buildApp(options: { logger?: FastifyServerOptions['logger'] } = {}) {
	const app = Fastify({
		logger: options.logger ?? false,
	});

	app.get('/health', () => {
		return { status: 'ok' };
	});

	return app;
}
