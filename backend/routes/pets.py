import uuid
from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import date, datetime
import models
from database import get_db
from security import get_current_user
from pydantic import BaseModel
from websocket_manager import manager

router = APIRouter(
    prefix="/api/pets",
    tags=["Pet Matching"]
)

class PetCreate(BaseModel):
    owner_id: str
    name: str
    species: str
    breed: Optional[str] = None
    age: Optional[float] = None
    weight: Optional[float] = None
    photo_url: Optional[str] = None

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

    # exclude own pets and already swiped pets
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
        owner_name = owner.username if owner else ""
        owner_age = calculate_age(getattr(owner, 'date_of_birth', None)) if (owner and owner.date_of_birth) else None
        owner_img = (owner.photo_url if owner else "") or ""
        owner_bio = (owner.bio if (owner and owner.bio) else "") or ""

        result.append({
            "id": pet.id,
            "name": pet.name,
            "species": pet.species,
            "breed": pet.breed or "",
            "age": pet.age,
            "weight": pet.weight,
            "location": pet.location or "",
            "description": pet.description or "",
            "petImage": pet.photo_url or "",
            "owner": {
                "id": owner.id if owner else "",
                "name": owner_name,
                "age": owner_age,
                "ownerImage": owner_img,
                "bio": owner_bio
            }
        })

    return result

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
        photo_url=pet_data.photo_url or ""
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

class SwipeCreate(BaseModel):
    is_like: bool

