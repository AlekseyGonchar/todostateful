from logging import Logger
from typing import Literal, NewType
from todostateful.domain.repositories import AuthRepository, TodoRepository
from todostateful.domain import domain
from todostateful.libraries.shared import BaseDto


class TodoDto(BaseDto):
    pass


class TodoService:
    def __init__(self, logger: Logger, todo_repository: TodoRepository) -> None:
        self._logger = logger
        self._todo_repository = todo_repository

    async def _get_user_todo_if_exists(self, user_id: domain.EntityId) -> domain.Todo:
        todo = await self._todo_repository.get(user_id)

        if not todo:
            raise UserNotFound

        return todo

    async def create(self, todo_user_to_create) -> TodoDto:
        todo = await self._todo_repository.get_todo_by_email(todo_user_to_create.email)

        if todo:
           raise UserAlreadyExists

        todo = Todo()
        await self._todo_repository.save(todo)

    async def delete(self, todo_user_to_delete) -> Literal[True]:
        todo = await self._todo_repository.delete(todo_user_to_delete)
        return True

    async def get_all_tasks(self, user_id: EntityId) -> list[TaskDto]:
        todo = await self._get_user_todo_if_exists(user_id)
        return [TaskDto(**item) for item in todo.tasks]

    async def create_task(self, user_id: EntityId, task_to_create) -> TaskDto:
        todo = await self._get_user_todo_if_exists(user_id)
        resulting_task = todo.create_task(task_to_create)
        await self._todo_repository.save(todo)
        return resulting_task

    async def edit_task(self, user_id: EntityId, task_to_edit) -> TaskDto:
        todo = await self._get_user_todo_if_exists(user_id)
        resulting_task = todo.edit_task(task_to_edit)
        await self._todo_repository.save(todo)
        return resulting_task

    async def delete_task(self, user_id: EntityId, task_to_delete) -> Literal[True]:
        todo = await self._get_user_todo_if_exists(user_id)
        todo.delete_task(task_to_delete)
        await self._todo_repository.save(todo)
        return True


class AuthService:
    def __init__(
        self,
        logger: Logger,
        auth_repository: AuthRepository,
        todo_service: TodoService,
    ) -> None:
        self._logger = logger
        self._auth_repository = auth_repository
        self._todo_service = todo_service

    async def request_otp_auth(self, phone: Phone):
        user = await self._auth_repository.get_by_phone(phone)

        if not user:
            await self._auth_repository()


    async def verify_otp_auth(self, verify_phone):
        pass
