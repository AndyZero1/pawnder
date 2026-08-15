from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime

import models
from database import get_db
from s3_utils import upload_file_to_s3

router = APIRouter(
    prefix="/api/map",
    tags=["Harta si Locatii"]
)

# 1. Raportare animal pierdut (POST /api/map/report-missing/)
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
        raise HTTPException(status_code=404, detail="Userul nu există.")

    photo_link = None
    if file:
        photo_link = upload_file_to_s3(file, folder="missing_pets")

    new_location = models.Location(
        title=f"Animal pierdut - Raportat de {user.username}",
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

    return {"message": "Raportat cu succes!", "location_id": new_location.id}

# 2. GET /api/map/locations/
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
    return [{"id": loc.id, "title": loc.title, "type": loc.type, "latitude": loc.latitude, "longitude": loc.longitude} for loc in locations]

# 3. GET /api/map/locations/{location_id}/details
@router.get("/locations/{location_id}/details")
async def get_location_details(location_id: str, db: Session = Depends(get_db)):
    location = db.query(models.Location).filter(models.Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Locația nu a fost găsită.")

    detalii = {
        "id": location.id, "title": location.title, "description": location.description,
        "type": location.type, "latitude": location.latitude, "longitude": location.longitude
    }

    if location.type == models.LocationType.MISSING_PET:
        missing_post = db.query(models.MissingPetPost).filter(models.MissingPetPost.location_id == location.id).first()
        if missing_post:
            user = db.query(models.User).filter(models.User.id == missing_post.user_id).first()
            detalii["missing_pet_info"] = {
                "missing_date": missing_post.missing_date, "status": missing_post.status,
                "photo_url": missing_post.photo_url, "posted_by": user.username if user else "Anonim"
            }
    return detalii