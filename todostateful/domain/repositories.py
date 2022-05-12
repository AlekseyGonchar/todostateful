from abc import ABC, abstractmethod


class TodoRepository(ABC):
    @abstractmethod
    async def get(self):
        ...

    @abstractmethod
    async def get_todo_by_email(self):
        ...

    @abstractmethod
    async def save(self):
        ...

    @abstractmethod
    async def delete(self):
        ...


class AuthRepository(ABC):
    @abstractmethod
    async def get_by_phone(self):
        pass
