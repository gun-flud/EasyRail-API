import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { isPostgresError } from '../../src/db/errors.js';
import type { Pool } from '../../src/db/pool.js';
import { setupTestDb, truncateAllTables } from '../helpers/db.js';

async function expectPgErrorCode(fn: () => Promise<unknown>, expectedCode: string): Promise<void> {
  try {
    await fn();
    expect.unreachable(`Expected PostgreSQL error ${expectedCode}, but query succeeded`);
  } catch (error) {
    expect(isPostgresError(error)).toBe(true);
    if (isPostgresError(error)) {
      expect(error.code).toBe(expectedCode);
    }
  }
}

async function seedTestUser(pool: Pool, email = 'passenger@test.com'): Promise<string> {
  const res = await pool.query<{ user_id: string }>(
    `INSERT INTO users (user_name, hashed_password, email, user_role)
     VALUES ('test_user', 'hashed_pw', $1, 'PASSENGER')
     RETURNING user_id`,
    [email],
  );
  const userId = res.rows[0]?.user_id;
  if (!userId) throw new Error('Failed to seed test user');
  return userId;
}

async function seedTestTicket(pool: Pool): Promise<{ userId: string; ticketId: string }> {
  const userId = await seedTestUser(pool);

  const passengerRes = await pool.query<{ passenger_id: string }>(
    `INSERT INTO passengers (user_id, passenger_lastname, passenger_name)
     VALUES ($1, 'Коваленко', 'Тест')
     RETURNING passenger_id`,
    [userId],
  );
  const passengerId = passengerRes.rows[0]?.passenger_id;

  const fromRes = await pool.query<{ station_id: string }>(
    `INSERT INTO stations (station_name, city) VALUES ('Київ-Тест', 'Київ') RETURNING station_id`,
  );
  const toRes = await pool.query<{ station_id: string }>(
    `INSERT INTO stations (station_name, city) VALUES ('Львів-Тест', 'Львів') RETURNING station_id`,
  );
  const fromStationId = fromRes.rows[0]?.station_id;
  const toStationId = toRes.rows[0]?.station_id;

  const routeRes = await pool.query<{ route_id: string }>(
    `INSERT INTO routes (route_name, base_segment_price, route_number, route_status, schedule_rule, train_type)
     VALUES ('Київ — Львів', 12000, '705T', 'ACTIVE', 'DAILY', 'INTERCITY')
     RETURNING route_id`,
  );
  const routeId = routeRes.rows[0]?.route_id;

  const typeRes = await pool.query<{ carriage_type_id: string }>(
    `INSERT INTO carriage_type_list (carriage_type, carriage_type_price_multiplier, number_of_seats)
     VALUES ('COUPE', 150, 36)
     RETURNING carriage_type_id`,
  );
  const carriageTypeId = typeRes.rows[0]?.carriage_type_id;

  const carriageRes = await pool.query<{ carriage_id: string }>(
    `INSERT INTO carriages (carriage_type_id, route_id, carriage_number)
     VALUES ($1, $2, 1)
     RETURNING carriage_id`,
    [carriageTypeId, routeId],
  );
  const carriageId = carriageRes.rows[0]?.carriage_id;

  const seatRes = await pool.query<{ seat_id: string }>(
    `INSERT INTO seat_templates_list (carriage_type_id, seat_number, is_side, tier_type)
     VALUES ($1, 1, false, 'DOWN')
     RETURNING seat_id`,
    [carriageTypeId],
  );
  const seatId = seatRes.rows[0]?.seat_id;

  const tripRes = await pool.query<{ trip_id: string }>(
    `INSERT INTO trips (route_id, departure_time, trip_status)
     VALUES ($1, NOW() + INTERVAL '2 days', 'SCHEDULED')
     RETURNING trip_id`,
    [routeId],
  );
  const tripId = tripRes.rows[0]?.trip_id;

  const ticketRes = await pool.query<{ ticket_id: string }>(
    `INSERT INTO ticket_segment (
       user_id, passenger_id, trip_id, seat_id, carriage_id,
       from_station_id, to_station_id, from_stop_order, to_stop_order,
       ticket_status, price,
       passenger_lastname, passenger_name, from_station_name, to_station_name,
       departure_time, arrival_time
     )
     VALUES (
       $1, $2, $3, $4, $5,
       $6, $7, 1, 2,
       'PAID', 24000,
       'Коваленко', 'Тест', 'Київ-Тест', 'Львів-Тест',
       NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days 6 hours'
     )
     RETURNING ticket_id`,
    [userId, passengerId, tripId, seatId, carriageId, fromStationId, toStationId],
  );
  const ticketId = ticketRes.rows[0]?.ticket_id;

  if (!ticketId) throw new Error('Failed to seed test ticket');
  return { userId, ticketId };
}

describe('03_audit_and_refunds schema constraints', () => {
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

  it('inserts valid rows into refunds and system_logs with defaults', async () => {
    const { userId, ticketId } = await seedTestTicket(pool);

    const refundRes = await pool.query<{ refund_status: string }>(
      `INSERT INTO refunds (ticket_id, amount, reason) VALUES ($1, $2, $3) RETURNING refund_status`,
      [ticketId, 21600, 'Changed plans'],
    );
    expect(refundRes.rows[0]?.refund_status).toBe('COMPLETED');


    const logRes = await pool.query<{ log_id: string }>(
      `INSERT INTO system_logs(user_id, action, metadata) VALUES ($1, $2, $3) RETURNING log_id`,
      [userId, 'TICKET_REFUNDED', JSON.stringify({ ticketId })],
    );
    expect(logRes.rows[0]?.log_id).toBeTypeOf('string');
  });

  it('rejects negative refund amount with CHECK constraint (23514)', async () => {
    const { ticketId } = await seedTestTicket(pool);


    await expectPgErrorCode(
      () => pool.query(` INSERT INTO refunds (ticket_id, amount) VALUES ($1, $2)`, [ticketId, -100]),
      '23514',
    );
  });

  it('rejects duplicate refund for the same ticket_id with UNIQUE constraint (23505)', async () => {
    const { ticketId } = await seedTestTicket(pool);

    await pool.query(`INSERT INTO refunds (ticket_id, amount) VALUES ($1, $2)`, [ticketId, 21600]);

    await expectPgErrorCode(
      () => pool.query(`INSERT INTO refunds (ticket_id, amount) VALUES ($1, $2)`, [ticketId, 21600]),
      '23505',
    );
  });

  it('keeps system_logs row and sets user_id to NULL when user is deleted', async () => {
    const userId = await seedTestUser(pool, 'delete-me@test.com');


    
    const logRes = await pool.query<{ log_id: string }>(
      `INSERT INTO system_logs (user_id, action) VALUES ($1, $2) RETURNING log_id`,
      [userId, 'USER_CREATED'],
    );
    const logId = logRes.rows[0]?.log_id;

    
    await pool.query(`DELETE FROM users WHERE user_id = $1`, [userId]);


    const checkRes = await pool.query<{ user_id: string | null }>(
      `SELECT user_id FROM system_logs WHERE log_id = $1`,
      [logId],
    );
    expect(checkRes.rows).toHaveLength(1);
    expect(checkRes.rows[0]?.user_id).toBeNull();
  });
});