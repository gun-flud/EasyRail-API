import * as z from 'zod';

const postgresUrlSchema = z
	.url()
	.refine(
		value => value.startsWith('postgres://') || value.startsWith('postgresql://'),
		'Must be a PostgreSQL connection string (postgres:// or postgresql://)',
	);

const envSchema = z
	.object({
		NODE_ENV: z.enum(['development', 'production', 'test']),
		PORT: z.coerce.number().int().min(1).max(65535).default(8080),
		LOG_LEVEL: z
			.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
			.default('info'),
		DATABASE_URL: postgresUrlSchema.optional(),
		TEST_DATABASE_URL: postgresUrlSchema.optional(),
	})
	.refine(data => data.NODE_ENV === 'test' || Boolean(data.DATABASE_URL), {
		path: ['DATABASE_URL'],
		message: 'DATABASE_URL is required when NODE_ENV is not test',
	});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
	console.error('Invalid environment variables:');
	for (const issue of parsed.error.issues) {
		console.error(`- ${issue.path.join('.')}: ${issue.message}`);
	}
	process.exit(1);
}

export const env = parsed.data;
