#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

poetry run mypy . --install-types --non-interactive
poetry run flake8 .
poetry check
poetry run safety check --full-report
