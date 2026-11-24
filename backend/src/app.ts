import Fastify from 'fastify';
import type { Logger } from './config/logger.js';
import type { Pool } from 'pg';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { serializerCompiler, validatorCompiler } from 'fastify-type-provider-zod';
import { checkDbConnection } from './db/pool.js';
import { errorHandler } from './shared/errors/errorHandler.js';
import { logger } from './config/logger.js';

export interface BuildAppOptions {
	logger?: Logger | boolean;
	pool?: Pool;
	closePoolOnClose?: boolean;
}

export function buildApp(options: BuildAppOptions = {}) {
	const app = Fastify({ loggerInstance: logger }).withTypeProvider<ZodTypeProvider>();

	app.setValidatorCompiler(validatorCompiler);
	app.setSerializerCompiler(serializerCompiler);

	app.setErrorHandler(errorHandler);


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
