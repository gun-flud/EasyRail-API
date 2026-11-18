import 'dotenv/config';
import { buildApp } from './app.js';
import { env } from './config/env.js';
import { loggerOptions } from './config/logger.js';
import { createPool } from './db/pool.js';

const pool = env.DATABASE_URL ? createPool(env.DATABASE_URL) : undefined;

const app = buildApp({
	logger: loggerOptions(),
	pool,
	closePoolOnClose: true,
});

async function shutdown(signal: string) {
	app.log.info(`${signal} received, shutting down`);

	try {
		await app.close();
		process.exit(0);
	} catch (err) {
		app.log.error(err);
		process.exit(1);
	}
}

process.on('SIGTERM', () => {
	void shutdown('SIGTERM');
});
process.on('SIGINT', () => {
	void shutdown('SIGINT');
});

async function start() {
	try {
		await app.listen({
			port: env.PORT,
			host: '0.0.0.0',
		});
	} catch (err) {
		app.log.error(err);
		process.exit(1);
	}
}

await start();
