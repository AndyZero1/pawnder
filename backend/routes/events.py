from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

import models
from database import get_db
from security import get_current_user

router = APIRouter(
    prefix="/api/events",
    tags=["Group Events"]
)

class EventBase(BaseModel):
    name: str
    details: str
    latitude: float
    longitude: float
    start_date: datetime
    end_time: datetime

class EventUpdate(BaseModel):
    name: Optional[str] = None
    details: Optional[str] = None
    start_date: Optional[datetime] = None
    end_time: Optional[datetime] = None

# creare de eveniment
@router.post("/create/")
def create_event(
    data: EventBase, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    new_location = models.Location(
        title=data.name,
        description=data.details,
        type=models.LocationType.PET_FRIENDLY,
        latitude=data.latitude,
        longitude=data.longitude,
    )
    db.add(new_location)
    db.flush() 

    new_event = models.Event(
        id_organizer=current_user.id,
        id_location=new_location.id,
        title=data.name,
        description=data.details,
        date_hour=data.start_date,
        end_date_hour=data.end_time
    )
    db.add(new_event)
    db.flush()

    # Organizatorul devine automat participant
    first_attendee = models.EventAttendee(event_id=new_event.id, user_id=current_user.id)
    db.add(first_attendee)

    db.commit()
    return {"message": "Event created successfully!", "event_id": new_event.id}

# vizibilitate la locatii din apropiere
@router.get("/nearby/")
def get_nearby_events(
    min_lat: float, max_lat: float, min_lon: float, max_lon: float,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    events = db.query(models.Event).join(models.Location).filter(
        models.Location.latitude >= min_lat,
        models.Location.latitude <= max_lat,
        models.Location.longitude >= min_lon,
        models.Location.longitude <= max_lon
    ).all()

    result = []
    for ev in events:
        organizer = ev.organizer
        loc = ev.location

        attendees_count = db.query(models.EventAttendee).join(models.User).filter(
            models.EventAttendee.event_id == ev.id,
            models.User.username != "admin.pawnder"
        ).count()
        
        is_participating = db.query(models.EventAttendee).filter(
            models.EventAttendee.event_id == ev.id,
            models.EventAttendee.user_id == current_user.id
        ).first() is not None

        result.append({
            "event_id": ev.id,
            "title": ev.title,
            "description": ev.description,
            "location_name": loc.title,
            "start_date": ev.date_hour.isoformat() if ev.date_hour else None,
            "end_time": ev.end_date_hour.isoformat() if ev.end_date_hour else None,
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "organizer": {"id": organizer.id, "name": organizer.username},
            "attendees_count": attendees_count,
            "is_participating": is_participating,
            "is_organizer": organizer.id == current_user.id
        })

    return result

# actualizare eveniment
@router.put("/{event_id}/update/")
def update_event(
    event_id: str,
    data: EventUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found.")
    
    if event.id_organizer != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own events.")

    if data.name:
        event.title = data.name
        event.location.title = data.name
    if data.details:
        event.description = data.details
        event.location.description = data.details
    if data.start_date:
        event.date_hour = data.start_date
    if data.end_time:
        event.end_date_hour = data.end_time

    db.commit()
    return {"message": "Event updated successfully!"}

# optiunea de stergere eveniment (daca esti organizator)
@router.delete("/{event_id}/delete/")
def delete_event(
    event_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found.")
    
    if event.id_organizer != current_user.id and current_user.rol != "ADMIN":
        raise HTTPException(status_code=403, detail="Not authorized to delete this event.")

    location = event.location

    db.query(models.EventAttendee).filter(models.EventAttendee.event_id == event_id).delete()
    db.query(models.EventMessage).filter(models.EventMessage.event_id == event_id).delete()

    db.delete(event)
    if location:
        db.delete(location)
        
    db.commit()
    return {"message": "Event deleted successfully."}

# optiunea de join
@router.post("/{event_id}/join/")
def join_event(
    event_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found.")

    existing_attendee = db.query(models.EventAttendee).filter(
        models.EventAttendee.event_id == event_id,
        models.EventAttendee.user_id == current_user.id
    ).first()

    if existing_attendee:
        raise HTTPException(status_code=400, detail="You are already participating in this event.")

    new_attendee = models.EventAttendee(event_id=event_id, user_id=current_user.id)
    db.add(new_attendee)
    db.commit()
    return {"message": "Successfully joined the event!"}

# optiunea de leave
@router.delete("/{event_id}/leave/")
def leave_event(
    event_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    attendee = db.query(models.EventAttendee).filter(
        models.EventAttendee.event_id == event_id,
        models.EventAttendee.user_id == current_user.id
    ).first()

    if not attendee:
        raise HTTPException(status_code=400, detail="You are not participating in this event.")

    db.delete(attendee)
    db.commit()
    return {"message": "You left the event."}

class ChatCreate(BaseModel):
    message: str


@router.get("/{event_id}/members/")
def get_event_members(
    event_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    attendees = db.query(models.EventAttendee).filter(models.EventAttendee.event_id == event_id).all()
    
    result = []
    for att in attendees:
        user = att.user

        if user.username == "admin.pawnder" or user.rol == "ADMIN":
            continue
            
        pet_name = user.pets[0].name if user.pets else "No pet"
        
        result.append({
            "user_name": user.username,
            "pet_details": pet_name,
            "is_me": user.id == current_user.id
        })
    return result

# partea de conv
@router.get("/{event_id}/chat/")
def get_event_chat(
    event_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    messages = db.query(models.EventMessage).filter(
        models.EventMessage.event_id == event_id
    ).order_by(models.EventMessage.timestamp.asc()).all()
    
    return [
        {
            "user_name": msg.user.username,
            "message": msg.message,
            "timestamp": msg.timestamp.strftime("%H:%M"),
            "is_me": msg.user_id == current_user.id
        }
        for msg in messages
    ]

@router.post("/{event_id}/chat/")
def post_event_chat(
    event_id: str, 
    data: ChatCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    new_msg = models.EventMessage(
        event_id=event_id,
        user_id=current_user.id,
        message=data.message
    )
    db.add(new_msg)
    db.commit()
    
    return {"message": "Message sent!"}