import fp from 'fastify-plugin';
import type { FastifyInstance } from 'fastify';
import type { Pool } from 'pg';
import { createPool, checkDbConnection } from '../db/pool.js';

declare module 'fastify' {
	interface FastifyInstance {
		db: Pool;
	}
}

export interface DbPluginOptions {
	connectionString?: string;
	pool?: Pool;
}

async function dbPlugin(fastify: FastifyInstance, opts: DbPluginOptions): Promise<void> {
	
	const pool = opts.pool ?? (opts.connectionString ? createPool(opts.connectionString) : null);

	if (!pool) {
		throw new Error('dbPlugin requires either "pool" or "connectionString"');
	}

	pool.on('error', (err: Error) => {
		fastify.log.error(err, 'Postgres pool error');
	});

	try {
		await checkDbConnection(pool);
	} catch (err) {
		if (!opts.pool) await pool.end();
		throw err;
	}

	fastify.decorate('db', pool);

	fastify.addHook('onClose', async () => {
		if (!opts.pool) await pool.end();
	});
}

export default fp(dbPlugin, { name: 'db' });