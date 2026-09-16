INSERT INTO org.employees (name, title)
VALUES
    ('Alice', 'CEO'),
    ('Bob', 'CTO'),
    ('Carol', 'CFO'),
    ('Deepa', 'Engineering Manager'),
    ('Erin', 'Software Engineer'),
    ('Faisal', 'Software Engineer'),
    ('Grace', 'Accountant')
ON CONFLICT (name) DO UPDATE SET title = EXCLUDED.title;

UPDATE org.employees AS employee
SET manager_id = manager.id
FROM (
    VALUES
        ('Bob', 'Alice'),
        ('Carol', 'Alice'),
        ('Deepa', 'Bob'),
        ('Erin', 'Deepa'),
        ('Faisal', 'Deepa'),
        ('Grace', 'Carol')
) AS reporting(employee_name, manager_name)
JOIN org.employees AS manager ON manager.name = reporting.manager_name
WHERE employee.name = reporting.employee_name;

UPDATE org.employees SET manager_id = NULL WHERE name = 'Alice';
