import os
import jwt
import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from database import get_db
import models

router = APIRouter(
    prefix="/api/auth",
    tags=["Autentificare"]
)

JWT_SECRET = os.getenv("JWT_SECRET", "secret_fallback")
ALGORITHM = "HS256"

# request validation
class UserRegister(BaseModel):
    username: Optional[str] = None
    email: EmailStr
    password: str
    rol: Optional[models.Role] = models.Role.OWNER
    cabinet_name: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

def hash_password(password: str) -> str:
    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    hashed_pwd = bcrypt.hashpw(pwd_bytes, salt)
    return hashed_pwd.decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8"), hashed_password.encode("utf-8")
    )

def create_jwt_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(hours=24)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)

### POST /api/auth/register
@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="An account with this email already exists. :(")

    hashed_pass = hash_password(user_data.password)

    new_user = models.User(
        username=user_data.username,
        email=user_data.email,
        hash_pass=hashed_pass,
        rol=user_data.rol
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if user_data.rol == models.Role.VETERINARY:
        vet_profile = models.VeterinaryProfile(user_id=new_user.id, cabinet_name=user_data.cabinet_name)
        db.add(vet_profile)
        db.commit()

    return {
        "message": "User successfully registered!",
        "user_id": new_user.id,
        "email": new_user.email,
        "rol": new_user.rol
    }

### POST /api/auth/login
@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == credentials.email).first()

    if not user or not verify_password(credentials.password, user.hash_pass):
        raise HTTPException(status_code=401, detail="Email sau parola incorecta!")

    token = create_jwt_token({
        "userId": user.id,
        "email": user.email,
        "rol": user.rol.value
    })

    return {
        "message": "Autentificare reusita!",
        "token": token,
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "rol": user.rol,
            "is_premium": user.is_premium
        }
    } 