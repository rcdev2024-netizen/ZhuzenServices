#!/usr/bin/env python3
"""
Generate valid PBKDF2 password hashes for test users.
Run this script to generate hashes that work with the backend.

Usage: python generate_hashes.py
"""

import hashlib
import secrets

def hash_password(password: str) -> str:
    """Generate a PBKDF2-SHA256 password hash (same as backend/security.py)"""
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 310_000)
    return f"pbkdf2_sha256$310000${salt.hex()}${digest.hex()}"

if __name__ == "__main__":
    password = "test123"
    
    users = [
        "admin@zhuzen.com",
        "manager@zhuzen.com",
        "tech1@zhuzen.com",
        "tech2@zhuzen.com",
        "customer1@example.com",
    ]
    
    print(f"\n{'='*100}")
    print(f"Generated PBKDF2-SHA256 hashes for password: '{password}'")
    print(f"{'='*100}\n")
    
    hashes = {}
    for email in users:
        hash_value = hash_password(password)
        hashes[email] = hash_value
        print(f"Email: {email}")
        print(f"Hash: {hash_value}\n")
    
    print(f"{'='*100}")
    print("✅ All hashes generated successfully!")
    print("Copy the hashes above to update 003_test_data.sql")
    print(f"{'='*100}\n")

