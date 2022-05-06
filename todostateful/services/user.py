class UserBase(BaseModel):
    username: str = Field(...)


class User(UserBase):
    id: int = Field(...)
    email: str = Field(...)
    activated: bool = Field(False, description="user is activated or not")

    class Config:
        orm_mode = True


class UserCreate(UserBase):
    email: str = Field(...)
    password: str = Field(...)


class UserService(object):
    async def create_user(db: AsyncSession, form_data: UserCreate) -> User:
        user = User(**form_data.dict())
        user.activated = True
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    async def get_user(db: AsyncSession, username: str):
        stmt = select(User).where(User.username == username)
        result: Result = await db.execute(stmt)
        return result.scalar()
