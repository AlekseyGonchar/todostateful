from pydantic import BaseSettings


class Config(BaseSettings):
    host: str = "0.0.0.0"
    port: int = 8000
    mongo_dsn: str = "mongodb://user:pass@host:27017"
