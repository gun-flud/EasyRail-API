import { env } from './env.js';
import { pino } from 'pino';
import type { FastifyBaseLogger } from 'fastify';

export const logger = pino(
	env.NODE_ENV === 'development'
		? {
				level: env.LOG_LEVEL,
				transport: {
					target: 'pino-pretty',
					options: {
						colorize: true,
						translateTime: 'HH:MM:ss',
						ignore: 'pid,hostname',
					},
				},
			}
		: { level: env.LOG_LEVEL },
);

export type Logger = FastifyBaseLogger;
