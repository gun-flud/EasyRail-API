import type { FastifyRequest } from 'fastify';
import * as z from 'zod';
import { env } from '../../config/env.js';
import { ForbiddenError, UnauthorizedError } from '../errors/app-error.js';

export const userRoleSchema = z.enum(['PASSENGER', 'ADMIN', 'CONDUCTOR']);
export type UserRole = z.infer<typeof userRoleSchema>;

export interface AuthUser {
	userId: string;
	role: UserRole;
}

declare module 'fastify' {
	interface FastifyRequest {
		user?: AuthUser;
	}
}

const uuidSchema = z.uuid();

export async function authStub(request: FastifyRequest): Promise<void> {
	if (env.NODE_ENV === 'production') {
		throw new UnauthorizedError('Authentication stub is disabled in production');
	}

	const userIdParsed = uuidSchema.safeParse(request.headers['x-user-id']);
	if (!userIdParsed.success) {
		throw new UnauthorizedError('Missing or invalid x-user-id header');
	}

	const roleParsed = userRoleSchema.safeParse(request.headers['x-user-role'] ?? 'PASSENGER');
	if (!roleParsed.success) {
		throw new UnauthorizedError('Invalid x-user-role header');
	}

	request.user = {
		userId: userIdParsed.data,
		role: roleParsed.data,
	};
}

export function getAuthUser(request: FastifyRequest): AuthUser {
	if (!request.user) {
		throw new UnauthorizedError();
	}
	return request.user;
}

export function requireRole(...roles: UserRole[]) {
	return async (request: FastifyRequest): Promise<void> => {
		await authStub(request);
		const user = getAuthUser(request);
		if (!roles.includes(user.role)) {
			throw new ForbiddenError('Insufficient permissions');
		}
	};
}
