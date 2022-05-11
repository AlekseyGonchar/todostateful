from typing import List, Mapping

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from src.cruds import user as user_crud
from src.db import get_db
from src.libs import authenticate
from src.schema import task as task_schema
from src.schema import user as user_schema

router = APIRouter(prefix="", tags=["user"])


@router.post("/user", response_model=user_schema.Token)
async def register_user(
    form_data: user_schema.UserCreate = Depends(),
    db: AsyncSession = Depends(get_db),
) -> Mapping[str, str]:
    form_data.password = authenticate.get_hashed_password(form_data.password)
    user = await user_crud.create_user(db, form_data)
    access_token = authenticate.create_access_token(user.username)
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/token", response_model=user_schema.Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    user = await authenticate.authenticate_user(
        db, form_data.username, form_data.password
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = authenticate.create_access_token(user.username)
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/users/me", response_model=user_schema.User)
async def read_users_me(
    current_user: user_schema.User = Depends(
        authenticate.get_current_active_user
    ),
):
    return current_user
