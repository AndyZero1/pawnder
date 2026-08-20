USE pet_app_db;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE consultation_messages;
TRUNCATE TABLE consultations;
TRUNCATE TABLE medical_records;
TRUNCATE TABLE pets;
TRUNCATE TABLE veterinary_profiles;
TRUNCATE TABLE missing_pet_posts;
TRUNCATE TABLE event_attendees;
TRUNCATE TABLE eveniments;
TRUNCATE TABLE hidden_gems;
TRUNCATE TABLE reviews;
TRUNCATE TABLE forum_posts;
TRUNCATE TABLE locations;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

-- parola este parola123
INSERT INTO users (id, username, email, hash_pass, rol, is_premium, is_identity_verified, photo_url, created_at)
VALUES
('10000000-0000-0000-0000-000000000001', 'admin.pawnder', 'admin@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'ADMIN', 1, 1, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80', NOW()),

('20000000-0000-0000-0000-000000000002', 'dr.maria', 'maria.vet@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'VETERINARY', 0, 1, 'https://images.unsplash.com/photo-1594824813624-9b2f6ef0d880?auto=format&fit=crop&w=300&q=80', NOW()),

('30000000-0000-0000-0000-000000000003', 'daniel.apostol', 'daniel.apostol@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'OWNER', 1, 1, 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=300&q=80', NOW()),

('40000000-0000-0000-0000-000000000004', 'miruna.mihai', 'miruna.mihai@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'OWNER', 0, 0, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=30<PASSWORD>', NOW()),

('50000000-0000-0000-0000-000000000005', 'alex.radu', 'alex.radu@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'OWNER', 0, 0, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80', NOW());

INSERT INTO veterinary_profiles (id, user_id, cabinet_name, is_checked, last_active_at)
VALUES
('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Clinica VetLife Herastrau', 1, NOW());

INSERT INTO pets (id, owner_id, name, species, breed, age, weight, photo_url, created_at)
VALUES
('31000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 'Max', 'Dog', 'Golden Retriever', 3.0, 31.5, 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80', NOW()),
('31000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', 'Milo', 'Cat', 'British Shorthair', 1.5, 4.2, 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=800&q=80', NOW()),

('41000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000004', 'Luna', 'Cat', 'European Shorthair', 2.0, 3.8, 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80', NOW()),

('51000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000005', 'Rocky', 'Dog', 'Beagle', 4.0, 14.0, 'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=800&q=80', NOW());

INSERT INTO medical_records (id, pet_id, vet_name, description, vaccination_date, next_vaccination_date, created_at)
VALUES
('32000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000001', 'Dr. Maria Popescu', 'Vaccin anual polivalent Nobivac DHPPi + Rabies.', '2026-03-10 10:00:00', '2027-03-10 10:00:00', NOW());

INSERT INTO locations (id, title, description, type, latitude, longitude, phone_number)
VALUES
('70000000-0000-0000-0000-000000000001', 'VetLife Clinic Herastrau', 'Clinica veterinara non-stop complet echipata.', 'VET_CLINIC', 44.4715, 26.0825, '+40722111222'),
('70000000-0000-0000-0000-000000000002', 'Cismigiu Pet Garden Cafe', 'Cafenea pet-friendly cu zona speciala de joaca.', 'PET_FRIENDLY', 44.4370, 26.0890, '+40733444555');

INSERT INTO forum_posts (id, user_id, title, content, created_at)
VALUES
('80000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000004', 'Recomandare hrana pisici sterilizate', 'Buna tuturor! Ce tip de hrana umeda recomandati pentru o pisicuta de 2 ani?', NOW());