from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routes import auth, admin, consultations, users, pets

from fastapi.staticfiles import StaticFiles
import os

os.makedirs("uploads", exist_ok=True)

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Pet App API",
    description="Backed for Pawnder",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(consultations.router)
app.include_router(users.router)
app.include_router(pets.router)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def root():
    return {"message": "API is opened"}
