import logging
from typing import Any, Callable, Mapping, Optional

import orjson
import sentry_sdk
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sentry_sdk.integrations.logging import ignore_logger

orjson_options = orjson.OPT_NAIVE_UTC | orjson.OPT_NON_STR_KEYS


def orjson_dumps(  # type: ignore[misc]
    v: Any,  # noqa: WPS111
    *,
    default: Optional[Callable[[Any], Any]],
) -> str:
    return orjson.dumps(v, default=default, option=orjson_options).decode()


class BaseDTO(BaseModel):
    class Config:  # noqa: WPS306, WPS431
        anystr_strip_whitespace = True
        allow_population_by_field_name = True
        extra = 'forbid'
        allow_mutation = False
        orm_mode = True
        json_loads = orjson.loads
        json_dumps = orjson_dumps


class ORJSONResponse(JSONResponse):
    def render(self, content_to_render: Any) -> bytes:  # type: ignore[misc]
        return orjson.dumps(
            content_to_render,
            option=orjson_options,
        )


def init_logger() -> None:
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger('app')
    logger.setLevel(logging.INFO)


def init_sentry() -> None:
    sentry_sdk.init()  # type: ignore[abstract]
    ignore_logger('app')


app = FastAPI(default_response_class=ORJSONResponse)
app.add_middleware(
    CORSMiddleware,
    allow_origins='*',
    allow_methods='*',
)


@app.get('/health')
async def health() -> Mapping[str, str]:
    return {'status': 'ok'}


if __name__ == '__main__':
    uvicorn.run(
        '__main__:app',
        host='0.0.0.0',  # noqa: S104
        port=8000,  # noqa: WPS432
        reload=True,
        forwarded_allow_ips='*',
    )
