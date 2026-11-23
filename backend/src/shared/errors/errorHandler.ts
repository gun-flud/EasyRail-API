import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import {
	hasZodFastifySchemaValidationErrors,
	isResponseSerializationError,
} from 'fastify-type-provider-zod';
import { AppError } from './app-error.js';
import { isPostgresError } from '../../db/errors.js';

export const errorHandler = (
	error: FastifyError | Error,
	request: FastifyRequest,
	reply: FastifyReply,
) => {
	if (hasZodFastifySchemaValidationErrors(error)) {
		return reply.status(400).send({
			code: 'VALIDATION_ERROR',
			message: 'Request validation failed',
			details: error.validation,
		});
	}

	if (isResponseSerializationError(error)) {
		request.log.error(error, 'Response serialization failed');
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

	request.log.error(error);
	return reply.status(500).send({
		code: 'INTERNAL_SERVER_ERROR',
		message: 'Internal server error',
	});
};
