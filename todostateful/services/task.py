

class TaskBase(BaseModel):
    title: str = Field(..., example="running", max_length=1024)


class Task(TaskBase):
    id: int = Field(..., gt=0, example=1)
    done: bool = Field(False, description="done task or not")

    class Config:
        orm_mode = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(TaskBase):
    done: bool = Field(default=False, description="done task or not")


class TaskService(object):
    async def create_task(
        db: AsyncSession,
        task_create: TaskCreate,
        user_id: int
    ) -> Task:
        task = Task(**task_create.dict(), owner_id=user_id)
        task.done = False
        db.add(task)
        await db.commit()
        await db.refresh(task)
        return task


    async def get_task(db: AsyncSession, id: int) -> Optional[Task]:
        stmt = select(Task).where(Task.id == id)
        result: Result = await db.execute(stmt)
        return result.scalar()


    async def get_tasks(db: AsyncSession, id: int) -> List[Task]:
        stmt = select(Task).where(User.id == id)
        result: Result = await db.execute(stmt)
        return result.scalars().all()


    async def update_task(
        db: AsyncSession, task: Task
    ) -> Task:
        db.add(task)
        await db.commit()
        await db.refresh(task)
        return task


    async def delete_task(db: AsyncSession, task: Task) -> None:
        await db.delete(task)
        await db.commit()
