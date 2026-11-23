import Fastify from 'fastify';
import type { FastifyBaseLogger } from 'fastify';
import { serializerCompiler, validatorCompiler } from 'fastify-type-provider-zod';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { checkDbConnection, type Pool } from './db/pool.js';
import { errorHandler } from './shared/errors/errorHandler.js';

export interface BuildAppOptions {
	logger?: FastifyBaseLogger | boolean;
	pool?: Pool;
	closePoolOnClose?: boolean;
}

export function buildApp(options: BuildAppOptions = {}) {
	const app = Fastify({
		logger: options.logger ?? false,
	}).withTypeProvider<ZodTypeProvider>();

	app.setValidatorCompiler(validatorCompiler);
	app.setSerializerCompiler(serializerCompiler);

	app.setErrorHandler(errorHandler);

	if (options.pool && options.closePoolOnClose) {
		const pool = options.pool;
		app.addHook('onClose', async () => {
			await pool.end();
		});
	}

	app.get('/health', () => {
		return { status: 'ok' };
	});

	if (options.pool) {
		const pool = options.pool;
		app.get('/health/ready', async (_request, reply) => {
			try {
				await checkDbConnection(pool);
				return { status: 'ok', db: 'healthy' };
			} catch (err) {
				app.log.error(err, 'Database readiness check failed');
				return reply.status(503).send({ status: 'error', db: 'unhealthy' });
			}
		});
	}

	return app;
}
