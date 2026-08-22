USE pet_app_db;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM event_messages;
DELETE FROM consultation_messages;
DELETE FROM consultations;
DELETE FROM medical_records;
DELETE FROM pets;
DELETE FROM veterinary_profiles;
DELETE FROM missing_pet_posts;
DELETE FROM event_attendees;
DELETE FROM eveniments;
DELETE FROM hidden_gems;
DELETE FROM reviews;
DELETE FROM forum_posts;
DELETE FROM locations;
DELETE FROM users;
SET FOREIGN_KEY_CHECKS = 1;

-- Toate conturile au parola: parola123
INSERT INTO users (id, username, email, hash_pass, bio, rol, date_of_birth, is_premium, is_identity_verified, photo_url, created_at)
VALUES
-- 1. Administrator
('10000000-0000-0000-0000-000000000001', 'admin.pawnder', 'admin@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'Pawnder System Administrator.', 'ADMIN', '1990-01-01 00:00:00', 1, 1, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80', NOW()),

-- 2. Singurul Veterinar din sistem
('20000000-0000-0000-0000-000000000002', 'dr.maria', 'maria.vet@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'Medic veterinar specialist chirurgie si urgente.', 'VETERINARY', '1988-06-15 00:00:00', 0, 1, 'https://images.unsplash.com/photo-1594824813624-9b2f6ef0d880?auto=format&fit=crop&w=300&q=80', NOW()),

-- 3. Utilizator Premium 1
('30000000-0000-0000-0000-000000000003', 'daniel.apostol', 'daniel.apostol@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'Pet lover, Golden Retriever owner.', 'OWNER', '1998-05-20 00:00:00', 1, 1, 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=300&q=80', NOW()),

-- 4. Utilizator Premium 2 (pentru testul de fallback)
('40000000-0000-0000-0000-000000000004', 'miruna.mihai', 'miruna.mihai@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'Iubitoare de pisici si voluntar.', 'OWNER', '2001-11-10 00:00:00', 1, 1, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80', NOW()),

-- 5. Utilizator Free (Non-Premium)
('50000000-0000-0000-0000-000000000005', 'alex.radu', 'alex.radu@pawnder.com', '$2b$12$mZs/U0omoZRlbC1U/j5JUOxnImN1d72sMFrcGdR2Z8LuZ9bfyTeku', 'Pasionat de dresaj canin.', 'OWNER', '1995-03-25 00:00:00', 0, 0, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80', NOW());

-- Profil Veterinar
INSERT INTO veterinary_profiles (id, user_id, cabinet_name, is_checked, last_active_at)
VALUES
('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Clinica VetLife Herastrau', 1, NOW());

-- Animale
INSERT INTO pets (id, owner_id, name, species, breed, age, weight, photo_url, created_at)
VALUES
('31000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 'Max', 'Dog', 'Golden Retriever', 3.0, 31.5, 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80', NOW()),
('41000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000004', 'Luna', 'Cat', 'European Shorthair', 2.0, 3.8, 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80', NOW());

-- Înregistrări Medicale
INSERT INTO medical_records (id, pet_id, vet_name, description, vaccination_date, next_vaccination_date, created_at)
VALUES
('32000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000001', 'Dr. Maria Popescu', 'Vaccin anual Nobivac DHPPi + Rabies.', '2026-03-10 10:00:00', '2027-03-10 10:00:00', NOW());

-- Locații Hartă
INSERT INTO locations (id, title, description, type, latitude, longitude, phone_number)
VALUES
('70000000-0000-0000-0000-000000000001', 'VetLife Clinic Herastrau', 'Clinica veterinara non-stop complet echipata.', 'VET_CLINIC', 44.4715, 26.0825, '+40722111222'),
('70000000-0000-0000-0000-000000000002', 'Cismigiu Pet Garden Cafe', 'Cafenea pet-friendly cu zona speciala de joaca.', 'PET_FRIENDLY', 44.4370, 26.0890, '+40733444555');

-- Forum
INSERT INTO forum_posts (id, user_id, title, content, created_at)
VALUES
('80000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000004', 'Recomandare hrana pisici sterilizate', 'Buna tuturor! Ce tip de hrana umeda recomandati?', NOW());

