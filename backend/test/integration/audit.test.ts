import type { Pool } from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { isPostgresError } from '../../src/db/errors.js';
import { withTransaction } from '../../src/db/transaction.js';
import { logAction } from '../../src/modules/audit/audit.service.js';
import { setupTestDb, truncateAllTables } from '../helpers/db.js';

describe('audit.service logAction', () => {
	let pool: Pool;

	beforeAll(async () => {
		pool = await setupTestDb();
	});

	beforeEach(async () => {
		await truncateAllTables(pool);
	});

	afterAll(async () => {
		if (pool) {
			await pool.end();
		}
	});

	it('inserts audit log row with userId and metadata', async () => {
		const userRes = await pool.query<{ user_id: string }>(
			`INSERT INTO users (user_name, hashed_password, email, user_role)
			 VALUES ('audit_user', 'hashed_pw', 'audit@test.com', 'PASSENGER')
			 RETURNING user_id`,
		);
		const userId = userRes.rows[0]?.user_id;
		expect(userId).toBeTypeOf('string');

		const created = await logAction(pool, {
			userId,
			action: 'PASSENGER_CREATED',
			metadata: { passengerName: 'Тарас' },
		});

		expect(created.log_id).toBeTypeOf('string');
		expect(created.user_id).toBe(userId);
		expect(created.action).toBe('PASSENGER_CREATED');
		expect(created.metadata).toEqual({ passengerName: 'Тарас' });
		expect(created.created_at).toBeInstanceOf(Date);
	});

	it('inserts audit log row when userId is null', async () => {
		const created = await logAction(pool, {
			userId: null,
			action: 'SYSTEM_STARTUP',
		});

		expect(created.user_id).toBeNull();
		expect(created.metadata).toEqual({});
	});

	it('rejects blank action with PostgreSQL CHECK constraint (23514)', async () => {
		try {
			await logAction(pool, { action: '   ' });
			expect.unreachable('Expected CHECK constraint error 23514');
		} catch (error) {
			expect(isPostgresError(error)).toBe(true);
			if (isPostgresError(error)) {
				expect(error.code).toBe('23514');
			}
		}
	});

	it('rolls back audit log when transaction fails', async () => {
		await expect(
			withTransaction(pool, async client => {
				await logAction(client, { action: 'WILL_ROLLBACK' });
				throw new Error('Simulated failure');
			}),
		).rejects.toThrow('Simulated failure');

		const countRes = await pool.query<{ count: number }>(
			'SELECT COUNT(*)::int AS count FROM system_logs',
		);
		expect(countRes.rows[0]?.count).toBe(0);
	});
});