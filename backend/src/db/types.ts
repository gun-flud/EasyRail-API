import type { QueryResult, QueryResultRow } from 'pg';

export interface QueryExecutor {
    query<T extends QueryResultRow = QueryResultRow>(
        text: string,
        params?: unknown[],
    ): Promise<QueryResult<T>>;
}