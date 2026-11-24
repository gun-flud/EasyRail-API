import fp from 'fastify-plugin';
import type { FastifyInstance } from 'fastify';
import type { Pool } from 'pg';
import { createPool, checkDbConnection } from '../db/pool.js';

declare module 'fastify' {
	interface FastifyInstance {
		db: Pool;
	}
}

interface DbPluginOptions {
    connectingString: string;
}

async function DbPlugin (fastify: FastifyInstance, opts: DbPluginOptions): Promise<void> {
    const pool = createPool(opts.connectingString);

    pool.on('error', (err: Error) => {
        fastify.log.error(err, "Postgres pool error");
    });

    try {
        checkDbConnection(pool);
    } catch (err) {
        await pool.end();
        throw err;
    }

    fastify.decorate('db', pool);

    fastify.addHook('onClose', async () => {
        await pool.end()
    });
}

export default fp(DbPlugin, {name: 'db'});