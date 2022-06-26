# todostateful

Проект использует [poetry](https://python-poetry.org/) для управления зависимостями, из-за чего докер образ сложнее обычного python-приложения на pip.

Для разделения и управления задачами используется [Task](#https://taskfile.dev/).

## Установка проекта

1. Установить корневые зависимости `poetry` и `task`

2. `task init` - установить проект и все его зависимости. Также устанавливает все stub'ы для mypy и pre-commit хуки.

## Запуск

1. Установить [docker](#https://docs.docker.com/engine/install/) и [docker-compose](#https://docs.docker.com/compose/install/)

2. `docker-compose up`

Для упрощения локального запуска, `docker-compose` не использует образ создаваемый buildx.

Для использования buildx нужно выполнить команду `task build:docker`, после чего запустить альтернативный `docker-compose` через `task run:compose-override`

## Запуск локального кластера

Для использования кластера требуется наличие:

1. [minikube](#https://minikube.sigs.k8s.io/docs/start/)
2. [Helm](#https://helm.sh/docs/intro/quickstart/)

После чего запустить скрипт

```bash
./minikube-setup.sh
```

Для доступа к кластеру посредством DNS-имен требуется настроить в качестве DNS [сервера сам кластер](#https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/)

Или же руками прописать IP minikube в `hosts`:

```bash
# Here 192.168.64.1 is your minikube cluster IP.
# You can use command `minikube ip` to find it out.
192.168.64.1 todostateful.localdev.me
```
