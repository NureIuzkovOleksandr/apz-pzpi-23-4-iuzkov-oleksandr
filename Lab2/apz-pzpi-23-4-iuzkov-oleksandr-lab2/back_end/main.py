from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import List, Optional, Dict
from datetime import timedelta, datetime
import uvicorn
import io
import math
import time
from database import get_db, create_tables
import models
import schemas
from schemas import SensorProcessingResponse, SensorReadingInput
from auth import (
    get_password_hash,
    authenticate_user,
    create_access_token,
    get_current_user,
    verify_password,
    ACCESS_TOKEN_EXPIRE_MINUTES
)
from business_logic import (
    SensorReadingProcessor,
    AnalyticsService,
    AutoControlFlow,
    DataValidationFlow,
    UserManagementFlow,
    AnalyticsReportFlow
)
import os
from datetime import datetime
from contextlib import asynccontextmanager


class RequestCounter:
    def __init__(self):
        self.request_count = 0
        self.start_time = datetime.now()
        self.error_count = 0

    def increment(self):
        self.request_count += 1

    def increment_error(self):
        self.error_count += 1

    def get_stats(self):
        elapsed = (datetime.now() - self.start_time).total_seconds()
        rps = self.request_count / elapsed if elapsed > 0 else 0
        return {
            "total_requests": self.request_count,
            "total_errors": self.error_count,
            "uptime_seconds": elapsed,
            "requests_per_second": round(rps, 2),
            "pod_name": os.getenv("POD_NAME", "unknown"),
            "timestamp": datetime.now().isoformat()
        }

request_counter = RequestCounter()


# Initialize admin user on startup
def _init_admin_user():
    import sys
    sys.stderr.write("[INIT] Starting admin initialization\n"); sys.stderr.flush()
    try:
        from database import SessionLocal
        db = SessionLocal()
        sys.stderr.write("[INIT] Database session created\n"); sys.stderr.flush()
        
        admin_exists = db.query(models.User).filter(
            models.User.email == "admin@example.com"
        ).first()
        sys.stderr.write(f"[INIT] Admin exists: {admin_exists is not None}\n"); sys.stderr.flush()
        
        if not admin_exists:
            sys.stderr.write("[INIT] Creating admin user...\n"); sys.stderr.flush()
            hashed_pw = get_password_hash("admin1234")
            sys.stderr.write(f"[INIT] Password hashed successfully\n"); sys.stderr.flush()
            admin_user = models.User(
                email="admin@example.com",
                username="admin",
                password_hash=hashed_pw,
                first_name="Admin",
                last_name="User",
                is_admin=True,
                is_active=True
            )
            db.add(admin_user)
            db.commit()
            sys.stderr.write("[INIT] ✓ Created default admin user\n"); sys.stderr.flush()
        else:
            sys.stderr.write("[INIT] ✓ Admin user already exists\n"); sys.stderr.flush()
    except Exception as e:
        import traceback
        sys.stderr.write(f"[INIT] ERROR: {e}\n"); sys.stderr.flush()
        sys.stderr.write(traceback.format_exc()); sys.stderr.flush()
    finally:
        if 'db' in locals():
            db.close()
    sys.stderr.write("[INIT] Startup complete\n"); sys.stderr.flush()


@asynccontextmanager
async def lifespan(app):
    # Startup
    print("Starting Climate Monitoring System API...", flush=True)
    create_tables()
    print("Connected to PostgreSQL database", flush=True)
    
    # Initialize admin user
    try:
        from database import SessionLocal
        db = SessionLocal()
        admin = db.query(models.User).filter(models.User.email == "admin@example.com").first()
        if not admin:
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
            print("✓ Created admin user", flush=True)
        else:
            print("✓ Admin user exists", flush=True)
        db.close()
    except Exception as e:
        print(f"⚠ Admin init failed: {e}", flush=True)
    
    yield
    # Shutdown
    print("Shutting down Climate Monitoring System API...", flush=True)


