import type { QueryExecutor } from '../../db/types.js';

export interface SystemLog {
	log_id: string;
	user_id: string | null;
	action: string;
	metadata: Record<string, unknown>;
	created_at: Date;
}

export interface LogActionInput {
	userId?: string | null;
	action: string;
	metadata?: Record<string, unknown>;
}

const INSERT_LOG_SQL = `
	INSERT INTO system_logs (user_id, action, metadata)
	VALUES ($1, $2, $3)
	RETURNING log_id, user_id, action, metadata, created_at
`;

export async function logAction(
	executor: QueryExecutor,
	input: LogActionInput,
): Promise<SystemLog> {
	const result = await executor.query<SystemLog>(INSERT_LOG_SQL, [
		input.userId ?? null,
		input.action,
		JSON.stringify(input.metadata ?? {}),
	]);

	const row = result.rows[0];
	if (!row) {
		throw new Error('Failed to insert system log');
	}
	return row;
}
