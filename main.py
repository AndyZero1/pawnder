from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date
from database import engine, get_db
import models
from s3_utils import upload_file_to_s3

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pawnder API")

@app.post("/api/upload/id-card/")
async def upload_id_card(
    user_id: str = Form(...), 
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Userul nu a fost găsit.")

    if not user.date_of_birth:
        raise HTTPException(status_code=400, detail="Setați data nașterii mai întâi!")
    
    today = date.today()
    age = today.year - user.date_of_birth.year - ((today.month, today.day) < (user.date_of_birth.month, user.date_of_birth.day))
    
    if age < 18:
        raise HTTPException(status_code=403, detail="Trebuie să ai minim 18 ani!")

    # upload S3
    file_url = upload_file_to_s3(file, folder="id_cards")

    # salvare in baza de date
    user.id_card_url = file_url
    db.commit()

    return {"message": "Document încărcat cu succes!", "url": file_url}

@app.post("/api/admin/approve-vet/{vet_profile_id}")
async def approve_veterinary(
    vet_profile_id: str,
    admin_id: str = Form(...),
    db: Session = Depends(get_db)
):
    admin_user = db.query(models.User).filter(models.User.id == admin_id).first()
    if not admin_user or admin_user.rol != "ADMIN":
        raise HTTPException(status_code=403, detail="Nu ai permisiuni de administrator.")

    vet_profile = db.query(models.VeterinaryProfile).filter(models.VeterinaryProfile.id == vet_profile_id).first()
    if not vet_profile:
        raise HTTPException(status_code=404, detail="Profilul nu există.")

    vet_profile.is_checked = True
    db.commit()

    return {"message": "Profil aprobat cu succes!"}

@app.get("/api/test/create-user/")
def create_test_user(db: Session = Depends(get_db)):
    # proba user major
    test_user = models.User(
        username="edyra_test",
        email="tes2@pawnder.com",
        hash_pass="parola_secreta",
        date_of_birth=date(1995, 5, 20) 
    )
    db.add(test_user)
    db.commit()
    db.refresh(test_user)
    
    return {"mesaj": "User creat cu succes!", "user_id": test_user.id}

@app.get("/api/admin/pending-identities/")
async def get_pending_identities(admin_id: str, db: Session = Depends(get_db)):
    # verificare admin
    admin_user = db.query(models.User).filter(models.User.id == admin_id).first()
    if not admin_user or admin_user.rol != "ADMIN":
        raise HTTPException(status_code=403, detail="Acces interzis. Doar pentru Administratori.")
    
    # user care are buletin neverificat
    pending_users = db.query(models.User).filter(
        models.User.id_card_url.isnot(None),
        models.User.is_identity_verified == False
    ).all()
    
    rezultat = []
    for user in pending_users:
        rezultat.append({
            "id": user.id,
            "username": user.username,
            "id_card_url": user.id_card_url
        })
        
    return rezultat

@app.post("/api/admin/approve-identity/{target_user_id}")
async def approve_identity(
    target_user_id: str, 
    admin_id: str = Form(...), 
    db: Session = Depends(get_db)
):
    # verificare admin
    admin_user = db.query(models.User).filter(models.User.id == admin_id).first()
    if not admin_user or admin_user.rol != "ADMIN":
        raise HTTPException(status_code=403, detail="Acces interzis.")
        
    # 2. aprobare utilizator
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Utilizatorul țintă nu a fost găsit.")
        
    # 3. identitatea user ului salvata
    target_user.is_identity_verified = True
    db.commit()
    
    return {"message": f"Identitatea utilizatorului {target_user.username} a fost aprobată cu succes!"}

@app.post("/api/admin/reject-identity/{target_user_id}")
async def reject_identity(
    target_user_id: str, 
    admin_id: str = Form(...), 
    db: Session = Depends(get_db)
):
    # verificare admin
    admin_user = db.query(models.User).filter(models.User.id == admin_id).first()
    if not admin_user or admin_user.rol != "ADMIN":
        raise HTTPException(status_code=403, detail="Acces interzis.")
        
    # optiunea de respins
    target_user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu a fost găsit.")
        
    # identitate respinsa
    target_user.is_identity_verified = False
    target_user.id_card_url = None
    db.commit()
    
    return {"message": f"Documentul pentru {target_user.username} a fost respins cu succes."}