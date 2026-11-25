import { Pool } from 'pg';


export function createPool(connectionString: string): Pool {
	const pool = new Pool({
		connectionString,
		max: 10,
		idleTimeoutMillis: 30_000,
		connectionTimeoutMillis: 5_000,
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
