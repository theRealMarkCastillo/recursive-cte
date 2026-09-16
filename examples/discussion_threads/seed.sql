INSERT INTO discussion.comments (
    comment_key, thread_key, author, body, posted_at
)
VALUES
    ('root', 'recursive-cte-tips', 'Alice',
     'How should I prevent cycles?', '2026-01-01 09:00:00+00'),
    ('reply-bob', 'recursive-cte-tips', 'Bob',
     'Carry visited node IDs in an array.', '2026-01-01 09:05:00+00'),
    ('reply-carol', 'recursive-cte-tips', 'Carol',
     'Also add a maximum depth.', '2026-01-01 09:06:00+00'),
    ('reply-deepa', 'recursive-cte-tips', 'Deepa',
     'Why use UNION ALL?', '2026-01-01 09:10:00+00'),
    ('reply-erin', 'recursive-cte-tips', 'Erin',
     'It preserves distinct paths to the same node.', '2026-01-01 09:15:00+00')
ON CONFLICT (comment_key) DO UPDATE
SET thread_key = EXCLUDED.thread_key,
    author = EXCLUDED.author,
    body = EXCLUDED.body,
    posted_at = EXCLUDED.posted_at;

UPDATE discussion.comments AS child
SET parent_id = parent.id,
    thread_key = parent.thread_key
FROM (
    VALUES
        ('reply-bob', 'root'),
        ('reply-carol', 'root'),
        ('reply-deepa', 'reply-bob'),
        ('reply-erin', 'reply-deepa')
) AS tree(child_key, parent_key)
JOIN discussion.comments AS parent ON parent.comment_key = tree.parent_key
WHERE child.comment_key = tree.child_key;

UPDATE discussion.comments SET parent_id = NULL WHERE comment_key = 'root';
