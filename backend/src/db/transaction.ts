import type { Pool, PoolClient } from 'pg';
import type { DbLogger } from './pool.js';

export async function withTransaction<T>(
	pool: Pool,
	fn: (client: PoolClient) => Promise<T>,
	logger?: DbLogger,
): Promise<T> {
	const client = await pool.connect();
	try {
		await client.query('BEGIN');
		const result = await fn(client);
		await client.query('COMMIT');
		return result;
	} catch (error) {
		try {
			await client.query('ROLLBACK');
		} catch (rollbackError) {
			logger?.error(rollbackError, 'Failed to rollback PostgreSQL transaction');
		}
		throw error;
	} finally {
		client.release();
	}
}
