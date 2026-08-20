from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base, SessionLocal
from routers import pets, auth
import models

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Pawnder API",
    description="Backend for Pawnder pet matching and community app",
    version="1.0.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(pets.router)

@app.get("/")
def root():
    return {
        "status": "online",
        "message": "Pawnder API is running! 🐾",
        "docs": "/docs"
    }

@app.on_event("startup")
def startup_seed():
    db = SessionLocal()
    try:
        from seed_data import seed_database
        seed_database(db)
    except Exception as e:
        print(f"Seed note: {e}")
    finally:
        db.close()
