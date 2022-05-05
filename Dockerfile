# Set python version before first FROM
# so python version can be configured as ARG:
ARG PYTHON_VERSION=3.10

# =============================================================================
# Base stage:
# Configures python environment, metadata and labels
# =============================================================================
FROM python:${PYTHON_VERSION}-slim-buster as python-base

# Build args:
ARG APP_NAME=todostateful
ARG POETRY_VERSION=1.1.13
ARG PYTHON_VERSION
ARG DEBIAN_FRONTEND=noninteractive
# Container metadata:
ARG REVISION
ARG CREATED
ARG VERSION
ARG AUTHORS="tumberum@gmail.com"
ARG URL="https://github.com/AlekseyGonchar/todostateful"
ARG LICENSES="MIT"

# Add image labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md:
LABEL org.opencontainers.image.title="${APP_NAME}"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.created="${CREATED}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="${AUTHORS}"
LABEL org.opencontainers.image.source="${SOURCE}"
LABEL org.opencontainers.image.url="${URL}"
LABEL org.opencontainers.image.licenses="${LICENSES}"
LABEL org.opencontainers.image.base.name=python:${PYTHON_VERSION}-slim-buster

# Set environment variables:
# package:
ENV APP_NAME="${APP_NAME}"
# python:
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONFAULTHANDLER=1
ENV PYTHONHASHSEED="random"
# pip:
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_DEFAULT_TIMEOUT=100
# poetry:
ENV POETRY_VERSION="${POETRY_VERSION}"
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV POETRY_NO_INTERACTION=1
ENV POETRY_CACHE_DIR='/var/cache/pypoetry'
ENV POETRY_HOME='/usr/local'


# =============================================================================
# Runtime builder stage:
# Upgrades system dependencies and installs poetry
# =============================================================================
FROM python-base as builder-base

ARG DEBIAN_FRONTEND=noninteractive

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
  # Clean apt cache to reduce size:
  && rm -rf /var/lib/apt/lists/*

WORKDIR "${APP_NAME}"

# Copy only lock and toml to install dependencies without code:
COPY ./poetry.lock ./pyproject.toml ./

RUN \
  # Install deps, without root package so docker layer caching works:
  poetry run pip install -U pip \
  && poetry install --no-dev --no-ansi --no-interaction --no-root \
  # Remove package cache to reduce layer size:
  && rm -rf "${POETRY_CACHE_DIR}"


# =============================================================================
# Production build stage:
# Installs runtime-only dependencies and runs CMD using venv
# =============================================================================
FROM python-base as production

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

COPY --from=builder-base ${APP_NAME} ${APP_NAME}

# Create app user to avoid executing application as root:
RUN \
  groupadd -r app_user \
  && useradd -d /"${APP_NAME}" -r -g app_user app_user \
  && chown app_user:app_user -R /"${APP_NAME}"

WORKDIR /"${APP_NAME}"

# COPY application code near venv
COPY --chown=app_user:app_user ./"${APP_NAME}" ./"${APP_NAME}"

USER app_user

EXPOSE 8000

HEALTHCHECK \
  --interval=5m \
  --timeout=5s \
  --retries=5 \
CMD curl -f / http://localhost:8000/health || exit 1

# ENTRYPOINT ["source", "/${APP_NAME}/.venv/bin/activate"]

# CMD [ \
#   "uvicorn", \
#   "app.main:app", \
#   "--proxy-headers", \
#   "--host", \
#   "0.0.0.0", \
#   "--port", \
#   "8000"\
# ]


# =============================================================================
# Development build stage:
# Installs all dependencies and root application
# =============================================================================
FROM python-base as development

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

WORKDIR ${APP_NAME}

# COPY poetry and application dependencies installed in previos stage:
COPY --from=builder-base ${POETRY_HOME} ${POETRY_HOME}
COPY --from=builder-base ${APP_NAME} .
COPY ./"${APP_NAME}" ./"${APP_NAME}"

RUN \
  # Install development dependencies and root package:
  poetry install --no-ansi --no-interaction \
  && rm -rf "${POETRY_CACHE_DIR}"

EXPOSE 8000

ENTRYPOINT ["poetry", "run"]

CMD [ \
  "uvicorn", \
  "app.main:app", \
  "--proxy-headers", \
  "--reload", \
  "--host", \
  "0.0.0.0", \
  "--port", \
  "8000"\
]
