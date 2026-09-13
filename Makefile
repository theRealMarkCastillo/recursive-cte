.PHONY: up down reset install walk paths shortest summary

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
	. .venv/bin/activate && python -m scripts.walk_graph --start storefront

paths:
	. .venv/bin/activate && python -m scripts.find_paths storefront postgres

shortest:
	. .venv/bin/activate && python -m scripts.shortest_path storefront postgres

summary:
	. .venv/bin/activate && python -m scripts.dependency_summary --start storefront
