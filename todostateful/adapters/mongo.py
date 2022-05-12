from beanie import init_beanie, Document
import motor.motor_asyncio
from todostateful.shared import BaseDto


class Task(BaseDto):
    pass


class TaskList(BaseDto):
    pass


class User(Document):
    pass


async def init() -> None:
    client = motor.motor_asyncio.AsyncIOMotorClient()
    await init_beanie(database=client.db_name)
