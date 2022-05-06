from db import Base
from sqlalchemy import create_engine

DB_URL = 'psql://postgres@postgres/postgres'

engine = create_engine(DB_URL, echo=True)


def reset_database() -> None:
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)


if __name__ == '__main__':
    reset_database()
