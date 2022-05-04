SHELL:=/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script="./build.sh"

# Interface functions - BEGIN
function example {
  echo -e "example: $script --dockerfile Dockerfile --envfile build.env"
}

function usage {
  echo -e "usage: $script [OPTION]\n"
}

function help {
  usage
  echo -e "OPTION:"
  echo -e "  --dockerfile     VAL     Dockerfile to use in build"
  echo -e "  --envfile        VAL     ENV file to pass arguments"
  echo -e "  --registry       VAL     Registry to push built images"
  echo -e "  --help                   Prints this help\n"
  example
}

# Interface functions - END

# Script functions - BEGIN

function get_commit_hash {
  git log --pretty=format:'%H' -n 1
}

function get_current_datetime {
  date --rfc-3339=ns
}

function get_current_version {
  poetry version | awk 'END {print $NF}'
}

# Script functions - END

# Main
dockerfile="./Dockerfile"
envfile="./local.env"

# Args while-loop
while [ "$1" != "" ]; do
  case $1 in
  --dockerfile)
    dockerfile=$1
    ;;
  --envfile)
    shift
    envfile=$1
    ;;
  --registry)
    shift
    envfile=$1
    ;;
  --help)
    help
    exit
    ;;
  *)
    echo "$script: illegal option $1"
    usage
    example
    exit 1 # error
    ;;
  esac
  shift
done

# Building image
source $envfile

docker run -d -p 5000:5000 --restart=always --name registry registry:2

docker buildx build . \
  --file "$dockerfile" \
  --tag="${APP_NAME}" \
  --build-arg REVISION="$(get_commit_hash)" \
  --build-arg CREATED="$(get_current_datetime)" \
  --build-arg VERSION="$(get_current_version)" \
  --build-arg PYTHON_VERSION="${PYTHON_VERSION}" \
  --build-arg POETRY_VERSION="${POETRY_VERSION}" \
  --build-arg APP_NAME="${APP_NAME}"
