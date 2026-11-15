export class AppError extends Error {
	public readonly statusCode: number;
	public readonly code: string;

	constructor(statusCode: number, code: string, message: string) {
		super(message);
		this.name = new.target.name;
		this.statusCode = statusCode;
		this.code = code;
	}
}

export class BadRequestError extends AppError {
	constructor(message: string, code = 'BAD_REQUEST') {
		super(400, code, message);
	}
}

export class UnauthorizedError extends AppError {
	constructor(message = 'Authentication required', code = 'UNAUTHORIZED') {
		super(401, code, message);
	}
}

export class ForbiddenError extends AppError {
	constructor(message = 'Access denied', code = 'FORBIDDEN') {
		super(403, code, message);
	}
}

export class NotFoundError extends AppError {
	constructor(message = 'Resource not found', code = 'NOT_FOUND') {
		super(404, code, message);
	}
}

export class ConflictError extends AppError {
	constructor(message: string, code = 'CONFLICT') {
		super(409, code, message);
	}
}

export interface PostgresErrorLike {
	code: string;
	constraint?: string;
	detail?: string;
}

export function isPostgresError(error: unknown): error is PostgresErrorLike {
	if (typeof error !== 'object' || error === null) {
		return false;
	}
	if (!('code' in error)) {
		return false;
	}
	return typeof error.code === 'string';
}
