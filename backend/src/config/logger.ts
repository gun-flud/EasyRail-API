import type { FastifyServerOptions } from 'fastify';
import { env } from './env.js';

export function loggerOptions(): FastifyServerOptions['logger'] {
	if (env.NODE_ENV === 'development') {
		return {
			level: env.LOG_LEVEL,
			transport: {
				target: 'pino-pretty',
				options: {
					colorize: true,
					translateTime: 'HH:MM:ss',
					ignore: 'pid,hostname',
				},
			},
		};
	}

	return { level: env.LOG_LEVEL };
}
