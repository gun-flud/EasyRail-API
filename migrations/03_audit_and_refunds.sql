CREATE TYPE refund_status AS ENUM ('PENDING', 'COMPLETED', 'REJECTED');

CREATE TABLE IF NOT EXISTS refunds (
        refund_id UUID DEFAULT uuidv7(),
        ticket_id UUID NOT NULL UNIQUE,
        amount INT NOT NULL CHECK (amount >= 0),
        reason VARCHAR(255) NULL,
        refund_status refund_status NOT NULL DEFAULT 'COMPLETED',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

        PRIMARY KEY (refund_id),
        FOREIGN KEY (ticket_id) REFERENCES ticket_segment (ticket_id) ON DELETE RESTRICT
    );

CREATE TABLE IF NOT EXISTS system_logs (
        log_id UUID DEFAULT uuidv7(),
        user_id UUID NULL,
        action VARCHAR(100) NOT NULL CHECK (LENGTH(TRIM(action)) > 0),
        metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

        PRIMARY KEY (log_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE SET NULL
    );

CREATE INDEX IF NOT EXISTS idx_passengers_user_id ON passengers (user_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_user_id_created_at ON system_logs (user_id, created_at DESC);