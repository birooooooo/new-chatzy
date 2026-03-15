from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str 

class UserLogin(BaseModel):
    login_input: str 
    password: str

class User(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True 

class MessageBase(BaseModel):
    content: str
    chat_id: str

class MessageCreate(MessageBase):
    id: str # The frontend usually generates the UUID for optimistic UI
    sender_id: int

class Message(MessageBase):
    id: str
    sender_id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class ChatBase(BaseModel):
    name: str
    type: int

class ChatCreate(ChatBase):
    id: str
    participant_ids: List[int]

class Chat(ChatBase):
    id: str
    created_at: datetime
    participants: List[User] = []
    messages: List[Message] = []

    class Config:
        from_attributes = True
