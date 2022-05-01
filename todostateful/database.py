# type: ignore
from typing import List
import motor.motor_asyncio
from todostateful.model import Todo
from todostateful.configs import Config

client = motor.motor_asyncio.AsyncIOMotorClient(Config().mongo_dsn)

db = client.db
collection = db.todo


async def fetch_all_todos() -> List[Todo]:
    todos = []
    cursor = collection.find({})

    async for document in cursor:
        todos.append(Todo(**document))

    return todos


async def create_todo(todo: Todo) -> Todo:
    document = todo
    await collection.insert_one(document)

    return document


async def update_todo(title: str, desc: str) -> Todo:
    await collection.update_one(
        {"title": title}, {"$set": {"description": desc}}
    )
    document = await collection.find_one({"title": title})

    return document


async def fetch_one_todo(title: str) -> Todo:
    document = await collection.find_one({"title": title})

    return document


async def remove_todo(title: str) -> bool:
    await collection.delete_one({"title": title})

    return True
