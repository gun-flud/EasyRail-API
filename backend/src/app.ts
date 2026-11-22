import * as z from 'zod';
import Fastify from 'fastify';
import type { FastifyServerOptions } from 'fastify';
import {
	hasZodFastifySchemaValidationErrors,
	isResponseSerializationError,
	serializerCompiler,
	validatorCompiler,
} from 'fastify-type-provider-zod';
import type { ZodTypeProvider } from 'fastify-type-provider-zod';
import { AppError, isPostgresError } from './db/errors.js';
import { checkDbConnection } from './db/pool.js';
import type { Pool } from './db/pool.js';

export interface BuildAppOptions {
	logger?: FastifyServerOptions['logger'] | undefined;
	pool?: Pool | undefined;
	closePoolOnClose?: boolean | undefined;
}

export function buildApp(options: BuildAppOptions = {}) {
	const app = Fastify({
		logger: options.logger ?? false,
	});

	app.setValidatorCompiler(validatorCompiler);
	app.setSerializerCompiler(serializerCompiler);

	app.setErrorHandler((error, _request, reply) => {
		if (hasZodFastifySchemaValidationErrors(error)) {
			return reply.status(400).send({
				code: 'VALIDATION_ERROR',
				message: 'Request validation failed',
				details: error.validation,
			});
		}

		if (isResponseSerializationError(error)) {
			app.log.error(error, 'Response serialization failed');
			return reply.status(500).send({
				code: 'INTERNAL_SERVER_ERROR',
				message: 'Response serialization failed',
			});
		}

		if (error instanceof AppError) {
			return reply.status(error.statusCode).send({
				code: error.code,
				message: error.message,
			});
		}

		if (isPostgresError(error)) {
			if (error.code === '23505') {
				return reply.status(409).send({
					code: 'UNIQUE_VIOLATION',
					message: 'Resource already exists',
				});
			}
			if (error.code === '23503') {
				return reply.status(409).send({
					code: 'FOREIGN_KEY_VIOLATION',
					message: 'Operation violates referential integrity',
				});
			}
			if (error.code === '23514') {
				return reply.status(400).send({
					code: 'CHECK_VIOLATION',
					message: 'Operation violates database check constraint',
				});
			}
		}

		if (
			typeof error === 'object' &&
			error !== null &&
			'statusCode' in error &&
			typeof error.statusCode === 'number' &&
			error.statusCode >= 400 &&
			error.statusCode < 500
		) {
			const code = 'code' in error && typeof error.code === 'string' ? error.code : 'BAD_REQUEST';
			const message = error instanceof Error ? error.message : 'Bad request';
			return reply.status(error.statusCode).send({ code, message });
		}

		app.log.error(error);
		return reply.status(500).send({
			code: 'INTERNAL_SERVER_ERROR',
			message: 'Internal server error',
		});
	});

	if (options.pool && options.closePoolOnClose) {
		const pool = options.pool;
		app.addHook('onClose', async () => {
			await pool.end();
		});
	}

	app.get('/health', () => {
		return { status: 'ok' };
	});

	const typedApp = app.withTypeProvider<ZodTypeProvider>();

	if (options.pool) {
		const pool = options.pool;
		typedApp.get(
			'/health/ready',
			{ schema: { querystring: z.object({}) } },
			async (_request, reply) => {
				try {
					await checkDbConnection(pool);
					return { status: 'ok', db: 'healthy' };
				} catch (err) {
					typedApp.log.error(err, 'Database readiness check failed');
					return reply.status(503).send({ status: 'error', db: 'unhealthy' });
				}
			},
		);
	}

	return typedApp;
}
