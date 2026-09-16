from __future__ import annotations

import subprocess
import sys
import unittest
from decimal import Decimal

from examples.common import initialize_all_examples, read_example_sql
from scripts.common import PROJECT_ROOT, connect, load_query


class GraphQueryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.connection = connect()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.connection.close()

    def execute(self, filename: str, parameters: dict[str, object]):
        return self.connection.execute(
            load_query(filename), parameters
        ).fetchall()

    def run_cli(self, module: str, *arguments: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, "-m", module, *arguments],
            cwd=PROJECT_ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_walk_is_bounded_by_max_depth(self) -> None:
        rows = self.execute(
            "01_walk.sql", {"start": "storefront", "max_depth": 2}
        )

        self.assertEqual(7, len(rows))
        self.assertEqual(2, max(row["depth"] for row in rows))

    def test_walk_stops_at_cycle(self) -> None:
        rows = self.execute(
            "01_walk.sql", {"start": "pricing", "max_depth": 8}
        )

        self.assertEqual(
            ["pricing", "legacy_tax_rules", "postgres"],
            [row["name"] for row in rows],
        )

    def test_all_expected_paths_are_found(self) -> None:
        rows = self.execute(
            "02_find_paths.sql",
            {"source": "storefront", "target": "postgres", "max_depth": 8},
        )

        self.assertEqual([3, 3, 3, 4, 4], [row["depth"] for row in rows])

    def test_shortest_path_uses_fewest_hops(self) -> None:
        rows = self.execute(
            "03_shortest_path.sql",
            {"source": "storefront", "target": "postgres", "max_depth": 8},
        )

        self.assertEqual(1, len(rows))
        self.assertEqual(3, rows[0]["depth"])
        self.assertEqual(
            "storefront -> api -> catalog -> postgres", rows[0]["path"]
        )

    def test_dependency_summary_counts_paths(self) -> None:
        rows = self.execute(
            "04_dependency_summary.sql", {"start": "storefront", "max_depth": 8}
        )
        postgres_row = next(row for row in rows if row["name"] == "postgres")

        self.assertEqual(3, postgres_row["min_hops"])
        self.assertEqual(5, postgres_row["simple_path_count"])

    def test_leaf_summary_is_a_successful_empty_result(self) -> None:
        result = self.run_cli(
            "scripts.dependency_summary", "--start", "postgres"
        )

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("No dependencies reachable from 'postgres'.", result.stdout)

    def test_find_paths_rejects_a_missing_source(self) -> None:
        result = self.run_cli(
            "scripts.find_paths", "does_not_exist", "postgres"
        )

        self.assertNotEqual(0, result.returncode)
        self.assertIn("Unknown node: 'does_not_exist'.", result.stderr)

    def test_shortest_path_rejects_a_missing_target(self) -> None:
        result = self.run_cli(
            "scripts.shortest_path", "storefront", "does_not_exist"
        )

        self.assertNotEqual(0, result.returncode)
        self.assertIn("Unknown node: 'does_not_exist'.", result.stderr)


class PracticalExampleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.connection = connect()
        initialize_all_examples(cls.connection)
        cls.connection.execute(
            """
            TRUNCATE TABLE
                org.employees,
                bom.components,
                bom.parts,
                rbac.user_roles,
                rbac.role_inheritance,
                rbac.role_permissions,
                rbac.users,
                rbac.roles,
                rbac.permissions,
                lineage.dependencies,
                lineage.assets,
                discussion.comments,
                routes.connections,
                routes.locations
            RESTART IDENTITY CASCADE
            """
        )
        initialize_all_examples(cls.connection)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.connection.rollback()
        cls.connection.close()

    def execute(
        self, example: str, query: str, parameters: dict[str, object]
    ):
        return self.connection.execute(
            read_example_sql(example, f"queries/{query}"), parameters
        ).fetchall()

    def test_organization_reports_and_management_chain(self) -> None:
        reports = self.execute(
            "org_chart", "01_reports.sql", {"manager": "Alice", "max_depth": 8}
        )
        chain = self.execute(
            "org_chart",
            "02_management_chain.sql",
            {"employee": "Erin", "max_depth": 8},
        )

        self.assertEqual(7, len(reports))
        self.assertEqual(
            ["Alice", "Bob", "Deepa", "Erin"],
            [row["name"] for row in chain],
        )

    def test_bill_of_materials_multiplies_and_aggregates(self) -> None:
        rows = self.execute(
            "bill_of_materials",
            "02_totals.sql",
            {"part": "bicycle", "max_depth": 8},
        )
        totals = {row["name"]: row["total_required"] for row in rows}

        self.assertEqual(Decimal("72"), totals["spoke"])
        self.assertEqual(Decimal("8"), totals["bolt"])
        self.assertEqual(Decimal("2"), totals["wheel"])

    def test_permissions_keep_paths_but_deduplicate_grants(self) -> None:
        roles = self.execute(
            "permissions",
            "01_effective_roles.sql",
            {"user": "alice", "max_depth": 8},
        )
        permissions = self.execute(
            "permissions",
            "02_effective_permissions.sql",
            {"user": "alice", "max_depth": 8},
        )

        self.assertEqual(2, sum(row["role_name"] == "viewer" for row in roles))
        self.assertEqual(
            {"edit_content", "manage_users", "read_reports", "view_audit_log"},
            {row["permission"] for row in permissions},
        )

    def test_data_lineage_walks_upstream_and_downstream(self) -> None:
        upstream = self.execute(
            "data_lineage",
            "01_upstream.sql",
            {"asset": "dashboard_revenue", "max_depth": 8},
        )
        impact = self.execute(
            "data_lineage",
            "02_downstream_impact.sql",
            {"asset": "raw_orders", "max_depth": 8},
        )

        self.assertIn("raw_orders", {row["name"] for row in upstream})
        self.assertEqual(
            {"customer_metrics", "dashboard_retention", "dashboard_revenue"},
            {
                row["name"]
                for row in impact
                if row["asset_type"] in {"dashboard", "warehouse_model"}
                and row["name"].startswith(("customer", "dashboard"))
            },
        )

    def test_discussion_thread_uses_depth_first_order(self) -> None:
        rows = self.execute(
            "discussion_threads",
            "01_thread.sql",
            {"thread": "recursive-cte-tips", "max_depth": 8},
        )

        self.assertEqual(
            ["root", "reply-bob", "reply-deepa", "reply-erin", "reply-carol"],
            [row["comment_key"] for row in rows],
        )
        self.assertEqual([0, 1, 2, 3, 1], [row["depth"] for row in rows])

    def test_weighted_shortest_differs_from_fewest_hops(self) -> None:
        parameters = {"source": "Depot", "target": "Store", "max_depth": 6}
        shortest_distance = self.execute(
            "weighted_routes", "02_shortest_distance.sql", parameters
        )[0]
        fewest_hops = self.execute(
            "weighted_routes", "03_fewest_hops.sql", parameters
        )[0]

        self.assertEqual(Decimal("7"), shortest_distance["total_distance_km"])
        self.assertEqual(3, shortest_distance["depth"])
        self.assertEqual(2, fewest_hops["depth"])
        self.assertEqual(Decimal("10"), fewest_hops["total_distance_km"])


if __name__ == "__main__":
    unittest.main()
