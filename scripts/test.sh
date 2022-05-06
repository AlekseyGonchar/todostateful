#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

poetry run pytest -vv -x tests
