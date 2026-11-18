import type { Pool, PoolClient } from 'pg';

export async function withTransaction<T>(
	pool: Pool,
	fn: (client: PoolClient) => Promise<T>,
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
			console.error('Failed to rollback PostgreSQL transaction:', rollbackError);
		}
		throw error;
	} finally {
		client.release();
	}
}
