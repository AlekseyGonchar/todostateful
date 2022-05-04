SHELL:=/usr/bin/env bash
.SHELLFLAGS := -e -u -o pipefail -c

.PHONY: lint
lint:
	poetry run mypy . --install-types --non-interactive
	poetry run flake8 .
	poetry check
	poetry run safety check --full-report

.PHONY: test
test:
	poetry run pytest -vv -x tests

.PHONY: docker
docker:
	docker build . \
		--tag="${APP_NAME}" \
		--build-arg REVISION="$(get_commit_hash)" \
		--build-arg CREATED="$(get_current_datetime)" \
		--build-arg VERSION="$(get_current_version)" \
		--build-arg PYTHON_VERSION="${PYTHON_VERSION}" \
		--build-arg POETRY_VERSION="${POETRY_VERSION}" \
		--build-arg APP_NAME="${APP_NAME}"
