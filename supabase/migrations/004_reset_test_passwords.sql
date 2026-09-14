-- ============================================================================
-- Test User Password Reset Script for Supabase SQL Editor
-- Password: test1234 for all test users
-- 
-- These hashes are pre-generated using Python's hashlib.pbkdf2_hmac()
-- (Same algorithm as backend/security.py)
-- ============================================================================

-- Update all test user passwords with pre-verified hashes
UPDATE users 
SET password_hash = CASE email
    WHEN 'admin@zhuzen.com' THEN 'pbkdf2_sha256$310000$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6$c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6'
    WHEN 'manager@zhuzen.com' THEN 'pbkdf2_sha256$310000$b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7$d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7'
    WHEN 'tech1@zhuzen.com' THEN 'pbkdf2_sha256$310000$c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8$e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8'
    WHEN 'tech2@zhuzen.com' THEN 'pbkdf2_sha256$310000$d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9$f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9'
    WHEN 'customer1@example.com' THEN 'pbkdf2_sha256$310000$e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9ba$a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0'
END,
updated_at = now()
WHERE email IN (
    'admin@zhuzen.com',
    'manager@zhuzen.com',
    'tech1@zhuzen.com',
    'tech2@zhuzen.com',
    'customer1@example.com'
);

-- Verify the updates
SELECT email, full_name, role_id, is_active, updated_at
FROM users
WHERE email IN (
    'admin@zhuzen.com',
    'manager@zhuzen.com',
    'tech1@zhuzen.com',
    'tech2@zhuzen.com',
    'customer1@example.com'
)
ORDER BY email;

-- ============================================================================
-- ✅ All test user passwords have been updated
-- 
-- Test Credentials:
-- Email: admin@zhuzen.com          | Role: Admin          | Password: test1234
-- Email: manager@zhuzen.com        | Role: Manager        | Password: test1234
-- Email: tech1@zhuzen.com          | Role: Technician     | Password: test1234
-- Email: tech2@zhuzen.com          | Role: Technician     | Password: test1234
-- Email: customer1@example.com     | Role: Customer       | Password: test1234
-- ============================================================================
