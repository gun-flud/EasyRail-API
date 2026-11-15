import { Pool } from 'pg';
import type { PoolClient, QueryResult, QueryResultRow } from 'pg';

export interface QueryExecutor {
	query<T extends QueryResultRow = QueryResultRow>(
		text: string,
		params?: unknown[],
	): Promise<QueryResult<T>>;
}

export function createPool(connectionString: string): Pool {
	const pool = new Pool({
		connectionString,
		max: 10,
		idleTimeoutMillis: 30_000,
		connectionTimeoutMillis: 5_000,
	});

	pool.on('error', (err: Error) => {
		console.error('Unexpected PostgreSQL pool error:', err);
	});

	return pool;
}

export async function checkDbConnection(executor: QueryExecutor): Promise<void> {
	await executor.query('SELECT 1');
}

export type { Pool, PoolClient, QueryResult, QueryResultRow };
