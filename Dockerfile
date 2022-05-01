# ARG APP_NAME=todostateful
# ARG PYTHON_VERSION=3.10
# ARG POETRY_VERSION=1.1.13

# # Use latest slim-buster as the fastest official python image with latest patches
# FROM python:$PYTHON_VERSION-slim-buster as base

# LABEL maintainer=""
# LABEL org.opencontainers.image.source=""

# ENV \
#   # python:
#   PYTHONDONTWRITEBYTECODE=1 \
#   PYTHONUNBUFFERED=1 \
#   PYTHONFAULTHANDLER=1 \
#   PYTHONHASHSEED=random \
#   # pip:
#   PIP_NO_CACHE_DIR=off \
#   PIP_DISABLE_PIP_VERSION_CHECK=on \
#   PIP_DEFAULT_TIMEOUT=100 \
#   # poetry:
#   POETRY_VERSION=$POETRY_VERSION \
#   POETRY_VIRTUALENVS_CREATE=false \
#   POETRY_NO_INTERACTION=1

# RUN apt-get update && apt-get upgrade -y \
#   && apt-get install --no-install-recommends -y \
#     bash \
#     build-essential \
#     curl \
#     gettext \
#     git \
#     libpq-dev \
#     && curl -sSL https://install.python-poetry.org | python -

# # Install Poetry - respects $POETRY_VERSION & $POETRY_HOME
# RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python
# ENV PATH="$POETRY_HOME/bin:$PATH"

# SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# RUN apt-get update && apt-get upgrade -y \
#   && apt-get install --no-install-recommends -y \
#     bash \
#     build-essential \
#     curl \
#     gettext \
#     git \
#     libpq-dev \
#   # Installing `poetry` package manager:
#   # https://github.com/python-poetry/poetry
#   && curl -sSL 'https://install.python-poetry.org' | python - \
#   && poetry --version \
#   # Cleaning cache:
#   && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
#   && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# # # Create dir for source code files
# # RUN mkdir /app
# # WORKDIR /app

# # # Install poetry
# # RUN pip install poetry

# # # Copy in the poetry config files
# # COPY pyproject.toml poetry.lock ./

# # # Install only production dependencies
# # RUN poetry install --no-root --no-dev

# # # Copy in everything else and install:
# # COPY . .
# # RUN poetry install --no-dev


# Set initial build args:
ARG APP_NAME="todostateful"
ARG PYTHON_VERSION="3.10"
ARG POETRY_VERSION="1.1.13"
ARG BRANCH=${BRANCH:-unknown}
ARG COMMIT=${COMMIT:-unknown}
ARG BUILD_TIME=${BUILD_TIME:-unknown}

# Base python image stage:
FROM python:${PYTHON_VERSION}-slim-buster as base

# Add image labels:
LABEL BRANCH=$BRANCH
LABEL COMMIT=$COMMIT
LABEL BUILD_TIME=$BUILD_TIME
LABEL MAINTAINER="tumberum@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/AlekseyGonchar/todostateful"

# Set environment variables:
# Current version metadata:
ENV COMMIT_SHA=${COMMIT}
ENV COMMIT_BRANCH=${BRANCH}
ENV COMMIT_BUILD_TIME=${BUILD_TIME}
# python:
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONFAULTHANDLER=1
ENV PYTHONHASHSEED="random"
# pip:
ENV PIP_NO_CACHE_DIR="off"
ENV PIP_DISABLE_PIP_VERSION_CHECK="on"
ENV PIP_DEFAULT_TIMEOUT=100
# poetry:
ENV POETRY_VERSION=$POETRY_VERSION
ENV POETRY_VIRTUALENVS_CREATE=false
ENV POETRY_NO_INTERACTION=1

# Build app as one docker layer command:
RUN \
  # Install patches && curl with build-essential and locales:
  apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y curl build-essential locales \
  # Installing poetry package manager:
  && curl -sSL 'https://install.python-poetry.org' | python - \
  && poetry --version \
  # Clean cache:
  && rm -rf /var/lib/apt/lists/*

RUN \
  # Install deps:
  poetry run pip install -U pip \
  && poetry install --no-dev --no-ansi \
  # Cleaning poetry installation's cache for production:
  && rm -rf "$POETRY_CACHE_DIR"

COPY poetry.lock pyproject.toml

# Entrypoint script
COPY ./docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["gunicorn", "--bind :$PORT", "--workers 1", "--threads 1", "--timeout 0", "\"$APP_NAME:create_app()\""]

# Create user
RUN groupadd -g 1500 app_user && \
    useradd -m -u 1500 -g app_user app_user

COPY --chown=app_user:app_user ./app /app
USER app_user
WORKDIR /${APP_NAME}

ENTRYPOINT /docker-entrypoint.sh $0 $@
CMD [ "gunicorn", "--worker-class uvicorn.workers.UvicornWorker", "--config /gunicorn_conf.py", "main:app"]
