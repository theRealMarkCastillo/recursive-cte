WITH RECURSIVE reports AS (
    SELECT
        employee.id,
        employee.name,
        employee.title,
        0::INTEGER AS depth,
        ARRAY[employee.id]::BIGINT[] AS path_ids,
        ARRAY[employee.name]::TEXT[] AS path_names
    FROM org.employees AS employee
    WHERE employee.name = %(manager)s

    UNION ALL

    SELECT
        employee.id,
        employee.name,
        employee.title,
        reports.depth + 1,
        reports.path_ids || employee.id,
        reports.path_names || employee.name
    FROM reports
    JOIN org.employees AS employee ON employee.manager_id = reports.id
    WHERE reports.depth < %(max_depth)s
      AND NOT (employee.id = ANY(reports.path_ids))
)
SELECT
    depth,
    repeat('  ', depth) || name AS organization_line,
    title,
    array_to_string(path_names, ' -> ') AS reporting_path
FROM reports
ORDER BY path_ids;
