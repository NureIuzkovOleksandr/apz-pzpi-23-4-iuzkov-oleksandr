#!/usr/bin/env python3
"""Initialize admin user in the database"""
import sys
import os
from dotenv import load_dotenv

load_dotenv()

# Add app to path
sys.path.insert(0, '/app')

from database import SessionLocal
import models
from auth import get_password_hash

def init_admin():
    db = SessionLocal()
    try:
        admin = db.query(models.User).filter(models.User.email == "admin@example.com").first()
        
        if admin:
            print("✓ Admin user already exists")
            return True
        
        print("Creating admin user...")
        admin_user = models.User(
            email="admin@example.com",
            username="admin",
            password_hash=get_password_hash("admin1234"),
            first_name="Admin",
            last_name="User",
            is_admin=True,
            is_active=True
        )
        db.add(admin_user)
        db.commit()
        print("✓ Admin user created successfully!")
        return True
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = init_admin()
    sys.exit(0 if success else 1)
