import dotenv from 'dotenv';
import * as z from 'zod';

dotenv.config({ path: ['../.env', '.env'] });

const postgresUrlSchema = z
	.string()
	.refine(
		value => value.startsWith('postgres://') || value.startsWith('postgresql://'),
		'Must be a PostgreSQL connection string (postgres:// or postgresql://)',
	);

const isProduction = process.env.NODE_ENV === 'production';

const dbUser = process.env.DB_USER ?? (isProduction ? '' : 'postgres');
const dbPassword = process.env.DB_PASSWORD ?? (isProduction ? '' : 'your_password');
const dbHost = process.env.DB_HOST ?? (isProduction ? '' : '127.0.0.1');
const dbPort = process.env.DB_PORT ?? '6543';
const dbName = process.env.DB_NAME ?? (isProduction ? '' : 'easyrail_db');

const canBuildDbUrl = Boolean(dbUser && dbPassword && dbHost && dbName);

const fallbackDatabaseUrl = canBuildDbUrl
	? `postgresql://${encodeURIComponent(dbUser)}:${encodeURIComponent(dbPassword)}@${dbHost}:${dbPort}/${dbName}`
	: undefined;

const fallbackTestDatabaseUrl =
	!isProduction && canBuildDbUrl
		? `postgresql://${encodeURIComponent(dbUser)}:${encodeURIComponent(dbPassword)}@${dbHost}:${dbPort}/${dbName}_test`
		: undefined;

const envSchema = z.object({
	NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
	PORT: z.coerce.number().int().min(1).max(65535).default(8080),
	LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
	DATABASE_URL: postgresUrlSchema,
	TEST_DATABASE_URL: postgresUrlSchema.optional(),
});

const parsed = envSchema.safeParse({
	...process.env,
	DATABASE_URL: process.env.DATABASE_URL ?? fallbackDatabaseUrl,
	TEST_DATABASE_URL: process.env.TEST_DATABASE_URL ?? fallbackTestDatabaseUrl,
});

if (!parsed.success) {
	console.error('Invalid environment variables:');
	for (const issue of parsed.error.issues) {
		console.error(`- ${issue.path.join('.')}: ${issue.message}`);
	}
	process.exit(1);
}

process.env.DATABASE_URL = parsed.data.DATABASE_URL;
if (parsed.data.TEST_DATABASE_URL) {
	process.env.TEST_DATABASE_URL = parsed.data.TEST_DATABASE_URL;
}

export const env = parsed.data;