@router.post("/{pet_id}/swipe/")
def swipe_pet(
    pet_id: str,
    swipe_data: SwipeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    target_pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    if not target_pet:
        raise HTTPException(status_code=404, detail="Pet not found!")

    # cannot swipe own pet
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

    # check match if user liked
    is_match = False
    if swipe_data.is_like:
        my_pets_ids = [pet.id for pet in current_user.pets]
        
        # check mutual like
        if my_pets_ids:
            mutual_like = db.query(models.PetSwipe).filter(
                models.PetSwipe.swiper_id == target_pet.owner_id,
                models.PetSwipe.target_pet_id.in_(my_pets_ids),
                models.PetSwipe.is_like == True
            ).first()

            if mutual_like:
                is_match = True
        else:
        
            other_swipe = db.query(models.PetSwipe).filter(
                models.PetSwipe.swiper_id == target_pet.owner_id,
                models.PetSwipe.is_like == True
            ).first()
            if other_swipe:
                is_match = True

        if is_match:
            target_owner = db.query(models.User).filter(models.User.id == target_pet.owner_id).first()
            target_username = target_owner.username if target_owner else target_pet.owner_id
            print(f"mutual like detected between {current_user.username} and {target_username}")

            # notifications
            db.add(models.Notification(
                user_id=target_pet.owner_id,
                title="It's a Match!",
                message=f"Hey! Someone liked your pet, {target_pet.name}! You have a new match!"
            ))
            db.add(models.Notification(
                user_id=current_user.id,
                title="It's a Match!",
                message=f"Congratulations! {target_pet.name} and their owner are a match!"
            ))

            existing_match = db.query(models.PetMatch).filter(
                (
                    (models.PetMatch.user1_id == current_user.id) &
                    (models.PetMatch.user2_id == target_pet.owner_id)
                ) | (
                    (models.PetMatch.user1_id == target_pet.owner_id) &
                    (models.PetMatch.user2_id == current_user.id)
                )
            ).first()

            if not existing_match:
                my_pets_ids_list = [p.id for p in current_user.pets]
                my_pet_in_match = my_pets_ids_list[0] if my_pets_ids_list else None

                new_match = models.PetMatch(
                    user1_id=current_user.id,
                    user2_id=target_pet.owner_id,
                    pet1_id=my_pet_in_match,
                    pet2_id=target_pet.id
                )
                db.add(new_match)

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




class SendMatchMessageRequest(BaseModel):
    content: str


@router.get("/matches/")
def get_my_matches(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Return all confirmed matches for the current user with other user info."""
    matches = db.query(models.PetMatch).filter(
        (models.PetMatch.user1_id == current_user.id) |
        (models.PetMatch.user2_id == current_user.id)
    ).order_by(models.PetMatch.created_at.desc()).all()

    result = []
    for m in matches:
        other_user = m.user2 if m.user1_id == current_user.id else m.user1
        their_pet  = m.pet2  if m.user1_id == current_user.id else m.pet1
        my_pet     = m.pet1  if m.user1_id == current_user.id else m.pet2

        # last message preview
        last_msg = db.query(models.MatchMessage).filter(
            models.MatchMessage.match_id == m.id
        ).order_by(models.MatchMessage.sent_at.desc()).first()

        result.append({
            "match_id": m.id,
            "created_at": m.created_at.isoformat() if m.created_at else None,
            "other_user": {
                "id": other_user.id if other_user else "",
                "username": other_user.username if other_user else "",
                "photo_url": other_user.photo_url if other_user else "",
                "bio": other_user.bio if other_user else "",
            },
            "their_pet": {
                "id": their_pet.id if their_pet else "",
                "name": their_pet.name if their_pet else "",
                "photo_url": their_pet.photo_url if their_pet else "",
                "breed": their_pet.breed if their_pet else "",
            },
            "my_pet": {
                "id": my_pet.id if my_pet else "",
                "name": my_pet.name if my_pet else "",
            },
            "last_message": {
                "content": last_msg.content if last_msg else None,
                "sent_at": last_msg.sent_at.isoformat() if (last_msg and last_msg.sent_at) else None,
                "is_mine": last_msg.sender_id == current_user.id if last_msg else None,
            }
        })

    return result


@router.get("/matches/{match_id}/messages/")
def get_match_messages(
    match_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Return all messages for a specific match conversation."""
    match = db.query(models.PetMatch).filter(models.PetMatch.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found.")

    
    if match.user1_id != current_user.id and match.user2_id != current_user.id:
        raise HTTPException(status_code=403, detail="You are not part of this match.")

    messages = db.query(models.MatchMessage).filter(
        models.MatchMessage.match_id == match_id
    ).order_by(models.MatchMessage.sent_at.asc()).all()

    return [
        {
            "id": msg.id,
            "sender_id": msg.sender_id,
            "sender_username": msg.sender.username if msg.sender else "",
            "content": msg.content,
            "sent_at": msg.sent_at.isoformat() if msg.sent_at else None,
            "is_mine": msg.sender_id == current_user.id,
        }
        for msg in messages
    ]


@router.post("/matches/{match_id}/messages/", status_code=201)
async def send_match_message(
    match_id: str,
    payload: SendMatchMessageRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Send a message in a match chat."""
    match = db.query(models.PetMatch).filter(models.PetMatch.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found.")

    if match.user1_id != current_user.id and match.user2_id != current_user.id:
        raise HTTPException(status_code=403, detail="You are not part of this match.")

    if not payload.content.strip():
        raise HTTPException(status_code=400, detail="Message content cannot be empty.")

    new_msg = models.MatchMessage(
        match_id=match_id,
        sender_id=current_user.id,
        content=payload.content.strip()
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    
    recipient_id = match.user2_id if match.user1_id == current_user.id else match.user1_id
    message_payload = {
        "event": "NEW_MATCH_MESSAGE",
        "match_id": match_id,
        "message_id": new_msg.id,
        "sender_id": current_user.id,
        "sender_username": current_user.username,
        "content": new_msg.content,
        "sent_at": new_msg.sent_at.isoformat() if new_msg.sent_at else None,
    }
    await manager.send_personal_message(message_payload, recipient_id)

    print(f"message sent by {current_user.username} in match {match_id}")

    return {
        "id": new_msg.id,
        "match_id": match_id,
        "sender_id": current_user.id,
        "sender_username": current_user.username,
        "content": new_msg.content,
        "sent_at": new_msg.sent_at.isoformat() if new_msg.sent_at else None,
        "is_mine": True,
    }