import { afterAll, describe, expect, it } from 'vitest';
import { buildApp } from '../../src/app.js';
import { env } from '../../src/config/env.js';
import { authStub, getAuthUser, requireRole } from '../../src/shared/auth/auth-stub.js';

describe('authStub & requireRole', () => {
	const app = buildApp({ logger: false });
	const validUserId = crypto.randomUUID();

	app.get('/test/auth', { preHandler: authStub }, async request => {
		return { user: getAuthUser(request) };
	});

	app.get('/test/admin', { preHandler: requireRole('ADMIN') }, async request => {
		return { user: getAuthUser(request) };
	});

	afterAll(async () => {
		await app.close();
	});

	it('sets user with default PASSENGER role when x-user-role is omitted', async () => {
		const res = await app.inject({
			method: 'GET',
			url: '/test/auth',
			headers: { 'x-user-id': validUserId },
		});

		expect(res.statusCode).toBe(200);
		expect(res.json()).toEqual({
			user: { userId: validUserId, role: 'PASSENGER' },
		});
	});

	it('returns 401 when x-user-id is missing or invalid', async () => {
		const missing = await app.inject({ method: 'GET', url: '/test/auth' });
		expect(missing.statusCode).toBe(401);

		const invalid = await app.inject({
			method: 'GET',
			url: '/test/auth',
			headers: { 'x-user-id': '123' },
		});
		expect(invalid.statusCode).toBe(401);
	});

	it('returns 401 when x-user-role is invalid', async () => {
		const res = await app.inject({
			method: 'GET',
			url: '/test/auth',
			headers: {
				'x-user-id': validUserId,
				'x-user-role': 'SUPERMAN',
			},
		});

		expect(res.statusCode).toBe(401);
	});

	it('returns 403 for PASSENGER on ADMIN route and 200 for ADMIN', async () => {
		const forbidden = await app.inject({
			method: 'GET',
			url: '/test/admin',
			headers: {
				'x-user-id': validUserId,
				'x-user-role': 'PASSENGER',
			},
		});
		expect(forbidden.statusCode).toBe(403);

		const allowed = await app.inject({
			method: 'GET',
			url: '/test/admin',
			headers: {
				'x-user-id': validUserId,
				'x-user-role': 'ADMIN',
			},
		});
		expect(allowed.statusCode).toBe(200);
		expect(allowed.json()).toEqual({
			user: { userId: validUserId, role: 'ADMIN' },
		});
	});

	it('fails closed with 401 in production even with valid headers', async () => {
		const originalEnv = env.NODE_ENV;
		env.NODE_ENV = 'production';
		try {
			const res = await app.inject({
				method: 'GET',
				url: '/test/admin',
				headers: {
					'x-user-id': validUserId,
					'x-user-role': 'ADMIN',
				},
			});
			expect(res.statusCode).toBe(401);
		} finally {
			env.NODE_ENV = originalEnv;
		}
	});
});