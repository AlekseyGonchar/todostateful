#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

poetry install
poetry run pre-commit install
poetry run mypy . --install-types --non-interactive
