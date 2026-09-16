.PHONY: up down reset install walk paths shortest summary test load-examples demos \
	demo-org demo-bom demo-rbac demo-lineage demo-discussion demo-routes

up:
	docker compose up -d --wait

down:
	docker compose down

reset:
	docker compose down -v

install:
	python3 -m venv .venv
	. .venv/bin/activate && python -m pip install -r requirements.txt

walk:
	. .venv/bin/activate && python -m scripts.walk_graph --start storefront --max-depth 8

paths:
	. .venv/bin/activate && python -m scripts.find_paths storefront postgres

shortest:
	. .venv/bin/activate && python -m scripts.shortest_path storefront postgres

summary:
	. .venv/bin/activate && python -m scripts.dependency_summary --start storefront

test:
	. .venv/bin/activate && python -m unittest discover -s tests -v

load-examples:
	. .venv/bin/activate && python -m scripts.load_examples

demos: demo-org demo-bom demo-rbac demo-lineage demo-discussion demo-routes

demo-org:
	. .venv/bin/activate && python -m examples.org_chart.demo

demo-bom:
	. .venv/bin/activate && python -m examples.bill_of_materials.demo

demo-rbac:
	. .venv/bin/activate && python -m examples.permissions.demo

demo-lineage:
	. .venv/bin/activate && python -m examples.data_lineage.demo

demo-discussion:
	. .venv/bin/activate && python -m examples.discussion_threads.demo

demo-routes:
	. .venv/bin/activate && python -m examples.weighted_routes.demo
