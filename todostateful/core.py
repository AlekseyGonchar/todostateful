from logging import Logger
from typing import Any, Callable, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
import orjson


orjson_options = orjson.OPT_NAIVE_UTC | orjson.OPT_NON_STR_KEYS


def orjson_dumps(  # type: ignore[misc]
    v: Any,  # noqa: WPS111
    *,
    default: Optional[Callable[[Any], Any]],
) -> str:
    return orjson.dumps(v, default=default, option=orjson_options).decode()


class BaseDto(BaseModel):
    pass

    class Config:
        anystr_strip_whitespace = True
        allow_population_by_field_name = True
        extra = "forbid"
        allow_mutation = False
        orm_mode = True
        json_loads = orjson.loads
        json_dumps = orjson_dumps


class BaseRepository:
    def __init__(
        self,
        db: AsyncSession,
        logger: Logger,
    ) -> None:
        self._db = db
        self._logger = logger
