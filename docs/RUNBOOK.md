# Operations runbook

This runbook covers starting, verifying, inspecting, troubleshooting, stopping, and resetting the recursive CTE lab.

## Service facts

```text
Compose service: postgres
Image:           postgres:16-alpine
Container port:  5432
Default host:    127.0.0.1
Default port:    55450
Database:        graphdb
User:            graph_user
Password:        graph_password (development only)
Volume:          recursive-cte_postgres_data
```

All commands assume the current directory is the repository root.

## First-time startup

1. Optionally create a local environment file:

   ```sh
   cp .env.example .env
   ```

2. Confirm the host port is free:

   ```sh
   lsof -nP -iTCP:55450 -sTCP:LISTEN
   ```

   No output means no host process is listening there. To see Docker-published ports:

   ```sh
   docker ps --format 'table {{.Names}}\t{{.Ports}}'
   ```

3. Start PostgreSQL and wait for health:

   ```sh
   docker compose up -d --wait
   ```

4. Verify status and port mapping:

   ```sh
   docker compose ps
   docker compose port postgres 5432
   ```

Expected mapping:

```text
127.0.0.1:55450
```

## Python setup

```sh
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

If `.env` contains non-default settings, export it into the current shell:

```sh
set -a
. ./.env
set +a
```

Confirm the driver and database connection:

```sh
python -c 'import psycopg; print(psycopg.__version__)'
python -m scripts.shortest_path storefront postgres
```

## Routine verification

Run the automated integration suite:

```sh
make test
```

Load all practical example schemas explicitly (each demo also loads its own):

```sh
make load-examples
```

Run every practical demo:

```sh
make demos
```

Run all teaching examples:

```sh
python -m scripts.walk_graph --start storefront --max-depth 8
python -m scripts.find_paths storefront postgres
python -m scripts.shortest_path storefront postgres
python -m scripts.dependency_summary --start storefront
```

Expected facts:

```text
shortest storefront -> postgres distance: 3 hops
simple storefront -> postgres paths:       5
postgres simple-path count in summary:     5
container health:                          healthy
```

## Open a SQL shell

With default credentials:

```sh
docker compose exec postgres psql -U graph_user -d graphdb
```

Useful `psql` commands:

```sql
\conninfo
\dt
\d graph_nodes
\d graph_edges
SELECT COUNT(*) AS nodes FROM graph_nodes;
SELECT COUNT(*) AS edges FROM graph_edges;
```

The seed contains 14 nodes and 19 edges.

The practical modules use separate `org`, `bom`, `rbac`, `lineage`,
`discussion`, and `routes` schemas. List them with:

```sql
\dn
```

Exit with:

```text
\q
```

## Logs and health

Show recent logs:

```sh
docker compose logs --tail=100 postgres
```

Follow logs until interrupted with Ctrl-C:

```sh
docker compose logs -f postgres
```

Inspect health directly:

```sh
docker compose exec postgres pg_isready -U graph_user -d graphdb
```

## Stop and resume

Stop containers while preserving data:

```sh
docker compose down
```

Resume with the same data:

```sh
docker compose up -d --wait
```

## Reset to the seed state

Warning: this deletes the lab's PostgreSQL volume and all changes made in the database.

```sh
docker compose down -v
docker compose up -d --wait
```

The files in `sql/01-schema.sql` and `sql/02-seed.sql` run only when PostgreSQL initializes a new, empty volume. Editing those files does not change an already initialized database until you reset the volume or apply the SQL manually.

## Change a conflicting port

If startup reports that `55450` is already allocated:

1. Choose an unused high port, such as `55451`.
2. Set both values in `.env`:

   ```text
   POSTGRES_PORT=55451
   DATABASE_URL=postgresql://graph_user:graph_password@localhost:55451/graphdb
   ```

3. Export the settings and start again:

   ```sh
   set -a
   . ./.env
   set +a
   docker compose up -d --wait
   ```

## Troubleshooting

### Port is already allocated

Symptom:

```text
bind: address already in use
```

Resolution: use the port-change procedure above. Confirm both `POSTGRES_PORT` and the port inside `DATABASE_URL` match.

### Python says connection refused

Check, in order:

```sh
docker compose ps
docker compose logs --tail=100 postgres
docker compose port postgres 5432
```

Then confirm `DATABASE_URL` points to that host port:

```sh
python -c 'import os; print(os.getenv("DATABASE_URL", "using project default"))'
```

### Password authentication failed

Credentials stored in a PostgreSQL volume do not change when `.env` changes. Either restore the credentials originally used to create the volume or reset the lab volume. Resetting deletes its data.

### Tables or seed rows are missing

Inspect initialization logs:

```sh
docker compose logs postgres
```

If the volume was initialized before the SQL files were mounted or updated, reset the volume. For non-disposable data, apply migrations manually instead of resetting.

### `ModuleNotFoundError: psycopg`

Activate the project environment and install requirements:

```sh
. .venv/bin/activate
python -m pip install -r requirements.txt
```

### Recursive query runs too long

Cancel it in `psql` with Ctrl-C. Add a depth predicate and use a timeout while experimenting:

```sql
SET statement_timeout = '5s';
```

Verify the recursive member includes a cycle guard such as:

```sql
NOT (child.id = ANY(path_ids))
```

## Files to inspect during an incident

```text
docker-compose.yml                 service, port, volume, health check
.env / .env.example               local credentials and host port
sql/01-schema.sql                 tables, constraints, indexes
sql/02-seed.sql                   expected nodes and edges
scripts/common.py                 Python connection default
sql/queries/*.sql                 traversal behavior and safeguards
```
