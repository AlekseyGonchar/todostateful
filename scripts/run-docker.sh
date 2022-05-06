#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

docker run -d -p 8000:8000 todostateful:local
