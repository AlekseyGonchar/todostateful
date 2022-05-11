from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from sqlalchemy.sql.schema import ForeignKey

ASYNC_DB_URL = "postgresql://postgres@postgres/postgres"

engine = create_async_engine(ASYNC_DB_URL, echo=True, future=True)

async_session: AsyncSession = sessionmaker(
    autoflush=True, bind=engine, class_=AsyncSession, future=True
)

Base = declarative_base()


class UserSchema(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(60))
    email = Column(String(254), unique=True)
    password = Column(String(60))
    activated = Column(Boolean)

    tasks = relationship("TaskSchema", back_populates="owner")


class TaskSchema(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(1024))
    done = Column(Boolean)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("UserSchema", back_populates="tasks")


async def get_db() -> AsyncSession:
    async with async_session() as session:
        yield session
