import type { Pool, PoolClient } from 'pg';
import type { Logger } from '../config/logger.js';

export async function withTransaction<T>(
	pool: Pool,
	fn: (client: PoolClient) => Promise<T>,
	logger?: Logger,
): Promise<T> {
	const client = await pool.connect();
	let shouldDestroyClient = false;
	try {
		await client.query('BEGIN');
		const result = await fn(client);
		await client.query('COMMIT');
		return result;
	} catch (error) {
		try {
			await client.query('ROLLBACK');
		} catch (rollbackError) {
			shouldDestroyClient = true;
			logger?.error(rollbackError, 'Failed to rollback PostgreSQL transaction');
		}
		throw error;
	} finally {
		client.release(shouldDestroyClient);
	}
}