app = FastAPI(
    title="Climate Monitoring System API",
    description="API для системи моніторингу температури та вологості в приміщенні",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "*"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



@app.middleware("http")
async def count_requests(request, call_next):

    try:
        request_counter.increment()
        response = await call_next(request)
        response.headers['X-Upstream-Server'] = f"{os.getenv('APP_NAME', 'api')}/{os.getenv('POD_NAME', 'unknown')}"
        return response
    except Exception as e:
        request_counter.increment_error()
        raise


@app.get("/", tags=["Root"])
async def root():

    return {
        "message": "Climate Monitoring System API",
        "version": "1.0.0",
        "docs": "/api/docs"
    }


@app.get("/health", tags=["Health"])
async def health_check():

    return {"status": "healthy", "database": "connected"}


@app.get("/metrics", tags=["Monitoring"])
async def get_metrics():


    return request_counter.get_stats()


@app.post("/api/test/load", tags=["Testing"])
async def simulate_load(
    intensity: int = Query(5, ge=1, le=10),
    duration_seconds: int = Query(5, ge=1, le=30)
):


    start_time = time.perf_counter()
    work_units = intensity * 150000
    result_value = 0.0

    for i in range(work_units):
        result_value += math.sqrt((i % 1000) + 1)
        if i % 50000 == 0 and time.perf_counter() - start_time > duration_seconds:
            break

    elapsed = time.perf_counter() - start_time
    stats = request_counter.get_stats()

    return {
        "status": "ok",
        "elapsed_seconds": round(elapsed, 3),
        "intensity": intensity,
        "work_units": i + 1,
        "server_pod": stats["pod_name"],
        "requests_per_second": stats["requests_per_second"],
    }




@app.post("/api/users/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED, tags=["Users"])
async def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):




    existing_user = db.query(models.User).filter(models.User.email == user.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )


    existing_username = db.query(models.User).filter(models.User.username == user.username).first()
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )


    hashed_password = get_password_hash(user.password)

    db_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        first_name=user.first_name,
        last_name=user.last_name,
        phone_number=user.phone_number
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user


@app.post("/api/auth/login", response_model=schemas.Token, tags=["Authentication"])
async def login(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):




    user = authenticate_user(db, login_data.email, login_data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )


    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@app.post("/api/auth/login/form", response_model=schemas.Token, tags=["Authentication"])
