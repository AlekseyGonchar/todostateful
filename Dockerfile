ARG PYTHON_VERSION=3.10

FROM python:${PYTHON_VERSION}-slim-buster as python-base

ARG APP_NAME=todostateful
ARG REVISION=unknown
ARG CREATED=unknown
ARG VERSION=unknown
ARG POETRY_VERSION=1.1.13
ARG PYTHON_VERSION

# Add image labels:
LABEL org.opencontainers.image.title="${APP_NAME}"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.created="${CREATED}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="tumberum@gmail.com"
LABEL org.opencontainers.image.url="https://github.com/AlekseyGonchar/todostateful"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.base.name=python:${PYTHON_VERSION}-slim-buster

# Set environment variables:
# Current version metadata:
ENV \
  APP_NAME="${APP_NAME}" \
  # python:
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONFAULTHANDLER=1 \
  PYTHONHASHSEED="random" \
  # pip:
  PIP_NO_CACHE_DIR=1 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  PIP_DEFAULT_TIMEOUT=100 \
  # poetry:
  POETRY_VERSION="${POETRY_VERSION}" \
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  POETRY_NO_INTERACTION=1 \
  POETRY_CACHE_DIR='/var/cache/pypoetry' \
  POETRY_HOME='/usr/local'

FROM python-base as builder-base

# Reason: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#using-pipes
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Build app as one docker layer command:
# hadolint ignore=DL3008
RUN \
  # Install patches && curl with build-essential:
  apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y curl build-essential \
  # Installing poetry package manager:
  && curl -sSL 'https://install.python-poetry.org' | python - \
  && poetry --version \
  # Clean cache:
  && rm -rf /var/lib/apt/lists/*

WORKDIR "${APP_NAME}"

COPY ./poetry.lock ./pyproject.toml ./

RUN \
  # Install deps, no root package so docker layer caching works:
  poetry run pip install -U pip \
  && poetry install --no-dev --no-ansi --no-interaction --no-root \
  && rm -rf "${POETRY_CACHE_DIR}"

FROM python-base as application

COPY --from=builder-base $POETRY_HOME $POETRY_HOME
COPY --from=builder-base $APP_NAME $APP_NAME

# Create app user:
RUN \
  groupadd -r app_user \
  && useradd -d /"${APP_NAME}" -r -g app_user app_user \
  && chown app_user:app_user -R /"${APP_NAME}"

WORKDIR /"${APP_NAME}"

COPY --chown=app_user:app_user ./"${APP_NAME}" ./"${APP_NAME}"

# install again using cache results in instaling root package only
RUN poetry install --no-dev --no-ansi --no-interaction

USER app_user

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl -f / http://localhost:8000/health || exit 1

CMD [ \
  "poetry", \
  "run", \
  "gunicorn", \
  "-w", \
  "1", \
  "-k", \
  "uvicorn.workers.UvicornWorker", \
  "todostateful.rest_app:app", \
  "-b", \
  "0.0.0.0:8000", \
  "--disable-redirect-access-to-syslog", \
  "--forwarded-allow-ips=\"*\"" \
]
