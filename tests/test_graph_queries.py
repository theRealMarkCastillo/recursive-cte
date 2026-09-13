from __future__ import annotations

import subprocess
import sys
import unittest

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


if __name__ == "__main__":
    unittest.main()
