from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

import models
from database import get_db
from s3_utils import upload_file_to_s3
from security import get_current_user

router = APIRouter(
    prefix="/api/map",
    tags=["Map and Locations"]
)

# POST /api/map/report-missing/

@router.post("/report-missing/")
async def report_missing_pet(
    user_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    description: str = Form(...),
    missing_date: datetime = Form(...),
    file: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    photo_link = None
    if file:
        photo_link = upload_file_to_s3(file, folder="missing_pets")

    new_location = models.Location(
        title=f"Missing Pet - Reported by {user.username}",
        description=description,
        type=models.LocationType.MISSING_PET,
        latitude=latitude,
        longitude=longitude
    )
    db.add(new_location)
    db.flush() 

    new_post = models.MissingPetPost(
        user_id=user.id,
        location_id=new_location.id,
        description=description,
        missing_date=missing_date,
        photo_url=photo_link,
        status="MISSING"
    )
    db.add(new_post)
    db.commit()

    return {"message": "Pet reported successfully!", "location_id": new_location.id}

# GET /api/map/locations/

@router.get("/locations/")
async def get_locations_in_area(
    min_lat: float, max_lat: float, min_lon: float, max_lon: float,
    location_type: Optional[models.LocationType] = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.Location).filter(
        models.Location.latitude >= min_lat,
        models.Location.latitude <= max_lat,
        models.Location.longitude >= min_lon,
        models.Location.longitude <= max_lon
    )
    if location_type:
        query = query.filter(models.Location.type == location_type)
        
    locations = query.all()
    
    result = []
    for loc in locations:
        loc_data = {
            "id": loc.id, 
            "title": loc.title, 
            "type": loc.type, 
            "latitude": loc.latitude, 
            "longitude": loc.longitude,
            "description": loc.description
        }
        
        if loc.type == models.LocationType.PET_FRIENDLY:
            event = db.query(models.Event).filter(models.Event.id_location == loc.id).first()
            if event:
                loc_data["start_date"] = event.date_hour
                loc_data["end_time"] = event.end_date_hour
                
        result.append(loc_data)
        
    return result


# GET /api/map/locations/{location_id}/details

@router.get("/locations/{location_id}/details")
async def get_location_details(location_id: str, db: Session = Depends(get_db)):
    location = db.query(models.Location).filter(models.Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found.")

    details = {
        "id": location.id, "title": location.title, "description": location.description,
        "type": location.type, "latitude": location.latitude, "longitude": location.longitude
    }

    if location.type == models.LocationType.MISSING_PET:
        missing_post = db.query(models.MissingPetPost).filter(models.MissingPetPost.location_id == location.id).first()
        if missing_post:
            user = db.query(models.User).filter(models.User.id == missing_post.user_id).first()
            details["missing_pet_info"] = {
                "missing_date": missing_post.missing_date, "status": missing_post.status,
                "photo_url": missing_post.photo_url, "posted_by": user.username if user else "Anonymous"
            }
    return details

class ClinicCreate(BaseModel):
    name: str
    details: str
    latitude: float
    longitude: float

class ReviewCreate(BaseModel):
    rating: int
    text: str

class EventCreate(BaseModel):
    name: str
    details: str
    latitude: float
    longitude: float
    start_date: datetime
    end_time: datetime

class GemCreate(BaseModel):
    name: str
    latitude: float
    longitude: float


# endpoints pentru creare locatii

@router.post("/add-clinic/")
def add_clinic(
    data: ClinicCreate, 
    db: Session = Depends(get_db), 
   # user: models.User = Depends(get_current_user)
):
    new_clinic_location = models.Location(
        title=data.name,
        description=data.details,
        type=models.LocationType.VET_CLINIC,
        latitude=data.latitude,
        longitude=data.longitude
    )
    db.add(new_clinic_location)
    db.commit()
    return {"message": "Clinic added successfully!", "id": new_clinic_location.id}


@router.post("/clinic/{location_id}/add-review/")
def add_review(
    location_id: str, 
    data: ReviewCreate, 
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    new_review = models.Review(
        location_id=location_id,
        nota=data.rating,
        text=data.text
    )
    db.add(new_review)
    db.commit()
    return {"message": "Review saved successfully!"}

# hidden gems

@router.post("/add-gem/")
def add_gem(
    data: GemCreate, 
    db: Session = Depends(get_db)
):
    new_location = models.Location(
        title=data.name,
        type=models.LocationType.HIDDEN_GEM,
        latitude=data.latitude,
        longitude=data.longitude
    )
    db.add(new_location)
    db.flush()

    new_gem = models.HiddenGem(
        location_id=new_location.id,
        is_exclusive_premium=False 
    )
    db.add(new_gem)
    db.commit()
    return {"message": "Hidden gem successfully placed!", "gem_id": new_gem.id}

@router.post("/gem/{location_id}/claim/")
def claim_hidden_gem(
    location_id: str, 
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    location = db.query(models.Location).filter(
        models.Location.id == location_id,
        models.Location.type == models.LocationType.HIDDEN_GEM
    ).first()

    if not location:
        raise HTTPException(status_code=404, detail="Hidden gem not found or already claimed!")

    db.delete(location)
    db.commit()

    return {
        "message": "Prize collected successfully! The gem has been removed from the map.",
        "claimed_by": user.username
    }