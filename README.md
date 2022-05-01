# todostateful

Проект использует [poetry](https://python-poetry.org/) для управления зависимостями, из-за чего докер образ сложнее обычного python-приложения на pip.

Для разделения и управления задачами используется [Task](#https://taskfile.dev/).

## Установка проекта

1. Установить корневые зависимости `poetry` и `task`

2. `task init` - установить проект и все его зависимости. Также устанавливает все stub'ы для mypy и pre-commit хуки.

## Запуск

1. Установить [docker](#https://docs.docker.com/engine/install/) и [docker-compose](#https://docs.docker.com/compose/install/)

2. `docker-compose up`

Для упрощения локального запуска, `docker-compose` не использует образ создаваемый buildx, для использования buildx нужно выполнить команду `task build:docker`
