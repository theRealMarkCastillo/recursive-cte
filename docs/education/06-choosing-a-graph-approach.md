# Lesson 6: Choose PostgreSQL or a graph database

## Goal

Understand why recursive CTEs are often the right first graph tool in PostgreSQL, where their limits are, and which relational patterns, PostgreSQL extensions, or graph-native databases fit other workloads.

There is no universal winner. Choose based on graph shape, query depth, write pattern, consistency boundary, algorithm needs, team experience, and operational cost.

## Why start with a recursive CTE?

Use a recursive CTE when the graph is part of an otherwise relational application and traversals are bounded and understandable.

```text
orders, users, permissions, products
                 |
                 | same database and transaction
                 v
nodes + edges + recursive SQL
```

The advantages are practical:

- No new database service or required extension.
- Graph edges can reference existing relational rows with foreign keys.
- Graph updates participate in the same ACID transaction as ordinary business data.
- SQL can combine traversal results with tables, JSON, aggregates, permissions, and reporting queries.
- Existing PostgreSQL backups, replication, access controls, monitoring, and client libraries still apply.
- The traversal state is explicit: depth, path, cost, root, and cycle rules are ordinary columns in the CTE.

PostgreSQL documents recursive CTEs as an iterative process with a working table and includes `SEARCH` and `CYCLE` syntax for traversal order and cycle detection. See the [PostgreSQL 16 recursive query documentation](https://www.postgresql.org/docs/16/queries-with.html).

## Recursive CTE tradeoffs

The same explicitness that makes recursive SQL flexible can make it verbose and expensive.

```text
Strength                              Cost
--------                              ----
one transactional data model         graph schema is hand-designed
ordinary SQL and joins                path syntax is verbose
custom state per traversal            cycle rules are your responsibility
works with existing PostgreSQL        no general graph algorithm library
excellent for bounded traversal       path counts can grow exponentially
familiar operational tooling          planner/storage are not graph-specialized
```

Important limitations:

- Enumerating every simple path is not an efficient general shortest-path algorithm.
- Highly connected graphs can produce enormous intermediate result sets.
- Variable-length patterns are less concise than graph query languages such as Cypher.
- Centrality, community detection, PageRank, K-shortest paths, and similar algorithms require custom work or another tool.
- A single node may appear through many routes, so deduplication semantics must be chosen deliberately.
- Recursive traversal is evaluated inside one SQL statement; application-level progress reporting or early algorithm-specific termination is harder.

## A decision sketch

```text
Is the data fundamentally a tree or hierarchy?
  |
  +-- yes --> Is ancestry queried much more often than structure changes?
  |             |
  |             +-- yes --> ltree, materialized path, closure table, nested sets
  |             `-- no  --> adjacency list + recursive CTE
  |
  `-- no --> Is it a routing/network optimization problem?
                |
                +-- yes --> pgRouting, or a specialized routing engine
                |
                `-- no --> Must graph and relational changes share a transaction?
                              |
                              +-- yes --> recursive CTE or Apache AGE
                              |
                              `-- no --> Are deep patterns/algorithms the main workload?
                                           |
                                           +-- yes --> graph-native database
                                           `-- no  --> recursive CTE is a strong baseline
```

## Other methods inside PostgreSQL

### Fixed-depth self-joins

For a known, tiny number of hops, ordinary joins are often simpler and give the planner a conventional query:

```sql
SELECT grandchild.*
FROM graph_nodes AS root
JOIN graph_edges AS e1 ON e1.from_node_id = root.id
JOIN graph_nodes AS child ON child.id = e1.to_node_id
JOIN graph_edges AS e2 ON e2.from_node_id = child.id
JOIN graph_nodes AS grandchild ON grandchild.id = e2.to_node_id
WHERE root.name = 'storefront';
```

Use this for exactly one, two, or another fixed number of hops. It does not adapt to unknown depth.

### Closure table

A closure table stores every known ancestor/descendant pair, often including distance:

```text
ancestor     descendant     depth
--------     ----------     -----
api          api            0
api          orders         1
api          postgres       2
```

Reads become simple indexed lookups. Writes become more expensive because inserts, moves, and deletes must maintain transitive rows. This is strongest for read-heavy trees or DAGs with controlled updates.

### Materialized path and `ltree`

A materialized path stores lineage on each row:

```text
company.engineering.platform.database
```

PostgreSQL's supplied [`ltree` extension](https://www.postgresql.org/docs/16/ltree.html) provides a hierarchical path type, ancestor/descendant operators, pattern matching, and index support. It is excellent for taxonomies, organization trees, and folder-like structures.

Tradeoff: one stored path naturally represents one location in a hierarchy. Arbitrary graphs, multiple parents, and frequent subtree moves require extra design or path rewrites.

### Nested sets

Nested sets assign left/right ranges to tree nodes. Descendant and ancestor reads can be very fast range queries, but inserting or moving nodes may update many ranges. Use them mainly for stable, read-heavy trees.

### Application-side BFS, DFS, Dijkstra, or A*

The application can fetch neighbor batches and run an algorithm in memory.

Benefits:

- Full control over queues, priority queues, heuristics, pruning, and progress.
- Easy reuse of established algorithm libraries.
- Can stop as soon as the algorithm proves an answer.

Costs:

- Repeated database round trips unless a useful subgraph is loaded in one query.
- More application memory and custom correctness work.
- Data can change between queries unless the traversal uses an appropriate transaction snapshot.

### PostgreSQL `SEARCH` and `CYCLE`

These clauses improve recursive CTE ergonomics; they are not a separate graph engine. `SEARCH` produces an ordering column and `CYCLE` produces cycle state/path information. They reduce handwritten bookkeeping but retain recursive CTE execution and scaling characteristics. See the [PostgreSQL recursive query documentation](https://www.postgresql.org/docs/16/queries-with.html#QUERIES-WITH-RECURSIVE).

## PostgreSQL graph extensions

### Apache AGE

[Apache AGE](https://age.apache.org/overview/) is a PostgreSQL extension that adds graph functionality and openCypher-style queries while using PostgreSQL's transactional storage layer. It is attractive when you want property-graph syntax and hybrid SQL/graph queries without operating a completely separate database.

Choose AGE when:

- Cypher-style pattern matching materially improves query clarity.
- Graph and relational data should remain in PostgreSQL.
- Your deployment platform permits the extension.

Tradeoffs:

- Extension installation, upgrades, backups, drivers, and PostgreSQL-version compatibility need testing.
- The graph representation and query API differ from this lab's plain tables.
- Its ecosystem and operational experience are smaller than core PostgreSQL's.
- It does not remove the need to benchmark the actual graph shape and queries.

### pgRouting

[pgRouting](https://docs.pgrouting.org/latest/en/) extends PostGIS/PostgreSQL for geospatial routing and network analysis. Its documented function families include Dijkstra, bidirectional Dijkstra, A*, K-shortest paths, connected components, flow, and spanning-tree operations.

Choose pgRouting for roads, logistics, utility networks, travel cost, and other edge-cost routing problems. It is specialized; it is not a general replacement for property-graph pattern matching.

## Dedicated and graph-capable databases

### Property-graph databases such as Neo4j

Neo4j stores a property graph and uses Cypher, whose syntax directly expresses node and relationship patterns:

```text
(storefront)-[:CALLS]->(api)-[:CALLS]->(service)
```

Neo4j's current Cypher documentation includes variable-length patterns and shortest-path selectors, while its Graph Data Science tooling provides specialized algorithms. See the official [Cypher pattern documentation](https://neo4j.com/docs/cypher-manual/current/patterns/) and [shortest-path documentation](https://neo4j.com/docs/cypher-manual/current/patterns/shortest-paths/).

Choose a property-graph database when graph traversal and pattern matching are the dominant workload, relationships are first-class domain objects, or graph algorithms are core product features.

Tradeoffs compared with keeping everything in PostgreSQL:

- Another service, query language, backup strategy, security model, and monitoring surface.
- Relational and graph writes may cross a transaction boundary.
- Data duplication, synchronization, or change-data-capture pipelines may be required.
- Joining graph results with operational relational data may move into the application or an integration layer.

### Managed multi-model graph databases such as Amazon Neptune

[Amazon Neptune](https://docs.aws.amazon.com/neptune/latest/userguide/access-graph-queries.html) supports property-graph queries with Gremlin and openCypher and RDF graphs with SPARQL. It is useful when a managed service, RDF/semantic modeling, or multiple graph query models are requirements.

Tradeoffs include cloud service cost, network boundaries, vendor-specific operations, and implementation differences from other engines using similar query languages.

### Graph features in relational databases

PostgreSQL is not the only relational database with graph options:

- [SQL Server graph tables and `MATCH`](https://learn.microsoft.com/en-us/sql/relational-databases/graphs/sql-graph-overview) add node/edge tables and graph pattern matching to T-SQL.
- [Oracle SQL property graphs](https://docs.oracle.com/en/database/oracle/property-graph/26.1/spgdg/sql-property-graphs.html) expose property graphs over relational data; current Oracle documentation describes `GRAPH_TABLE` pattern matching and graph algorithm functions.
- Relational databases that support recursive CTEs can generally use an adjacency-list design like this lab, although exact recursion syntax and limits vary.

These can be a sensible choice when your organization is already committed to that database and wants graph capabilities without introducing another primary data platform.

## Comparison table

```text
Approach             Best fit                         Main cost
--------             --------                         ---------
fixed self-joins     known small hop count            depth is hard-coded
recursive CTE        bounded graph + relational data  verbose; path explosion
closure table        read-heavy tree/DAG              expensive maintenance
ltree/path           hierarchy with one lineage       awkward arbitrary graphs
nested sets          mostly static trees              costly moves/inserts
application algorithm custom algorithm control        round trips/data movement
Apache AGE           Cypher inside PostgreSQL         extension lifecycle
pgRouting            weighted/geospatial networks     specialized data model
property graph DB    graph-first patterns/algorithms  another data platform
RDF graph DB         semantics/ontology/linked data   different model and language
```

## When to stay with this lab's design

Stay with adjacency tables and recursive CTEs if most of these are true:

- PostgreSQL is already the system of record.
- Traversals are shallow or have a firm maximum depth.
- The graph is not extremely dense.
- Queries mostly ask reachability, hierarchy, dependency, or lineage questions.
- Strong joins to relational business data matter.
- Graph changes must commit atomically with ordinary rows.
- The team values low operational complexity more than concise graph syntax.

## Signals that it is time to evaluate another approach

- Recursive queries routinely hit timeouts or create huge intermediate results.
- The product needs weighted shortest paths, K-shortest paths, centrality, PageRank, or community detection.
- Most queries are variable-length graph patterns rather than relational queries.
- Developers spend substantial effort implementing graph semantics repeatedly.
- A graph projection or duplicate graph store can be refreshed predictably without violating consistency requirements.
- Benchmarks on representative data show a graph-specific option meeting requirements materially better.

## A practical migration path

```text
1. adjacency tables + recursive CTE
              |
              v
2. measure real depth, branching, latency, and write rate
              |
       +------+------+
       |             |
       v             v
3a. optimize SQL   3b. test AGE/pgRouting/graph DB
       |             |
       +------> compare with the same dataset and queries
                            |
                            v
                  4. choose from evidence
```

Keep the node and edge model portable, create a representative benchmark corpus, and compare correctness and operational cost—not only single-query latency.
