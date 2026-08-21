from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import date

from database import engine, get_db, SessionLocal
import models

from s3_utils import upload_file_to_s3
from routes import auth, admin, consultations, map, events, pets
from security import get_current_admin, get_current_user

from fastapi.staticfiles import StaticFiles
import os

os.makedirs("uploads", exist_ok=True)

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Pawnder API",
    description="Backend for Pawnder",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(map.router)
app.include_router(events.router)
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(consultations.router)
app.include_router(pets.router)

@app.get("/")
def root():
    return {
        "status": "online",
        "message": "Pawnder API is running! 🐾",
        "docs": "/docs"
    }

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
