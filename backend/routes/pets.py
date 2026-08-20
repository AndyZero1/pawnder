import uuid
from datetime import date
from typing import Optional, List

from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

import models
from database import get_db
from security import get_current_user

router = APIRouter(
    prefix="/api/pets",
    tags=["Pets & Matching"]
)

class PetCreate(BaseModel):
    owner_id: str
    name: str
    species: str
    breed: Optional[str] = None
    age: Optional[float] = None
    weight: Optional[float] = None
    photo_url: Optional[str] = None

class SwipeCreate(BaseModel):
    is_like: bool


def calculate_age(born: date) -> int:
    if not born:
        return 0
    today = date.today()
    return today.year - born.year - ((today.month, today.day) < (born.month, born.day))


@router.get("/matching/")
def get_pet_matches(
    species: Optional[str] = Query(None, description="Filter by species (e.g., Dog, Cat)"),
    min_age: Optional[float] = Query(None, description="Minimum age of the pet"),
    max_age: Optional[float] = Query(None, description="Maximum age of the pet"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    swiped_pets_subquery = db.query(models.PetSwipe.target_pet_id).filter(
        models.PetSwipe.swiper_id == current_user.id
    )

    # excludere animale pe care le am vazut deja
    query = db.query(models.Pet).filter(
        models.Pet.owner_id != current_user.id,
        models.Pet.id.notin_(swiped_pets_subquery)
    )

    if species:
        query = query.filter(models.Pet.species.ilike(f"%{species}%"))
    
    if min_age is not None:
        query = query.filter(models.Pet.age >= min_age)
        
    if max_age is not None:
        query = query.filter(models.Pet.age <= max_age)

    matched_pets = query.all()

    result = []
    for pet in matched_pets:
        owner = pet.owner
        result.append({
            "id": pet.id,
            "name": pet.name,
            "breed": pet.breed if pet.breed else "Unknown mix",
            "age": pet.age,
            "location": "Bucharest", 
            "description": getattr(pet, 'description', f"{pet.name} is looking for playmates!"),
            "petImage": pet.photo_url or "https://via.placeholder.com/900",
            "owner": {
                "id": owner.id,
                "name": owner.username,
                "age": calculate_age(owner.date_of_birth),
                "ownerImage": owner.photo_url or "https://via.placeholder.com/400",
                "bio": getattr(owner, 'bio', "Animal lover.")
            }
        })

    return result


@router.get("/notifications/")
def get_my_notifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    notifications = db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id
    ).order_by(models.Notification.created_at.desc()).all()
    
    return [
        {
            "id": n.id,
            "title": n.title,
            "message": n.message,
            "is_read": n.is_read,
            "created_at": n.created_at
        } for n in notifications
    ]


@router.post("/notifications/{notif_id}/read/")
def mark_notification_as_read(
    notif_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    notif = db.query(models.Notification).filter(
        models.Notification.id == notif_id,
        models.Notification.user_id == current_user.id
    ).first()
    
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found.")
        
    notif.is_read = True
    db.commit()
    
    return {"message": "Notification marked as read."}


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


@router.post("/{pet_id}/swipe/")
def swipe_pet(
    pet_id: str,
    swipe_data: SwipeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # validare existenta pet
    target_pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    if not target_pet:
        raise HTTPException(status_code=404, detail="Pet not found!")

    if target_pet.owner_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot swipe on your own pet.")

    existing_swipe = db.query(models.PetSwipe).filter(
        models.PetSwipe.swiper_id == current_user.id,
        models.PetSwipe.target_pet_id == target_pet.id
    ).first()

    if existing_swipe:
        existing_swipe.is_like = swipe_data.is_like
        db.commit()
    else:
        new_swipe = models.PetSwipe(
            swiper_id=current_user.id,
            target_pet_id=target_pet.id,
            is_like=swipe_data.is_like
        )
        db.add(new_swipe)
        db.commit()

    # 3. match daca user ul curent a dat like
    is_match = False
    if swipe_data.is_like:
        my_pets_ids = [pet.id for pet in current_user.pets]
        
        if my_pets_ids:
            mutual_like = db.query(models.PetSwipe).filter(
                models.PetSwipe.swiper_id == target_pet.owner_id,
                models.PetSwipe.target_pet_id.in_(my_pets_ids),
                models.PetSwipe.is_like == True
            ).first()

            if mutual_like:
                is_match = True
                      
                # notif pentru celalalt user
                notif_target = models.Notification(
                    user_id=target_pet.owner_id,
                    title="It's a Match!",
                    message=f"Hey! Someone just liked your pet, {target_pet.name}! You have a new match!"
                )
                
                # notif pentru user ul curent
                notif_current = models.Notification(
                    user_id=current_user.id,
                    title="It's a Match!",
                    message=f"Congratulations! {target_pet.name} likes you back!"
                )
                
                db.add(notif_target)
                db.add(notif_current)
                db.commit()

    return {
        "message": "Swipe recorded successfully!",
        "is_match": is_match
    }


@router.get("/{owner_id}")
def get_user_pets(owner_id: str, db: Session = Depends(get_db)):
    return db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()


@router.delete("/{pet_id}")
def delete_pet(pet_id: str, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    db.delete(pet)
    db.commit()
    return {"message": "Pet deleted successfully"}