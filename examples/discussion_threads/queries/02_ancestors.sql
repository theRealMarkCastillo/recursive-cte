WITH RECURSIVE ancestors AS (
    SELECT
        comment.id,
        comment.comment_key,
        comment.parent_id,
        comment.author,
        comment.body,
        0::INTEGER AS levels_up,
        ARRAY[comment.id]::BIGINT[] AS path_ids
    FROM discussion.comments AS comment
    WHERE comment.comment_key = %(comment)s

    UNION ALL

    SELECT
        parent.id,
        parent.comment_key,
        parent.parent_id,
        parent.author,
        parent.body,
        ancestors.levels_up + 1,
        ancestors.path_ids || parent.id
    FROM ancestors
    JOIN discussion.comments AS parent ON parent.id = ancestors.parent_id
    WHERE ancestors.levels_up < %(max_depth)s
      AND NOT (parent.id = ANY(ancestors.path_ids))
)
SELECT levels_up, comment_key, author, body
FROM ancestors
ORDER BY levels_up DESC;
