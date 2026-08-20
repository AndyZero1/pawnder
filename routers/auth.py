import os
import jwt
import bcrypt
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from database import get_db
import models

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)

JWT_SECRET = os.getenv("JWT_SECRET", "pawnder_super_secret_jwt_key_2026")
ALGORITHM = "HS256"

class UserRegister(BaseModel):
    username: Optional[str] = None
    email: EmailStr
    password: str
    rol: Optional[models.Role] = models.Role.OWNER
    cabinet_name: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

def hash_password(password: str) -> str:
    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    hashed_pwd = bcrypt.hashpw(pwd_bytes, salt)
    return hashed_pwd.decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"), hashed_password.encode("utf-8")
        )
    except Exception:
        return False

def create_jwt_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="An account with this email already exists.")

    computed_username = user_data.username or user_data.email.split("@")[0]
    hashed_pass = hash_password(user_data.password)

    new_user = models.User(
        id=str(uuid.uuid4()),
        username=computed_username,
        email=user_data.email,
        hash_pass=hashed_pass,
        rol=user_data.rol or models.Role.OWNER
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if user_data.rol == models.Role.VETERINARY:
        vet_profile = models.VeterinaryProfile(user_id=new_user.id, cabinet_name=user_data.cabinet_name)
        db.add(vet_profile)
        db.commit()

    token = create_jwt_token({
        "userId": new_user.id,
        "email": new_user.email,
        "rol": new_user.rol.value if hasattr(new_user.rol, 'value') else str(new_user.rol)
    })

    return {
        "message": "User successfully registered!",
        "token": token,
        "user_id": new_user.id,
        "email": new_user.email,
        "username": new_user.username,
        "rol": new_user.rol.value if hasattr(new_user.rol, 'value') else str(new_user.rol)
    }

@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        (models.User.email == credentials.email) | (models.User.username == credentials.email)
    ).first()

    if not user or not verify_password(credentials.password, user.hash_pass):
        raise HTTPException(status_code=401, detail="Email sau parola incorecta!")

    token = create_jwt_token({
        "userId": user.id,
        "email": user.email,
        "rol": user.rol.value if hasattr(user.rol, 'value') else str(user.rol)
    })

    return {
        "message": "Autentificare reusita!",
        "token": token,
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "rol": user.rol.value if hasattr(user.rol, 'value') else str(user.rol),
            "is_premium": user.is_premium
        }
    }

@router.get("/me")
def get_me(db: Session = Depends(get_db)):
    # Helper to check me
    return {"status": "ok"}

