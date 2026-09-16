WITH RECURSIVE thread AS (
    SELECT
        comment.id,
        comment.comment_key,
        comment.author,
        comment.body,
        comment.posted_at,
        0::INTEGER AS depth,
        ARRAY[comment.id]::BIGINT[] AS path_ids,
        ARRAY[comment.posted_at]::TIMESTAMPTZ[] AS sort_path
    FROM discussion.comments AS comment
    WHERE comment.thread_key = %(thread)s
      AND comment.parent_id IS NULL

    UNION ALL

    SELECT
        child.id,
        child.comment_key,
        child.author,
        child.body,
        child.posted_at,
        thread.depth + 1,
        thread.path_ids || child.id,
        thread.sort_path || child.posted_at
    FROM thread
    JOIN discussion.comments AS child ON child.parent_id = thread.id
    WHERE thread.depth < %(max_depth)s
      AND NOT (child.id = ANY(thread.path_ids))
)
SELECT
    depth,
    comment_key,
    repeat('  ', depth) || author || ': ' || body AS display_line,
    posted_at
FROM thread
ORDER BY sort_path, path_ids;
