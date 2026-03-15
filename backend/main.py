import logging
import json
from typing import Dict
from fastapi import FastAPI, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import exc, text

import models, schemas
from database import engine, get_db, SessionLocal

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create database tables
# In production, use migrations (Alembic) instead of this naive approach
logger.info("Creating database tables...")
try:
    models.Base.metadata.create_all(bind=engine)
except Exception as e:
    logger.warning(f"Could not create database tables (DB might not be connected yet): {e}")

app = FastAPI(title="Chitzy0 API")

# Configure CORS so the Flutter app can communicate with the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Chitzy0 API!"}

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

@app.post("/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user_email = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    db_user_username = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user_username:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/login", response_model=schemas.User)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    # Check if login_input is email or username
    login_input = user_credentials.login_input
    if "@" in login_input:
        user = db.query(models.User).filter(models.User.email == login_input).first()
    else:
        user = db.query(models.User).filter(models.User.username == login_input).first()
        
    if not user:
        raise HTTPException(status_code=403, detail="Invalid Credentials")
    
    if not verify_password(user_credentials.password, user.hashed_password):
        raise HTTPException(status_code=403, detail="Invalid Credentials")
        
    return user

@app.get("/users/search", response_model=list[schemas.User])
def search_users(query: str, db: Session = Depends(get_db)):
    users = db.query(models.User).filter(
        (models.User.username.ilike(f"%{query}%")) | 
        (models.User.email.ilike(f"%{query}%"))
    ).limit(50).all()
    return users

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_personal_message(self, message: str, client_id: str):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/chat/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                # Payload requires: id, chat_id, content, receiver_id (optional for 1-1 realtime)
                msg_content = payload.get("content")
                chat_id = payload.get("chat_id")
                receiver_id = payload.get("receiver_id")
                
                db = SessionLocal()
                try:
                    # Upsert the chat to prevent Foreign Key constraint errors 
                    # since Flutter generates the chat ID locally for optimistic UI
                    chat = db.query(models.Chat).filter(models.Chat.id == chat_id).first()
                    if not chat:
                        new_chat = models.Chat(id=chat_id, name="Chat", type=0) # 0 for private
                        db.add(new_chat)
                        db.commit()

                    new_msg = models.Message(
                        id=payload.get("id"),
                        chat_id=chat_id,
                        sender_id=int(client_id),
                        content=msg_content
                    )
                    db.add(new_msg)
                    db.commit()
                    db.refresh(new_msg)
                    
                    response_payload = {
                        "id": new_msg.id,
                        "chatId": new_msg.chat_id,
                        "senderId": str(new_msg.sender_id),
                        "content": new_msg.content,
                        "timestamp": new_msg.timestamp.isoformat()
                    }
                    response_str = json.dumps(response_payload)
                finally:
                    db.close()
                
                # Send the confirmed saved message back to sender 
                await manager.send_personal_message(response_str, client_id)
                # Route it to the receiver instantly if they are online
                if receiver_id and str(receiver_id) != client_id:
                    await manager.send_personal_message(response_str, str(receiver_id))
                    
            except Exception as e:
                logger.error(f"Error processing message from {client_id}: {e}")
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)

@app.get("/health")
def health_check():
    # Simple HTTP check for Railway to verify the web server is running.
    # We do not strictly check the DB here to avoid deployment failures
    # if the user hasn't provisioned a PostgreSQL database yet.
    return {"status": "ok", "message": "FastAPI is running"}

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.getenv("PORT", 8080))
    logger.info(f"Starting Uvicorn server on port {port}...")
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info")
