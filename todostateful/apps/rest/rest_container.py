
from dependency_injector import containers, providers
from todostateful.domain.todo.repositories import user, task
from todostateful import adapters


class Container(containers.DeclarativeContainer):
    user_repository = providers.Factory(user.UserRepository)
