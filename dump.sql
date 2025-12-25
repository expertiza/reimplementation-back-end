-- Common Users Seed Data for Development Environment
-- This ensures all team members have the same test users
-- Usage: docker exec -i reimplementation-back-end-db-1 mysql -u root -pexpertiza reimplementation_development < users_seed_data.sql

-- Insert common user data (only if they don't already exist)
INSERT IGNORE INTO users (id, full_name, email, password_digest, role_id, created_at, updated_at) VALUES
(1, 'Admin User', 'admin@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 1, NOW(), NOW()),
(2, 'Alice Johnson', 'alice@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW()),
(3, 'Bob Smith', 'bob@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW()),
(4, 'Charlie Davis', 'charlie@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW()),
(5, 'Diana Martinez', 'diana@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW()),
(6, 'Ethan Brown', 'ethan@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW()),
(7, 'Fiona Wilson', 'fiona@example.com', '$2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW', 4, NOW(), NOW());

-- Note: All users have the password "password123"
-- Password hash: $2a$12$PfN/CKp7R6aQp9bXt6SKIOElvh2DuXkopyN4xjRI3J.F8uAKsI1jW

SELECT 'Users seed data loaded successfully!' AS message;
SELECT id, full_name, email FROM users WHERE id IN (1, 2, 3, 4, 5, 6, 7);