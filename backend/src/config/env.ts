import dotenv from 'dotenv';
import * as z from 'zod';

dotenv.config({ path: ['../.env', '.env'] });

const postgresUrlSchema = z
	.string()
	.refine(
		value => value.startsWith('postgres://') || value.startsWith('postgresql://'),
		'Must be a PostgreSQL connection string (postgres:// or postgresql://)',
	);

const dbUser = process.env.DB_USER ?? 'postgres';
const dbPassword = process.env.DB_PASSWORD ?? 'your_password';
const dbHost = process.env.DB_HOST ?? '127.0.0.1';
const dbPort = process.env.DB_PORT ?? '6543';
const dbName = process.env.DB_NAME ?? 'easyrail_db';

const defaultDatabaseUrl = `postgresql://${dbUser}:${dbPassword}@${dbHost}:${dbPort}/${dbName}`;
const defaultTestDatabaseUrl = `postgresql://${dbUser}:${dbPassword}@${dbHost}:${dbPort}/${dbName}_test`;

const envSchema = z.object({
	NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
	PORT: z.coerce.number().int().min(1).max(65535).default(8080),
	LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
	DATABASE_URL: postgresUrlSchema.default(defaultDatabaseUrl),
	TEST_DATABASE_URL: postgresUrlSchema.default(defaultTestDatabaseUrl),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
	console.error('Invalid environment variables:');
	for (const issue of parsed.error.issues) {
		console.error(`- ${issue.path.join('.')}: ${issue.message}`);
	}
	process.exit(1);
}

// Забезпечуємо наявність у process.env для хелперів тестів
process.env.DATABASE_URL = parsed.data.DATABASE_URL;
process.env.TEST_DATABASE_URL = parsed.data.TEST_DATABASE_URL;

export const env = parsed.data;
