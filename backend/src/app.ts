import Fastify from 'fastify';
import type { Pool } from 'pg';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { serializerCompiler, validatorCompiler } from 'fastify-type-provider-zod';

import type { Logger } from './config/logger.js';
import { checkDbConnection } from './db/pool.js';
import { errorHandler } from './shared/errors/errorHandler.js';
import { logger } from './config/logger.js';
import dbPlugin from './plugins/db.js';

export interface BuildAppOptions {
	logger?: Logger | boolean;
	pool?: Pool;
	databaseUrl?: string;
}

function resolveLoggerOptions(loggerOpt?: Logger | boolean) {
	return typeof loggerOpt === 'boolean'
		? { logger: loggerOpt }
		: { loggerInstance: loggerOpt ?? logger };
}

export function buildApp(options: BuildAppOptions = {}) {
	const app = Fastify(resolveLoggerOptions(options.logger)).withTypeProvider<ZodTypeProvider>();

	app.setValidatorCompiler(validatorCompiler);
	app.setSerializerCompiler(serializerCompiler);

	app.setErrorHandler(errorHandler);


	app.get('/health', () => {
		return { status: 'ok' };
	});


	if (options.pool || options.databaseUrl) {
		void app.register(dbPlugin, {
			pool: options.pool,
			connectionString: options.databaseUrl,
		});

		app.get('/health/ready', async (_request, reply) => {
			try {
				await checkDbConnection(app.db);
				return { status: 'ok', db: 'healthy' };
			} catch (err) {
				app.log.error(err, 'Database readiness check failed');
				return reply.status(503).send({ status: 'error', db: 'unhealthy' });
			}
		});
	}

	return app;
}
