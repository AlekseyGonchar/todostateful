# type: ignore
from fastapi import FastAPI, HTTPException
from typing import List, Mapping, Union
from todostateful.database import (
    create_todo,
    fetch_all_todos,
    update_todo,
    fetch_one_todo,
    remove_todo,
)
from todostateful.model import Todo
from todostateful.configs import Config
from fastapi.middleware.cors import CORSMiddleware
import uvicorn


app = FastAPI()

origins = [
    f"http://{Config().host}:{Config().port}",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/todo")
async def get_todo() -> List[Todo]:
    return await fetch_all_todos()


@app.post("/api/todo/", response_model=Todo)
async def post_todo(todo: Todo) -> Union[Todo, HTTPException]:
    response = await create_todo(todo.dict())

    if response:
        return response

    raise HTTPException(400, "Something went wrong")


@app.put("/api/todo/{title}/", response_model=Todo)
async def put_todo(title: str, desc: str) -> Union[Todo, HTTPException]:
    response = await update_todo(title, desc)

    if response:
        return response

    raise HTTPException(404, f"There is no todo with the title {title}")


@app.get("/api/todo/{title}", response_model=Todo)
async def get_todo_by_title(title: str) -> Union[Todo, HTTPException]:
    response = await fetch_one_todo(title)

    if response:
        return response

    raise HTTPException(404, f"There is no todo with the title {title}")


@app.delete("/api/todo/{title}")
async def delete_todo(title: str) -> Union[str, HTTPException]:
    response = await remove_todo(title)

    if response:
        return "Successfully deleted todo"

    raise HTTPException(404, f"There is no todo with the title {title}")


@app.get("/health")
async def health() -> Mapping[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(
        "__main__:app",
        host=Config().host,
        port=Config().port,
        reload=True,
        forwarded_allow_ips="*",
    )
