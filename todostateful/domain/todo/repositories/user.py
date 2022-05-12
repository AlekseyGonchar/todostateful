import imp
from typing import Optional

from pydantic import Field
from sqlalchemy import select

from todostateful.shared import BaseRepository, BaseDto
from todostateful.adapters.db import UserSchema


class UserBase(BaseDto):
    username: str = Field(...)


class User(UserBase):
    id: int = Field(...)
    email: str = Field(...)
    activated: bool = Field(False)
    password: str = Field(...)

    class Config:
        orm_mode = True


class UserCreate(UserBase):
    email: str = Field(...)
    password: str = Field(...)


class UserRepository(BaseRepository):
    async def create_user(self, form_data: UserCreate) -> User:
        user = UserSchema(**form_data.dict(), activated = True)
        self._db.add(user)

        await self._db.commit()
        await self._db.refresh(user)

        return user

    async def get_user(self, username: str) -> Optional[User]:
        stmt = select(User).where(User.username == username)
        query_result = await self._db.execute(stmt)
        user: Optional[UserSchema] = query_result.scalar()

        return User.from_orm(user) if user else None
