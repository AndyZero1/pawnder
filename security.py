import os
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
import models

JWT_SECRET = os.getenv("JWT_SECRET", "pawnder_super_secret_jwt_key_2026")
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_id = payload.get("userId")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Token invalid: Lipseste ID-ul.")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Sesiunea a expirat.")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Token invalid.")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="Userul nu mai exista.")
    return user

def get_current_admin(current_user: models.User = Depends(get_current_user)):
    if hasattr(current_user.rol, 'value') and current_user.rol.value != "ADMIN":
        raise HTTPException(status_code=403, detail="Acces interzis! Trebuie să fii Administrator.")
    return current_user
