from abc import ABC
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import NewType, Optional, Union
from uuid import UUID
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


@dataclass(kw_only=True, slots=True, frozen=True)
class RepeatableDueTime(DueTime):
    pass


@dataclass(kw_only=True, slots=True, frozen=True)
class ConcreteDueTime(DueTime):
    pass


@dataclass(kw_only=True, slots=True)
class Task:
    uid: EntityId
    name: Name
    description: Description | None
    due_time: ConcreteDueTime | RepeatableDueTime | None


@dataclass(kw_only=True, slots=True)
class TaskList:
    uid: EntityId
    name: Name
    tasks: list[Task]

    def create_task(
        self,
        task_name: Name,
        description: Description | None = None,
        due_time: RepeatableDueTime | ConcreteDueTime | None = None,
    ) -> Task:
        pass


@dataclass(kw_only=True, slots=True)
class User:
    uid: EntityId
    task_lists: list[TaskList]

    def create_task_list(self, task_list_name: Name) -> TaskList:
        pass
