# Set python version before first FROM, so python version can be configured in docker:
ARG PYTHON_VERSION=3.10

# ===========
# Base stage:
# ===========
FROM python:${PYTHON_VERSION}-slim-buster as python-base

# Build args:
ARG APP_NAME=todostateful
ARG POETRY_VERSION=1.1.13
ARG PYTHON_VERSION
# Container metadata:
ARG REVISION
ARG CREATED
ARG VERSION
ARG AUTHORS="tumberum@gmail.com"
ARG URL="https://github.com/AlekseyGonchar/todostateful"
ARG LICENSES="MIT"

# Add image labels:
LABEL org.opencontainers.image.title="${APP_NAME}"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.created="${CREATED}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="${AUTHORS}"
LABEL org.opencontainers.image.url="${URL}"
LABEL org.opencontainers.image.licenses="${LICENSES}"
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


# ===================================
# Runtime dependeicnes builder stage:
# ===================================
FROM python-base as builder-base

# Reason: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#using-pipes
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

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
  # Install deps, no root package so docker layer caching works:
  poetry run pip install -U pip \
  && poetry install --no-dev --no-ansi --no-interaction --no-root \
  # Remove package cache to reduce layer size:
  && rm -rf "${POETRY_CACHE_DIR}"


# =====================================
# Development dependencies build stage:
# =====================================
FROM builder-base as development-builder-base

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

RUN \
  # Install development dependencies so they work inside container
  poetry install --no-ansi --no-interaction --no-root \
  && rm -rf "${POETRY_CACHE_DIR}"


# =======================
# Production build stage:
# =======================
FROM python-base as production

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

COPY --from=builder-base $APP_NAME $APP_NAME

# Create app user to avoid executing application as root:
RUN \
  groupadd -r app_user \
  && useradd -d /"${APP_NAME}" -r -g app_user app_user \
  && chown app_user:app_user -R /"${APP_NAME}"

WORKDIR /"${APP_NAME}"

# COPY application code near venv
COPY --chown=app_user:app_user ./"${APP_NAME}" ./"${APP_NAME}"

# install again using cache results in instaling root package only
# RUN poetry install --no-dev --no-ansi --no-interaction

USER app_user

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl -f / http://localhost:8000/health || exit 1

ENTRYPOINT [".", "/opt/pysetup/.venv/bin/activate"]

CMD ["uvicorn", "app.main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "8000"]


# ========================
# Development build stage:
# ========================
FROM python-base as development

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# COPY poetry and application dependencies installed in previos stage:
COPY --from=development-builder-base $POETRY_HOME $POETRY_HOME
COPY --from=development-builder-base $APP_NAME $APP_NAME
COPY ./"${APP_NAME}" ./"${APP_NAME}"

# install again using cache results in instaling root package only
RUN poetry install --no-dev --no-ansi --no-interaction

EXPOSE 8000

ENTRYPOINT ["poetry", "run"]

CMD ["uvicorn", "app.main:app", "--proxy-headers", "--reload", "--host", "0.0.0.0", "--port", "8000"]
