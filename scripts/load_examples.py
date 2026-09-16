from __future__ import annotations

from examples.common import EXAMPLE_NAMES, initialize_example
from scripts.common import connect


def main() -> None:
    with connect() as connection:
        for example_name in EXAMPLE_NAMES:
            initialize_example(connection, example_name)
            print(f"Loaded example: {example_name}")


if __name__ == "__main__":
    main()
