# Python version can be configured as ARG, mind '-' at the beggining:
ARG PYTHON_VERSION=3.10

# =============================================================================
# Base stage:
# =============================================================================
FROM python:${PYTHON_VERSION}-slim-bullseye as python-base
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# Build args:
ARG APP_NAME=todostateful
ARG POETRY_VERSION=1.1.13
ARG PYTHON_VERSION
# Container metadata args:
ARG REVISION
ARG CREATED
ARG VERSION
ARG AUTHORS="tumberum@gmail.com"
ARG URL="https://github.com/AlekseyGonchar/todostateful"
ARG LICENSES="MIT"

# Add image labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md:
LABEL org.opencontainers.image.title=todostateful
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.created="${CREATED}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="${AUTHORS}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.url="${URL}"
LABEL org.opencontainers.image.licenses="${LICENSES}"
LABEL org.opencontainers.image.base.name=python:${PYTHON_VERSION}-slim-bullseye

# Set environment variables:
# package:
ENV APP_NAME="todostateful"
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
ENV LOG_LEVEL=debug

# =============================================================================
# Runtime builder stage:
# =============================================================================
FROM python-base as builder-base
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Build app as one docker layer command:
# hadolint ignore=DL3008
RUN \
  # Install patches && curl with build-essential:
  apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y curl \
  # Installing poetry package manager:
  && curl -sSL 'https://install.python-poetry.org' | python - \
  && poetry --version \
  # Clean apt cache to reduce size:
  && rm -rf /var/lib/apt/lists/*

WORKDIR /todostateful

# Copy only lock and toml to install dependencies without code:
COPY ./poetry.lock ./pyproject.toml ./

RUN \
  # Install deps, without root package so docker layer caching works:
  poetry run pip install -U pip \
  && poetry install --no-dev --no-ansi --no-interaction --no-root \
  # Remove package cache to reduce layer size:
  && rm -rf "${POETRY_CACHE_DIR}"


# =============================================================================
# App build stage:
# =============================================================================
FROM python-base as app-base
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# COPY poetry and runtime deps:
COPY --from=builder-base /"${POETRY_HOME}" /"${POETRY_HOME}"
COPY --from=builder-base /todostateful /todostateful

WORKDIR /todostateful

# Create app user to avoid executing application as root:
RUN \
  groupadd -r app_user \
  && useradd -d /todostateful -r -g app_user app_user \
  && chown app_user:app_user -R .

# COPY application code:
COPY --chown=app_user:app_user ./todostateful ./todostateful

RUN \
  # Install root package via poetry:
  poetry install --no-dev --no-ansi --no-interaction \
  && rm -rf "${POETRY_CACHE_DIR}"

USER app_user

HEALTHCHECK \
  --interval=5m \
  --timeout=5s \
  --retries=5 \
CMD curl -f / http://localhost:8000/health || exit 1

EXPOSE 8000

ENTRYPOINT ["poetry", "run"]

CMD [ \
  "uvicorn", \
  "todostateful.main:app", \
  "--reload", \
  "--host", \
  "0.0.0.0", \
  "--port", \
  "8000" \
]

# TODO: Add separate development stage
# TODO: without poetry and optionally with gunicorn
