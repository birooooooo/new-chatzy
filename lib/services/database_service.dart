import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDB('chat_app.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  static Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        name TEXT,
        type INTEGER,
        avatar TEXT,
        unreadCount INTEGER,
        isPinned INTEGER,
        isMuted INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        typingUserId TEXT,
        adminIds TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT,
        senderId TEXT,
        content TEXT,
        type INTEGER,
        status INTEGER,
        timestamp TEXT,
        replyToId TEXT,
        translatedContent TEXT,
        translatedLanguage TEXT,
        aiSuggestion TEXT,
        reactions TEXT
      )
    ''');
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE chats ADD COLUMN updatedAt TEXT');
    }
  }

  // Chat Operations
  static Future<void> saveChat(ChatModel chat) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getChats() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('chats');
  }

  // Message Operations
  static Future<void> saveMessage(MessageModel message) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<MessageModel>> getMessages(String chatId) async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  static Future<void> deleteChat(String chatId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }
}
