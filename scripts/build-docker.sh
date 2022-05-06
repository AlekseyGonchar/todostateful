#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function get_commit_hash {
  git log --pretty=format:'%H' -n 1
}

function get_branch_name {
  git branch --show-current
}

function get_current_datetime {
  date --rfc-3339=ns
}

function get_current_version {
  poetry version | awk 'END {print $NF}'
}

function get_full_revision {
  echo "$(get_current_version)"-"$(get_branch_name)"
}

cd ..

docker buildx build . \
  --tag todostateful:latest todostateful:"$(get_full_revision)" \
  --build-arg REVISION="$(get_commit_hash)" \
  --build-arg CREATED="$(get_current_datetime)" \
  --build-arg VERSION="$(get_full_revision)"
