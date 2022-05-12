from typing import Any, Callable, Optional

import orjson
from pydantic import BaseModel
from typing import List, Type, Optional, Mapping, Any

from starlette import status


orjson_options = orjson.OPT_NAIVE_UTC | orjson.OPT_NON_STR_KEYS


def orjson_dumps(v: Any, *, default: Optional[Callable[[Any], Any]]) -> str:  # type: ignore[misc]
    return orjson.dumps(v, default=default, option=orjson_options).decode()


class BaseDto(BaseModel):
    pass

    class Config:
        anystr_strip_whitespace = True
        allow_population_by_field_name = True
        extra = "forbid"
        orm_mode = True
        json_loads = orjson.loads
        json_dumps = orjson_dumps


class AppException(Exception):
    status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR
    message: str = 'Internal server error'

    def __init__(  # type: ignore[misc]
        self,
        message: str | None = None,
        payload: Mapping[str, Any] | None = None,
        debug: Any = None,
    ) -> None:
        self.message = message or self.message
        self.payload = payload
        self.debug = debug

    @classmethod
    def code(cls) -> str:
        return cls.__name__

    def to_json(self) -> Mapping[str, Any]:  # type: ignore[misc]
        return {
            'code': self.code(),
            'message': self.message,
            'payload': self.payload,
            'debug': self.debug,
        }


def exception_schema(exceptions: List[Type[AppException]]) -> Mapping[int, Any]:  # type: ignore[misc]
    responses: dict[int, dict[str, Any]] = {}  # type: ignore[misc]

    schema = {
        'type': 'object',
        'properties': {
            'code': {
                'type': 'string',
                'title': 'Semantic code',
            },
            'message': {
                'type': 'string',
                'title': 'Description',
            },
            'payload': {
                'type': 'object',
                'title': 'Error body'
            },
            'debug': {
                'type': 'string',
                'title': 'Debug info'
            }
        }
    }

    for exc in exceptions:
        code = exc.code()

        if exc.status_code not in responses:
            responses[exc.status_code] = {}

        responses[exc.status_code][code] = {
            'value': {
                'code': code,
                'message': exc.message
            }
        }

    return {
        status_code: {
            'content': {
                'application/json': {
                    'schema': schema,
                    'examples': examples
                }
            }
        }
        for status_code, examples in responses.items()
    }
