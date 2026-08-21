from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import shutil, os, uuid

import models
from database import get_db

router = APIRouter(
    prefix="/api/users",
    tags=["Users & Profile"]
)

class UserProfileUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    bio: Optional[str] = None
    date_of_birth: Optional[str] = None
    photo_url: Optional[str] = None

@router.post("/upload-photo")
async def upload_photo(file: UploadFile = File(...)):
    os.makedirs("uploads", exist_ok=True)
    extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{extension}"
    file_path = os.path.join("uploads", unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"http://localhost:8000/uploads/{unique_filename}"}

@router.get("/{user_id}")
def get_user_profile(user_id: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu a fost găsit.")
    
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "bio": user.bio or "Pet lover, Pawnder member.",
        "rol": user.rol.value if hasattr(user.rol, 'value') else user.rol,
        "is_premium": user.is_premium,
        "photo_url": user.photo_url,
        "date_of_birth": user.date_of_birth.strftime("%d/%m/%Y") if user.date_of_birth else "",
    }

@router.put("/{user_id}")
def update_user_profile(user_id: str, payload: UserProfileUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu a fost găsit.")

    if payload.username is not None:
        user.username = payload.username
    if payload.email is not None:
        user.email = payload.email
    if payload.bio is not None:
        user.bio = payload.bio
    if payload.photo_url is not None:
        user.photo_url = payload.photo_url
    if payload.date_of_birth:
        try:
            user.date_of_birth = datetime.strptime(payload.date_of_birth, "%d/%m/%Y")
        except ValueError:
            pass

    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "bio": user.bio or "",
        "photo_url": user.photo_url,
        "date_of_birth": user.date_of_birth.strftime("%d/%m/%Y") if user.date_of_birth else "",
    }