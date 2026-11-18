import 'dotenv/config';
import fs from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { createPool } from '../../src/db/pool.js';
import type { Pool } from '../../src/db/pool.js';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../migrations', import.meta.url));

function getTestDatabaseUrl(): string {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) {
    throw new Error(
      'TEST_DATABASE_URL is not set. Add it to backend/.env or pass it in the environment.',
    );
  }
  return url;
}

function extractSafeTestDbName(connectionString: string): string {
  const parsed = new URL(connectionString);
  const dbName = parsed.pathname.replace(/^\//, '');

  if (!dbName.endsWith('_test')) {
    throw new Error(
      `Refusing to reset database "${dbName}": test database name must end with "_test".`,
    );
  }
  if (!/^[a-zA-Z0-9_]+$/.test(dbName)) {
    throw new Error(`Unsafe test database name "${dbName}".`);
  }

  return dbName;
}

async function ensureDatabaseExists(connectionString: string, dbName: string): Promise<void> {
  const adminUrl = new URL(connectionString);
  adminUrl.pathname = '/postgres';

  const adminPool = createPool(adminUrl.toString());
  try {
    const existing = await adminPool.query('SELECT 1 FROM pg_database WHERE datname = $1', [
      dbName,
    ]);
    if (existing.rowCount === 0) {
      await adminPool.query(`CREATE DATABASE "${dbName}"`);
    }
  } finally {
    await adminPool.end();
  }
}

export async function setupTestDb(): Promise<Pool> {
  const connectionString = getTestDatabaseUrl();
  const dbName = extractSafeTestDbName(connectionString);

  await ensureDatabaseExists(connectionString, dbName);

  const pool = createPool(connectionString);

  await pool.query('DROP SCHEMA IF EXISTS public CASCADE');
  await pool.query('CREATE SCHEMA public');

  const entries = await fs.readdir(MIGRATIONS_DIR);
  const migrationFiles = entries
    .filter((file) => file.endsWith('.sql') && file !== '02_seed.sql')
    .sort();

  for (const file of migrationFiles) {
    const sql = await fs.readFile(path.join(MIGRATIONS_DIR, file), 'utf8');
    if (sql.trim().length > 0) {
      await pool.query(sql);
    }
  }

  return pool;
}

export async function truncateAllTables(pool: Pool): Promise<void> {
  const result = await pool.query<{ tablename: string }>(
    "SELECT tablename FROM pg_tables WHERE schemaname = 'public'",
  );

  if (result.rows.length === 0) {
    return;
  }

  const tablesSql = result.rows
    .map((row) => `"${row.tablename.replaceAll('"', '""')}"`)
    .join(', ');

  await pool.query(`TRUNCATE TABLE ${tablesSql} RESTART IDENTITY CASCADE`);
}