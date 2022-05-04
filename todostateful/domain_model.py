from abc import ABC
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import NewType, Optional, Union
from uuid import UUID, uuid4
from enum import Enum

EntityId = NewType('EntityId', UUID)
Name = NewType('Name', str)
Description = NewType('Description', str)


class RepeatPeriod(Enum):
    DAY = timedelta(days=1)
    WEEK = timedelta(days=7)
    MONTH = timedelta(days=30)
    YEAR = timedelta(days=365)


class DueTime(ABC):
    pass


class RepeatableDueTime(DueTime):
    pass


class ConcreteDueTime(DueTime):
    pass


class Task(object):
    uid: EntityId
    name: Name
    description: Description | None
    due_time: ConcreteDueTime | RepeatableDueTime | None

    def __init__(self) -> None:
        pass


class TaskList(object):
    max_tasks: int = 100

    def __init__(self, name: Name) -> None:
        self.uid = EntityId(uuid4())
        self.name = name
        self.tasks: list[Task] = []

    def create_task(
        self,
        task_name: Name,
        description: Description | None = None,
        due_time: RepeatableDueTime | ConcreteDueTime | None = None,
    ) -> Task:
        pass


class User(object):
    max_task_lists: int = 5

    def __init__(self) -> None:
        self.uid = EntityId(uuid4())
        self._task_lists: list[TaskList] = []
