from typing import NewType


EntityId = NewType('EntityId', str)
Phone = NewType('Phone', str)


class Task:
    id: EntityId


class User:
    pass


class Todo:
    pass


class Todo:
    id: EntityId

    def create_task(self):
        pass

    def edit_task(self):
        pass


class User:
    id: EntityId
