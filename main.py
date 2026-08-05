from fastapi import FastAPI
from database import engine, Base
from routes import auth

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Pet App API",
    description="Backed for Pawnder",
    version="1.0.0"
)

app.include_router(auth.router)

@app.get("/")
def root():
    return {"message": "API is opened"}
