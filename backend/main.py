from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date
from database import engine, get_db
import models
from s3_utils import upload_file_to_s3
from routers import map
from backend.security import get_current_admin, get_current_user

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pawnder API")

app.include_router(map.router)

@app.post("/api/upload/id-card/")
async def upload_id_card(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.date_of_birth:
        raise HTTPException(status_code=400, detail="Please set your date of birth first!")
    
    today = date.today()
    age = today.year - current_user.date_of_birth.year - ((today.month, today.day) < (current_user.date_of_birth.month, current_user.date_of_birth.day))
    
    if age < 18:
        raise HTTPException(status_code=403, detail="You must be at least 18 years old!")

    # s3 upload
    file_url = upload_file_to_s3(file, folder="id_cards")

    # salvat in database
    current_user.id_card_url = file_url
    db.commit()

    return {"message": "Document uploaded successfully!", "url": file_url}

@app.post("/api/admin/approve-vet/{vet_profile_id}")
async def approve_veterinary(
    vet_profile_id: str,
    admin_user: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    vet_profile = db.query(models.VeterinaryProfile).filter(models.VeterinaryProfile.id == vet_profile_id).first()
    if not vet_profile:
        raise HTTPException(status_code=404, detail="Veterinary profile not found.")

    vet_profile.is_checked = True
    db.commit()

    return {"message": "Veterinary profile approved successfully!"}

@app.get("/api/test/create-user/")
def create_test_user(db: Session = Depends(get_db)):
    # test user major
    test_user = models.User(
        username="edyra_test",
        email="test2@pawnder.com",
        hash_pass="secret_password",
        date_of_birth=date(1995, 5, 20) 
    )
    db.add(test_user)
    db.commit()
    db.refresh(test_user)
    
    return {"message": "User successfully created!", "user_id": test_user.id}

@app.get("/api/admin/pending-identities/")
async def get_pending_identities(
    admin_user: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    # useri cu id neverificat
    pending_users = db.query(models.User).filter(
        models.User.id_card_url.isnot(None),
        models.User.is_identity_verified == False
    ).all()
    
    result = []
    for user in pending_users:
        result.append({
            "id": user.id,
            "username": user.username,
            "id_card_url": user.id_card_url
        })
        
    return result

@app.post("/api/admin/approve-identity/{target_user_id}")
async def approve_identity(
    target_user_id: str, 
    admin_user: models.User = Depends(get_current_admin), 
    db: Session = Depends(get_db)
):
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found.")
        
    target_user.is_identity_verified = True
    db.commit()
    
    return {"message": f"Identity for user {target_user.username} successfully approved by {admin_user.username}!"}


@app.post("/api/admin/reject-identity/{target_user_id}")
async def reject_identity(
    target_user_id: str, 
    admin_user: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found.")
        
    target_user.is_identity_verified = False
    target_user.id_card_url = None
    db.commit()
    
    return {"message": f"Document for {target_user.username} has been rejected."}