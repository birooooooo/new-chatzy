from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Table
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

chat_participants = Table(
    'chat_participants',
    Base.metadata,
    Column('chat_id', String, ForeignKey('chats.id'), primary_key=True),
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True)
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    is_active = Column(Boolean, default=True)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    chats = relationship('Chat', secondary=chat_participants, back_populates='participants')

class Chat(Base):
    __tablename__ = "chats"

    id = Column(String, primary_key=True, index=True) # UUID string
    name = Column(String, nullable=False, default="")
    type = Column(Integer, default=0) # 0: private, 1: group
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    participants = relationship('User', secondary=chat_participants, back_populates='chats')
    messages = relationship('Message', back_populates='chat', cascade="all, delete-orphan")

class Message(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True, index=True) # UUID string
    chat_id = Column(String, ForeignKey('chats.id'), nullable=False)
    sender_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    content = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    chat = relationship('Chat', back_populates='messages')
    sender = relationship('User')
