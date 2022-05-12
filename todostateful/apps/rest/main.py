import logging
from typing import Any, Mapping

import orjson
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from todostateful.shared import orjson_options


class ORJSONResponse(JSONResponse):
    def render(self, content_to_render: Any) -> bytes:  # type: ignore[misc]
        return orjson.dumps(
            content_to_render,
            option=orjson_options,
        )


def init_logger() -> None:
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("app")
    logger.setLevel(logging.INFO)


app = FastAPI(default_response_class=ORJSONResponse)
app.add_middleware(
    CORSMiddleware,
    allow_origins="*",
    allow_methods="*",
)


@app.get("/health")
async def health() -> Mapping[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(
        "__main__:app",
        host="0.0.0.0",  # noqa: S104
        port=8000,  # noqa: WPS432
        reload=True,
        forwarded_allow_ips="*",
    )
