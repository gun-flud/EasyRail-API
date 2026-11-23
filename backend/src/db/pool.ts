import type { Logger } from '../config/logger.js';
import { Pool } from 'pg';
import type { PoolClient, QueryResult, QueryResultRow } from 'pg';

export interface QueryExecutor {
	query<T extends QueryResultRow = QueryResultRow>(
		text: string,
		params?: unknown[],
	): Promise<QueryResult<T>>;
}

export function createPool(connectionString: string, logger?: Logger): Pool {
	const pool = new Pool({
		connectionString,
		max: 10,
		idleTimeoutMillis: 30_000,
		connectionTimeoutMillis: 5_000,
	});

	pool.on('error', (err: Error) => {
		logger?.error(err, 'Unexpected PostgreSQL pool error');
	});

	return pool;
}

export async function checkDbConnection(pool: Pool, timeoutMs = 2_000): Promise<void> {
	const client = await pool.connect();
	let timer: ReturnType<typeof setTimeout> | undefined;
	let shouldDestroy = false;

	try {
		const query = client.query('SELECT 1');
		query.catch(() => {});

		const timeout = new Promise<never>((_resolve, reject) => {
			timer = setTimeout(() => reject(new Error('DB readiness timeout')), timeoutMs);
		});

		await Promise.race([query, timeout]);
	} catch (err) {
		shouldDestroy = true;
		throw err;
	} finally {
		clearTimeout(timer);
		client.release(shouldDestroy);
	}
}

export type { Pool, PoolClient, QueryResult, QueryResultRow };
