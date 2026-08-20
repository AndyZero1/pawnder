from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
import uuid

import models
from database import get_db

router = APIRouter(prefix="/api/pets", tags=["Pets"])

class PetCreate(BaseModel):
    owner_id: str
    name: str
    species: str
    breed: Optional[str] = None
    age: Optional[float] = None
    weight: Optional[float] = None
    photo_url: Optional[str] = None

@router.get("/{owner_id}")
def get_user_pets(owner_id: str, db: Session = Depends(get_db)):
    return db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_pet(pet_data: PetCreate, db: Session = Depends(get_db)):
    new_pet = models.Pet(
        id=str(uuid.uuid4()),
        owner_id=pet_data.owner_id,
        name=pet_data.name,
        species=pet_data.species,
        breed=pet_data.breed,
        age=pet_data.age,
        weight=pet_data.weight,
        photo_url=pet_data.photo_url or "https://images.unsplash.com/photo-1543852786-1cf6624b9987?auto=format&fit=crop&w=500&q=80"
    )
    db.add(new_pet)
    db.commit()
    db.refresh(new_pet)
    return new_pet

@router.delete("/{pet_id}")
def delete_pet(pet_id: str, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    db.delete(pet)
    db.commit()
    return {"message": "Pet deleted successfully"}