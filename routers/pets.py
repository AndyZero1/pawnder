from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import date, datetime
import models
from database import get_db
from security import get_current_user
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/pets",
    tags=["Pet Matching"]
)

def calculate_age(born) -> int:
    if not born:
        return 0
    if hasattr(born, 'date'):
        born = born.date()
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

    # Exclude own pets and already swiped pets
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
        owner_name = owner.username if owner else "Pet Lover"
        owner_age = calculate_age(owner.birth_date if owner else None) or 25
        owner_img = (owner.photo_url if owner else None) or "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80"
        owner_bio = getattr(owner, 'bio', None) or "Passionate about dogs, outdoor walks, and friendly pets!"

        result.append({
            "id": pet.id,
            "name": pet.name,
            "breed": pet.breed if pet.breed else "Playful Friend",
            "age": pet.age if pet.age is not None else 2,
            "location": "Bucharest", 
            "description": getattr(pet, 'description', None) or f"{pet.name} is super friendly and looking for active playmates!",
            "petImage": pet.photo_url or "https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=900&q=80",
            "owner": {
                "id": owner.id if owner else "",
                "name": owner_name,
                "age": owner_age,
                "ownerImage": owner_img,
                "bio": owner_bio
            }
        })

    return result

class SwipeCreate(BaseModel):
    is_like: bool

@router.post("/{pet_id}/swipe/")
def swipe_pet(
    pet_id: str,
    swipe_data: SwipeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Validate target pet existence
    target_pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    if not target_pet:
        raise HTTPException(status_code=404, detail="Pet not found!")

    # Cannot swipe own pet
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

    # Check match if user liked
    is_match = False
    if swipe_data.is_like:
        my_pets_ids = [pet.id for pet in current_user.pets]
        
        # Check mutual like
        if my_pets_ids:
            mutual_like = db.query(models.PetSwipe).filter(
                models.PetSwipe.swiper_id == target_pet.owner_id,
                models.PetSwipe.target_pet_id.in_(my_pets_ids),
                models.PetSwipe.is_like == True
            ).first()

            if mutual_like:
                is_match = True
        else:
            # If current user hasn't registered a pet yet, check if other owner swiped on current user or auto-match for demo
            other_swipe = db.query(models.PetSwipe).filter(
                models.PetSwipe.swiper_id == target_pet.owner_id,
                models.PetSwipe.is_like == True
            ).first()
            if other_swipe:
                is_match = True

        if is_match:
            # Notification for target owner
            notif_target = models.Notification(
                user_id=target_pet.owner_id,
                title="It's a Match! 🐾",
                message=f"Hey! Someone liked your pet, {target_pet.name}! You have a new match!"
            )
            
            # Notification for current user
            notif_current = models.Notification(
                user_id=current_user.id,
                title="It's a Match! 🐾",
                message=f"Congratulations! {target_pet.name} and their owner are a match!"
            )
            
            db.add(notif_target)
            db.add(notif_current)
            db.commit()

    return {
        "message": "Swipe recorded successfully!",
        "is_match": is_match
    }

@router.post("/reset-swipes/")
def reset_swipes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Allows testing/resetting swiped pets for current user."""
    db.query(models.PetSwipe).filter(models.PetSwipe.swiper_id == current_user.id).delete()
    db.commit()
    return {"message": "Swipes reset successfully! You can swipe on all pets again."}

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
            "created_at": n.created_at.isoformat() if n.created_at else None
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