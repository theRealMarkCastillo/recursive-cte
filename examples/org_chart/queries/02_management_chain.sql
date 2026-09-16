WITH RECURSIVE management_chain AS (
    SELECT
        employee.id,
        employee.name,
        employee.title,
        employee.manager_id,
        0::INTEGER AS levels_up,
        ARRAY[employee.id]::BIGINT[] AS path_ids
    FROM org.employees AS employee
    WHERE employee.name = %(employee)s

    UNION ALL

    SELECT
        manager.id,
        manager.name,
        manager.title,
        manager.manager_id,
        chain.levels_up + 1,
        chain.path_ids || manager.id
    FROM management_chain AS chain
    JOIN org.employees AS manager ON manager.id = chain.manager_id
    WHERE chain.levels_up < %(max_depth)s
      AND NOT (manager.id = ANY(chain.path_ids))
)
SELECT levels_up, name, title
FROM management_chain
ORDER BY levels_up DESC;