async def login_form(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):



    user = authenticate_user(db, form_data.username, form_data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@app.post("/api/auth/logout", tags=["Authentication"])
async def logout(current_user: models.User = Depends(get_current_user)):


    return {
        "message": "Successfully logged out",
        "user": current_user.username
    }




@app.get("/api/users/me", response_model=schemas.UserResponse, tags=["Users"])
async def get_current_user_profile(current_user: models.User = Depends(get_current_user)):


    return current_user


@app.put("/api/users/me", response_model=schemas.UserResponse, tags=["Users"])
async def update_current_user(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, key, value)

    db.commit()
    db.refresh(current_user)

    return current_user


@app.delete("/api/users/me", status_code=status.HTTP_204_NO_CONTENT, tags=["Users"])
async def delete_current_user(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    db.delete(current_user)
    db.commit()

    return None


@app.put("/api/users/me/password", tags=["Users"])
async def change_password(
    password_data: schemas.PasswordChange,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):




    if not verify_password(password_data.old_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password"
        )


    current_user.password_hash = get_password_hash(password_data.new_password)
    db.commit()

    return {"message": "Password changed successfully"}




@app.get("/api/rooms", response_model=List[schemas.RoomResponse], tags=["Rooms"])
async def get_rooms(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    rooms = db.query(models.Room).filter(
        models.Room.user_id == current_user.id
    ).all()

    return rooms


@app.post("/api/rooms", response_model=schemas.RoomResponse, status_code=status.HTTP_201_CREATED, tags=["Rooms"])
async def create_room(
    room: schemas.RoomCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    db_room = models.Room(
        name=room.name,
        description=room.description,
        floor=room.floor,
        area=room.area,
        user_id=current_user.id
    )

    db.add(db_room)
    db.commit()
    db.refresh(db_room)

    return db_room


@app.get("/api/rooms/{room_id}", response_model=schemas.RoomResponse, tags=["Rooms"])
async def get_room(
    room_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )

    return room


@app.put("/api/rooms/{room_id}", response_model=schemas.RoomResponse, tags=["Rooms"])
async def update_room(
    room_id: int,
    room_update: schemas.RoomUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )

    for key, value in room_update.dict(exclude_unset=True).items():
        setattr(room, key, value)

    db.commit()
    db.refresh(room)

    return room


@app.delete("/api/rooms/{room_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Rooms"])
async def delete_room(
    room_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )

    db.delete(room)
    db.commit()

    return None




@app.get("/api/sensors", response_model=List[schemas.SensorResponse], tags=["Sensors"])
async def get_sensors(
    room_id: int = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    query = db.query(models.Sensor).join(models.Room).filter(
        models.Room.user_id == current_user.id
    )

    if room_id:

        room = db.query(models.Room).filter(
            models.Room.id == room_id,
            models.Room.user_id == current_user.id
        ).first()

        if not room:
            raise HTTPException(
                status_code=404,
                detail="Room not found or you don't have access"
            )

        query = query.filter(models.Sensor.room_id == room_id)

    sensors = query.all()
    return sensors


@app.post("/api/sensors", response_model=schemas.SensorResponse, status_code=status.HTTP_201_CREATED, tags=["Sensors"])
async def create_sensor(
    sensor: schemas.SensorCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):




    room = db.query(models.Room).filter(
        models.Room.id == sensor.room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )


    existing_sensor = db.query(models.Sensor).filter(
        models.Sensor.device_id == sensor.device_id
    ).first()

    if existing_sensor:
        raise HTTPException(
            status_code=400,
            detail="Sensor with this device_id already exists"
        )

    db_sensor = models.Sensor(
        name=sensor.name,
        device_id=sensor.device_id,
        room_id=sensor.room_id,
        sensor_type=sensor.sensor_type
    )

    db.add(db_sensor)
    db.commit()
    db.refresh(db_sensor)

    return db_sensor


@app.get("/api/sensors/{sensor_id}", response_model=schemas.SensorResponse, tags=["Sensors"])
async def get_sensor(
    sensor_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    sensor = db.query(models.Sensor).join(models.Room).filter(
        models.Sensor.id == sensor_id,
        models.Room.user_id == current_user.id
    ).first()

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found or you don't have access"
        )

    return sensor


@app.put("/api/sensors/{sensor_id}", response_model=schemas.SensorResponse, tags=["Sensors"])
async def update_sensor(
    sensor_id: int,
    sensor_update: schemas.SensorUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    sensor = db.query(models.Sensor).join(models.Room).filter(
        models.Sensor.id == sensor_id,
        models.Room.user_id == current_user.id
    ).first()

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found or you don't have access"
        )

    for key, value in sensor_update.dict(exclude_unset=True).items():
        setattr(sensor, key, value)

    db.commit()
    db.refresh(sensor)

    return sensor


@app.delete("/api/sensors/{sensor_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Sensors"])
async def delete_sensor(
    sensor_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    sensor = db.query(models.Sensor).join(models.Room).filter(
        models.Sensor.id == sensor_id,
        models.Room.user_id == current_user.id
    ).first()

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found or you don't have access"
        )

    db.delete(sensor)
    db.commit()

    return None


@app.post("/api/sensors/{sensor_id}/readings", response_model=schemas.SensorReadingResponse, status_code=status.HTTP_201_CREATED, tags=["Sensors"])
async def create_sensor_reading(
    sensor_id: int,
    reading: schemas.SensorReadingCreate,
    db: Session = Depends(get_db)
):


    sensor = db.query(models.Sensor).filter(
        models.Sensor.id == sensor_id
    ).first()

    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")


    sensor.last_online = datetime.utcnow()

    db_reading = models.SensorReading(
        sensor_id=sensor_id,
        temperature=reading.temperature,
        humidity=reading.humidity,
        timestamp=reading.timestamp or datetime.utcnow()
    )

    db.add(db_reading)
    db.commit()
    db.refresh(db_reading)

    return db_reading


@app.get("/api/sensors/{sensor_id}/readings", response_model=List[schemas.SensorReadingResponse], tags=["Sensors"])
async def get_sensor_readings(
    sensor_id: int,
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):




    sensor = db.query(models.Sensor).join(models.Room).filter(
        models.Sensor.id == sensor_id,
        models.Room.user_id == current_user.id
    ).first()

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail="Sensor not found or you don't have access"
        )

    readings = db.query(models.SensorReading)\
        .filter(models.SensorReading.sensor_id == sensor_id)\
        .order_by(models.SensorReading.timestamp.desc())\
        .limit(limit)\
        .all()

    return readings




@app.get("/api/climate-devices", response_model=List[schemas.ClimateDeviceResponse], tags=["Climate Devices"])
async def get_climate_devices(
    room_id: int = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    query = db.query(models.ClimateDevice).join(models.Room).filter(
        models.Room.user_id == current_user.id
    )

    if room_id:
        query = query.filter(models.ClimateDevice.room_id == room_id)

    devices = query.all()
    return devices


@app.post("/api/climate-devices", response_model=schemas.ClimateDeviceResponse, status_code=status.HTTP_201_CREATED, tags=["Climate Devices"])
async def create_climate_device(
    device: schemas.ClimateDeviceCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    room = db.query(models.Room).filter(
        models.Room.id == device.room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room not found or you don't have access")

    db_device = models.ClimateDevice(
        name=device.name,
        device_id=device.device_id,
        room_id=device.room_id,
        device_type=device.device_type,
        power_consumption=device.power_consumption
    )

    db.add(db_device)
    db.commit()
    db.refresh(db_device)

    return db_device

@app.get("/api/climate-devices/{device_id}", response_model=schemas.ClimateDeviceResponse, tags=["Climate Devices"])
async def get_climate_device(
    device_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    device = db.query(models.ClimateDevice).join(models.Room).filter(
        models.ClimateDevice.id == device_id,
        models.Room.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=404,
            detail="Device not found or you don't have access"
        )

    return device

@app.put("/api/climate-devices/{device_id}", response_model=schemas.ClimateDeviceResponse, tags=["Climate Devices"])
async def update_climate_device(
    device_id: int,
    device_update: schemas.ClimateDeviceUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    device = db.query(models.ClimateDevice).join(models.Room).filter(
        models.ClimateDevice.id == device_id,
        models.Room.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=404,
            detail="Device not found or you don't have access"
        )


    for key, value in device_update.dict(exclude_unset=True).items():
        setattr(device, key, value)

    db.commit()
    db.refresh(device)

    return device
@app.delete("/api/climate-devices/{device_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Climate Devices"])
async def delete_climate_device(
    device_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    device = db.query(models.ClimateDevice).join(models.Room).filter(
        models.ClimateDevice.id == device_id,
        models.Room.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=404,
            detail="Device not found or you don't have access"
        )

    db.delete(device)
    db.commit()

    return None

@app.post("/api/climate-devices/{device_id}/control", response_model=schemas.DeviceCommandResponse, status_code=status.HTTP_201_CREATED, tags=["Climate Devices"])
async def control_device(
    device_id: int,
    command: schemas.DeviceCommandCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    device = db.query(models.ClimateDevice).join(models.Room).filter(
        models.ClimateDevice.id == device_id,
        models.Room.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(status_code=404, detail="Device not found or you don't have access")

    db_command = models.DeviceCommand(
        device_id=device_id,
        command=command.command,
        parameters=command.parameters,
        issued_by=current_user.id
    )

    db.add(db_command)
    db.commit()
    db.refresh(db_command)

    return db_command




@app.get("/api/alerts", response_model=List[schemas.AlertResponse], tags=["Alerts"])
async def get_alerts(
    room_id: int = None,
    is_read: bool = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    query = db.query(models.Alert).join(models.Room).filter(
        models.Room.user_id == current_user.id
    )

    if room_id:
        query = query.filter(models.Alert.room_id == room_id)
    if is_read is not None:
        query = query.filter(models.Alert.is_read == is_read)

    alerts = query.order_by(models.Alert.created_at.desc()).all()
    return alerts

@app.post("/api/alerts", response_model=schemas.AlertResponse, status_code=status.HTTP_201_CREATED, tags=["Alerts"])
async def create_alert(
    alert: schemas.AlertCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == alert.room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )

    db_alert = models.Alert(**alert.dict())

    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)

    return db_alert

@app.put("/api/alerts/{alert_id}/read", response_model=schemas.AlertResponse, tags=["Alerts"])
async def mark_alert_read(
    alert_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    alert = db.query(models.Alert).join(models.Room).filter(
        models.Alert.id == alert_id,
        models.Room.user_id == current_user.id
    ).first()

    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found or you don't have access")

    alert.is_read = True
    db.commit()
    db.refresh(alert)

    return alert

@app.delete("/api/alerts/{alert_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Alerts"])
async def delete_alert(
    alert_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    alert = db.query(models.Alert).join(models.Room).filter(
        models.Alert.id == alert_id,
        models.Room.user_id == current_user.id
    ).first()

    if not alert:
        raise HTTPException(
            status_code=404,
            detail="Alert not found or you don't have access"
        )

    db.delete(alert)
    db.commit()

    return None


@app.get("/api/climate-thresholds", response_model=List[schemas.ClimateThresholdResponse], tags=["Climate Thresholds"])
async def get_thresholds(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    thresholds = db.query(models.ClimateThreshold)\
        .join(models.Room)\
        .filter(models.Room.user_id == current_user.id)\
        .all()

    return thresholds


@app.get("/api/climate-thresholds/room/{room_id}", response_model=schemas.ClimateThresholdResponse, tags=["Climate Thresholds"])
async def get_room_threshold(
    room_id: int,
    db: Session = Depends(get_db)
):


    threshold = db.query(models.ClimateThreshold)\
        .filter(models.ClimateThreshold.room_id == room_id)\
        .first()

    if not threshold:
        raise HTTPException(status_code=404, detail="Threshold settings not found for this room")

    return threshold

@app.post("/api/climate-thresholds", response_model=schemas.ClimateThresholdResponse, status_code=status.HTTP_201_CREATED, tags=["Climate Thresholds"])
async def create_threshold(
    threshold: schemas.ClimateThresholdCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    room = db.query(models.Room).filter(
        models.Room.id == threshold.room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room not found or you don't have access")

    db_threshold = models.ClimateThreshold(**threshold.dict())

    db.add(db_threshold)
    db.commit()
    db.refresh(db_threshold)

    return db_threshold

@app.put("/api/climate-thresholds/{threshold_id}", response_model=schemas.ClimateThresholdResponse, tags=["Climate Thresholds"])
async def update_threshold(
    threshold_id: int,
    threshold_update: schemas.ClimateThresholdUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    threshold = db.query(models.ClimateThreshold)\
        .join(models.Room)\
        .filter(
            models.ClimateThreshold.id == threshold_id,
            models.Room.user_id == current_user.id
        ).first()

    if not threshold:
        raise HTTPException(
            status_code=404,
            detail="Threshold settings not found or you don't have access"
        )


    for key, value in threshold_update.dict(exclude_unset=True).items():
        setattr(threshold, key, value)

    db.commit()
    db.refresh(threshold)

    return threshold

@app.put("/api/climate-thresholds/room/{room_id}", response_model=schemas.ClimateThresholdResponse, tags=["Climate Thresholds"])
async def update_room_threshold(
    room_id: int,
    threshold_update: schemas.ClimateThresholdUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(
            status_code=404,
            detail="Room not found or you don't have access"
        )


    threshold = db.query(models.ClimateThreshold)\
        .filter(models.ClimateThreshold.room_id == room_id)\
        .first()

    if not threshold:
        raise HTTPException(
            status_code=404,
            detail="Threshold settings not found for this room"
        )


    for key, value in threshold_update.dict(exclude_unset=True).items():
        setattr(threshold, key, value)

    db.commit()
    db.refresh(threshold)

    return threshold

@app.delete("/api/climate-thresholds/{threshold_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Climate Thresholds"])
async def delete_threshold(
    threshold_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    threshold = db.query(models.ClimateThreshold)\
        .join(models.Room)\
        .filter(
            models.ClimateThreshold.id == threshold_id,
            models.Room.user_id == current_user.id
        ).first()

    if not threshold:
        raise HTTPException(
            status_code=404,
            detail="Threshold settings not found or you don't have access"
        )

    db.delete(threshold)
    db.commit()

    return None


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
@app.post(
    "/api/sensors/{sensor_id}/readings/process",
    response_model=SensorProcessingResponse,
    tags=["Sensors - Advanced"],
    summary="Обробити показник з повною логікою",
)
async def process_sensor_reading_advanced(
    sensor_id: int,
    reading: SensorReadingInput,
    db: Session = Depends(get_db)
):



    sensor = db.query(models.Sensor).filter(
        models.Sensor.id == sensor_id
    ).first()

    if not sensor:
        raise HTTPException(
            status_code=404,
            detail=f"Sensor with id {sensor_id} not found"
        )


    if reading.temperature is None and reading.humidity is None:
        raise HTTPException(
            status_code=400,
            detail="At least one of temperature or humidity must be provided"
        )


    result = SensorReadingProcessor.process_reading(
        db=db,
        sensor_id=sensor_id,
        temperature=reading.temperature,
        humidity=reading.humidity,
        timestamp=reading.timestamp
    )

    if not result["success"]:
        raise HTTPException(
            status_code=result.get("status_code", 400),
            detail=result.get("error", "Processing failed")
        )

    return {
        "success": result["success"],
        "reading_id": result["reading_id"],
        "is_anomaly": result["is_anomaly"],
        "commands_executed": result["commands_executed"],
        "alerts_created": result["alerts_created"],
        "threshold_check": result["threshold_check"],
        "details": {
            "sensor_id": sensor_id,
            "sensor_name": sensor.name,
            "room_id": sensor.room_id,
            "timestamp": reading.timestamp or datetime.utcnow()
        }
    }



@app.post("/api/auto-control/execute/{reading_id}", tags=["Auto Control"])
async def execute_auto_control(
    reading_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    result = AutoControlFlow.execute_auto_control(
        db=db,
        sensor_reading_id=reading_id
    )

    return result


@app.get("/api/auto-control/status/{room_id}", tags=["Auto Control"])
async def get_auto_control_status(
    room_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    room = db.query(models.Room).filter(
        models.Room.id == room_id,
        models.Room.user_id == current_user.id
    ).first()

    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    threshold = db.query(models.ClimateThreshold).filter(
        models.ClimateThreshold.room_id == room_id
    ).first()

    if not threshold:
        return {
            "room_id": room_id,
            "auto_control_enabled": False,
            "message": "Thresholds not configured"
        }

    return {
        "room_id": room_id,
        "auto_control_enabled": threshold.auto_control_enabled,
        "thresholds": {
            "temperature": {
                "min": threshold.min_temperature,
                "max": threshold.max_temperature
            },
            "humidity": {
                "min": threshold.min_humidity,
                "max": threshold.max_humidity
            }
        }
    }




@app.get("/api/analytics/cached", tags=["Analytics"])
async def get_cached_analytics(
    room_id: Optional[int] = None,
    period_days: int = 7,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    if room_id:
        room = db.query(models.Room).filter(
            models.Room.id == room_id,
            models.Room.user_id == current_user.id
        ).first()

        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

    result = AnalyticsService.get_analytics(
        db=db,
        room_id=room_id,
        period_days=period_days
    )

    if not result["success"]:
        raise HTTPException(
            status_code=result.get("status_code", 404),
            detail=result.get("error", "No data available")
        )

    return result


@app.post("/api/analytics/report", tags=["Analytics"])
async def generate_analytics_report(
    room_id: Optional[int] = None,
    period_hours: Optional[int] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):



    if room_id:
        room = db.query(models.Room).filter(
            models.Room.id == room_id,
            models.Room.user_id == current_user.id
        ).first()

        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

    result = AnalyticsReportFlow.generate_report(
        db=db,
        room_id=room_id,
        start_date=start_date,
        end_date=end_date,
        period_hours=period_hours
    )

    if not result["success"]:
        raise HTTPException(
            status_code=404,
            detail=result.get("error", "Cannot generate report")
        )

    return result




@app.post("/api/admin/users/manage", tags=["Admin - Users"])
async def manage_user_admin(
    operation: str,
    user_data: Optional[Dict] = None,
    target_user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    result = UserManagementFlow.manage_user(
        db=db,
        admin_user_id=current_user.id,
        operation=operation,
        user_data=user_data,
        target_user_id=target_user_id
    )

    if not result["success"]:
        status_code = 403 if result.get("status") == "unauthorized" else 400
        raise HTTPException(
            status_code=status_code,
            detail=result.get("error", "Operation failed")
        )

    return result


@app.get("/api/admin/users/list", tags=["Admin - Users"])
async def list_all_users(
    skip: int = 0,
    limit: int = 100,
    is_active: Optional[bool] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can access this endpoint"
        )

    query = db.query(models.User)

    if is_active is not None:
        query = query.filter(models.User.is_active == is_active)

    users = query.offset(skip).limit(limit).all()

    return {
        "total": len(users),
        "users": [
            {
                "id": u.id,
                "username": u.username,
                "email": u.email,
                "is_active": u.is_active,
                "is_admin": u.is_admin,
                "created_at": u.created_at.isoformat()
            }
            for u in users
        ]
    }


@app.get("/api/admin/system/logs", tags=["Admin - System"])
async def get_system_logs(
    limit: int = 100,
    skip: int = 0,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Only administrators can access logs")

    from admin import SystemLogging

    logs = SystemLogging.get_system_logs(db, limit=limit, offset=skip)
    return {"logs": logs}


@app.get("/api/admin/statistics", tags=["Admin - System"])
async def get_admin_statistics(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can access this endpoint"
        )

    from admin import DataManagement, UserManagement

    system_stats = DataManagement.get_system_statistics(db)
    user_stats = UserManagement.get_user_statistics(db)

    return {
        "system": system_stats,
        "users": user_stats,
        "timestamp": datetime.utcnow().isoformat()
    }




@app.get("/api/export/sensor-data/csv", tags=["Data Export"])
async def export_sensor_data_csv(
    room_id: Optional[int] = None,
    sensor_id: Optional[int] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    from admin import DataExport
    from fastapi.responses import Response


    if room_id:
        room = db.query(models.Room).filter(
            models.Room.id == room_id,
            models.Room.user_id == current_user.id
        ).first()

        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

    csv_data = DataExport.export_sensor_data_to_csv(
        db=db,
        room_id=room_id,
        sensor_id=sensor_id,
        start_date=start_date,
        end_date=end_date
    )

    if not csv_data or csv_data == "":
        raise HTTPException(
            status_code=404,
            detail="No data found for export"
        )

    filename = f"sensor_data_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.csv"

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"'
        }
    )


@app.get("/api/export/configuration", tags=["Data Export"])
async def export_system_configuration(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    from admin import DataExport

    config = DataExport.export_system_configuration(db)

    return config


@app.post("/api/import/configuration", tags=["Data Import"])
async def import_system_configuration(
    config_data: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Only administrators can import configuration")
    from admin import DataImport

    result = DataImport.import_system_configuration(db, current_user.id, config_data)
    return result




@app.post("/api/admin/cleanup", tags=["Admin - System"])
async def cleanup_old_data(
    days_to_keep: int = 90,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):


    if not current_user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="Only administrators can perform cleanup"
        )

    from admin import DataManagement

    result = DataManagement.cleanup_old_data(db, days_to_keep)

    return result




@app.get("/api/test/business-logic", tags=["Testing"])
async def test_business_logic():


    return {
        "status": "ok",
        "message": "Enhanced business logic is loaded",
        "available_modules": [
            "SensorReadingProcessor",
            "AnalyticsService",
            "AutoControlFlow",
            "DataValidationFlow",
            "UserManagementFlow",
            "AnalyticsReportFlow"
        ],
        "endpoints": {
            "sensor_processing": "/api/sensors/{sensor_id}/readings/process",
            "validation": "/api/sensors/{sensor_id}/readings/validate",
            "auto_control": "/api/auto-control/execute/{reading_id}",
            "analytics": "/api/analytics/cached",
            "report": "/api/analytics/report",
            "admin": "/api/admin/users/manage",
            "export": "/api/export/sensor-data/csv"
        }
    }