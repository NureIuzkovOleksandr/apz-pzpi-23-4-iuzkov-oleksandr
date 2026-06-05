from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv


load_dotenv()


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:your_password@localhost:5432/climate_monitoring"
)


engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=30,
    pool_recycle=3600,
    connect_args={"connect_timeout": 10, "application_name": "climate_api"}
)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


Base = declarative_base()


def get_db():


    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()



def create_tables():


    print("Creating PostgreSQL tables if they do not exist")
    try:
        Base.metadata.create_all(bind=engine)
    except IntegrityError as e:
        msg = str(e).lower()
        if "pg_type_typname_nsp_index" in msg or "duplicate key value violates unique constraint" in msg:
            print("Warning: enum type already exists, continuing")
        else:
            raise
    print("PostgreSQL tables ready")



def drop_tables():
    Base.metadata.drop_all(bind=engine)