from datetime import datetime
from typing import Optional
from beanie import init_beanie, Document, Link
import motor.motor_asyncio
from todostateful.shared import BaseDto
from uuid import UUID, uuid4
from pydantic import Field


class Task(BaseDto):
    name: str
    description: str | None
    due_time: datetime | None
    done: bool = False
    created_at: datetime


class User(BaseDto):
    name: str | None
    updated_at: Optional[datetime]


class Todo(Document):
    id: UUID = Field(default_factory=uuid4)  # type: ignore[assignment]
    user: User
    tasks: list[Task]
    created_at: datetime


class AuthSession(BaseDto):
    key: Optional[str]
    expires_at: datetime
    created_at: datetime


class Auth(Document):
    id: UUID = Field(default_factory=uuid4)  # type: ignore[assignment]
    todo: Link[Todo]
    sessions: list[AuthSession]


async def init(client: motor.motor_asyncio.AsyncIOMotorDatabase) -> None:
    # client = motor.motor_asyncio.AsyncIOMotorClient("mongodb://user:pass@host:27017")
    await init_beanie(database=client.db_name)
