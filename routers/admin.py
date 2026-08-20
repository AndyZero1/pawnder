from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from datetime import date, datetime
from typing import Optional
from database import get_db
import models
from s3_utils import upload_file_to_s3

router = APIRouter(
    prefix="/api",
    tags=["Admin & Verification"]
)

def calculate_age(born) -> int:
    if not born:
        return 0
    if hasattr(born, 'date'):
        born = born.date()
    today = date.today()
    return today.year - born.year - ((today.month, today.day) < (born.month, born.day))

@router.post("/upload/id-card/")
def upload_id_card(
    user_id: str = Form(...), 
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Userul nu a fost găsit.")

    if not user.birth_date:
        raise HTTPException(status_code=400, detail="Setați data nașterii mai întâi!")
    
    age = calculate_age(user.birth_date)
    if age < 18:
        raise HTTPException(status_code=403, detail="Trebuie să ai minim 18 ani!")

    file_url = upload_file_to_s3(file, folder="id_cards")

    user.id_card_url = file_url
    user.is_identity_verified = False
    db.commit()

    return {"message": "Document încărcat cu succes!", "url": file_url}

@router.get("/admin/pending-identities/")
def get_pending_identities(
    admin_id: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    pending_users = db.query(models.User).filter(
        models.User.id_card_url.isnot(None),
        models.User.is_identity_verified == False
    ).all()
    
    rezultat = []
    for user in pending_users:
        rezultat.append({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "age": calculate_age(user.birth_date),
            "id_card_url": user.id_card_url,
            "created_at": user.created_at.strftime("%d.%m.%Y") if user.created_at else "Azi"
        })
        
    return rezultat

@router.post("/admin/approve-identity/{target_user_id}")
def approve_identity(
    target_user_id: str, 
    admin_id: Optional[str] = Form(None), 
    db: Session = Depends(get_db)
):
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Utilizatorul țintă nu a fost găsit.")
        
    target_user.is_identity_verified = True
    db.commit()
    
    return {"message": f"Identitatea utilizatorului {target_user.username} a fost aprobată cu succes!"}

@router.post("/admin/reject-identity/{target_user_id}")
def reject_identity(
    target_user_id: str, 
    admin_id: Optional[str] = Form(None), 
    db: Session = Depends(get_db)
):
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu a fost găsit.")
        
    target_user.is_identity_verified = False
    target_user.id_card_url = None
    db.commit()
    
    return {"message": f"Documentul pentru {target_user.username} a fost respins cu succes."}

@router.get("/admin/pending-vets/")
def get_pending_vets(db: Session = Depends(get_db)):
    pending_vets = db.query(models.VeterinaryProfile).filter(
        models.VeterinaryProfile.is_checked == False
    ).all()

    rezultat = []
    for vet in pending_vets:
        user = vet.user
        rezultat.append({
            "id": vet.id,
            "cabinet_name": vet.cabinet_name or "Cabinet Veterinar",
            "doctor_name": user.username if user else "Dr. Medic",
            "email": user.email if user else "",
            "cv_url": vet.cv_url,
            "recommendation_form_url": vet.recommendation_form_url
        })
    return rezultat

@router.post("/admin/approve-vet/{vet_profile_id}")
def approve_veterinary(
    vet_profile_id: str,
    admin_id: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    vet_profile = db.query(models.VeterinaryProfile).filter(models.VeterinaryProfile.id == vet_profile_id).first()
    if not vet_profile:
        raise HTTPException(status_code=404, detail="Profilul nu există.")

    vet_profile.is_checked = True
    db.commit()

    return {"message": "Profil veterinar aprobat cu succes!"}
