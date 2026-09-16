CREATE SCHEMA IF NOT EXISTS discussion;

CREATE TABLE IF NOT EXISTS discussion.comments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    comment_key TEXT NOT NULL UNIQUE,
    thread_key TEXT NOT NULL,
    parent_id BIGINT REFERENCES discussion.comments(id) ON DELETE CASCADE,
    author TEXT NOT NULL,
    body TEXT NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL,
    CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE INDEX IF NOT EXISTS comments_thread_parent_idx
    ON discussion.comments (thread_key, parent_id, posted_at, id);
