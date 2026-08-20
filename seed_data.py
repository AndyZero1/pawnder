import uuid
from datetime import datetime, timezone
import bcrypt
import models
from database import engine, Base

def hash_password(password: str) -> str:
    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode("utf-8")

def seed_database(db):
    Base.metadata.create_all(bind=engine)
    # Check if already seeded
    existing_pets = db.query(models.Pet).count()

    if existing_pets >= 5:
        print(f"Database already has {existing_pets} pets. Skipping seed.")
        return

    print("Seeding database with test users and pets...")

    # 1. Main Demo User
    demo_user = db.query(models.User).filter(models.User.email == "adrian@pawnder.com").first()
    if not demo_user:
        demo_user = models.User(
            id=str(uuid.uuid4()),
            username="Adrian",
            email="adrian@pawnder.com",
            hash_pass=hash_password("password123"),
            rol=models.Role.OWNER,
            birth_date=datetime(1998, 5, 20, tzinfo=timezone.utc),
            photo_url="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80",
            bio="Dog dad and tech enthusiast! Always down for weekend park playdates."
        )
        db.add(demo_user)
        db.commit()
        db.refresh(demo_user)

    # 2. Demo User's Pet (Luna)
    adrian_pet = db.query(models.Pet).filter(models.Pet.owner_id == demo_user.id).first()
    if not adrian_pet:
        adrian_pet = models.Pet(
            id=str(uuid.uuid4()),
            owner_id=demo_user.id,
            name="Luna",
            species="Dog",
            breed="Golden Retriever",
            age=2.5,
            photo_url="https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=80",
            description="Loving, active Golden girl who loves tennis balls and socializing!"
        )
        db.add(adrian_pet)
        db.commit()
        db.refresh(adrian_pet)

    # 3. Other pet owners and their pets
    owners_data = [
        {
            "username": "Elena Popescu",
            "email": "elena@example.com",
            "birth_date": datetime(1996, 4, 12, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80",
            "bio": "Loving dog mom and weekend park runner! 🏃‍♀️🐾",
            "pets": [
                {
                    "name": "Bella",
                    "species": "Dog",
                    "breed": "Border Collie",
                    "age": 2.0,
                    "photo_url": "https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=900&q=80",
                    "description": "Smart, energetic agility champion. Loves catching frisbees in Herăstrău park!",
                    "has_liked_adrian": True # Will create an instant match!
                }
            ]
        },
        {
            "username": "Andrei Ionescu",
            "email": "andrei@example.com",
            "birth_date": datetime(1994, 9, 8, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80",
            "bio": "Mountain hiker & outdoor lover with a fluffy companion.",
            "pets": [
                {
                    "name": "Thor",
                    "species": "Dog",
                    "breed": "Siberian Husky",
                    "age": 3.0,
                    "photo_url": "https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=900&q=80",
                    "description": "Dramatic vocal singer and master of snow & mud. Very friendly with other dogs!",
                    "has_liked_adrian": True
                }
            ]
        },
        {
            "username": "Maria Radu",
            "email": "maria@example.com",
            "birth_date": datetime(1999, 11, 23, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
            "bio": "Architecture student & dedicated Corgi parent. ☕🐕",
            "pets": [
                {
                    "name": "Milo",
                    "species": "Dog",
                    "breed": "Welsh Corgi Pembroke",
                    "age": 1.5,
                    "photo_url": "https://images.unsplash.com/photo-1612536057832-2ff7ead58194?auto=format&fit=crop&w=900&q=80",
                    "description": "Little legs, huge personality! Loves tummy rubs and making canine friends.",
                    "has_liked_adrian": True
                }
            ]
        },
        {
            "username": "Radu Dumitrescu",
            "email": "radu@example.com",
            "birth_date": datetime(1993, 2, 17, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
            "bio": "Coffee, photography and long park walks.",
            "pets": [
                {
                    "name": "Simba",
                    "species": "Dog",
                    "breed": "Golden Retriever",
                    "age": 4.0,
                    "photo_url": "https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=900&q=80",
                    "description": "Gentle giant who loves swimming and chilling on sunny grass.",
                    "has_liked_adrian": False
                }
            ]
        },
        {
            "username": "Ana Moraru",
            "email": "ana@example.com",
            "birth_date": datetime(1997, 7, 5, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80",
            "bio": "Graphic designer & Shiba lover. Follow our adventures! ✨",
            "pets": [
                {
                    "name": "Nala",
                    "species": "Dog",
                    "breed": "Shiba Inu",
                    "age": 2.0,
                    "photo_url": "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=900&q=80",
                    "description": "Curious and alert queen. Takes time to warm up, but once a friend, a friend forever!",
                    "has_liked_adrian": True
                }
            ]
        },
        {
            "username": "Cristian Vasile",
            "email": "cristi@example.com",
            "birth_date": datetime(1995, 8, 30, tzinfo=timezone.utc),
            "photo_url": "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=400&q=80",
            "bio": "Frenchie enthusiast and amateur baker.",
            "pets": [
                {
                    "name": "Rocky",
                    "species": "Dog",
                    "breed": "French Bulldog",
                    "age": 3.5,
                    "photo_url": "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=900&q=80",
                    "description": "Snore champion and cuddle monster. Always excited to meet new dogs!",
                    "has_liked_adrian": False
                }
            ]
        }
    ]

    for o_data in owners_data:
        user = db.query(models.User).filter(models.User.email == o_data["email"]).first()
        if not user:
            user = models.User(
                id=str(uuid.uuid4()),
                username=o_data["username"],
                email=o_data["email"],
                hash_pass=hash_password("password123"),
                rol=models.Role.OWNER,
                birth_date=o_data["birth_date"],
                photo_url=o_data["photo_url"],
                bio=o_data["bio"]
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        for p_data in o_data["pets"]:
            pet = db.query(models.Pet).filter(
                models.Pet.name == p_data["name"],
                models.Pet.owner_id == user.id
            ).first()

            if not pet:
                pet = models.Pet(
                    id=str(uuid.uuid4()),
                    owner_id=user.id,
                    name=p_data["name"],
                    species=p_data["species"],
                    breed=p_data["breed"],
                    age=p_data["age"],
                    photo_url=p_data["photo_url"],
                    description=p_data["description"]
                )
                db.add(pet)
                db.commit()
                db.refresh(pet)

                # Pre-swipe on Adrian's pet so when Adrian likes, a match is created
                if p_data.get("has_liked_adrian") and adrian_pet:
                    swipe = models.PetSwipe(
                        id=str(uuid.uuid4()),
                        swiper_id=user.id,
                        target_pet_id=adrian_pet.id,
                        is_like=True
                    )
                    db.add(swipe)
                    db.commit()

    print("Database successfully seeded with users and pets! 🎉")

if __name__ == "__main__":
    from database import SessionLocal
    db = SessionLocal()
    seed_database(db)
    db.close()
