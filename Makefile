SHELL:=/usr/bin/env bash

.PHONY: lint
lint:
	poetry run mypy . --install-types --non-interactive
	poetry run flake8 .
	poetry check
	poetry run safety check --full-report

.PHONY: test
test:
	poetry run pytest -vv -x tests

.PHONY: format
format:
	poetry run isort .
