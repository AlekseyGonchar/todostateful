from typing import List, Optional

from pydantic import Field
from sqlalchemy import select

from todostateful.shared import BaseRepository, BaseDto
from todostateful.adapters.db import TaskSchema, UserSchema

class TaskBase(BaseDto):
    title: str = Field(..., max_length=1024)


class Task(TaskBase):
    id: int = Field(..., gt=0)
    done: bool = Field(False)


class TaskCreate(TaskBase):
    pass


class TaskUpdate(TaskBase):
    done: bool = Field(default=False)


class TaskRepository(BaseRepository):
    async def create_task(
        self,
        task_create: TaskCreate,
        user_id: int,
    ) -> Task:
        task = Task(**task_create.dict(), owner_id=user_id)
        task.done = False
        self._db.add(task)

        await self._db.commit()
        await self._db.refresh(task)

        return task

    async def get_task(self, id: int) -> Optional[Task]:
        stmt = select(TaskSchema).where(TaskSchema.id == id)
        query_result = await self._db.execute(stmt)
        task: Optional[TaskSchema] = query_result.scalar()

        return Task.from_orm(task) if task else None

    async def get_tasks(self, id: int) -> List[Task]:
        stmt = select(TaskSchema).where(UserSchema.id == id)
        query_result = await self._db.execute(stmt)
        tasks: List[TaskSchema] = query_result.scalars().all()

        return [Task.from_orm(task) for task in tasks]

    async def update_task(self, task: Task) -> Task:
        self._db.add(task)

        await self._db.commit()
        await self._db.refresh(task)

        return task

    async def delete_task(self, task: Task) -> None:
        await self._db.delete(task)
        await self._db.commit()
