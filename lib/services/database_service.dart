import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sms_message.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tuguardian.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE sms_messages (
        id $idType,
        sender $textType,
        message $textType,
        timestamp $intType,
        riskScore $intType,
        isQuarantined $intType,
        suspiciousElements $textType,
        isDemo $intType
      )
    ''');

    print('✅ Base de datos creada');
  }

  Future<void> insertMessage(SMSMessage message) async {
    final db = await database;
    await db.insert(
      'sms_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SMSMessage>> getAllMessages() async {
    final db = await database;
    final maps = await db.query(
      'sms_messages',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => SMSMessage.fromMap(map)).toList();
  }

  Future<List<SMSMessage>> getRealMessages() async {
    final db = await database;
    final maps = await db.query(
      'sms_messages',
      where: 'isDemo = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => SMSMessage.fromMap(map)).toList();
  }

  Future<List<SMSMessage>> getDemoMessages() async {
    final db = await database;
    final maps = await db.query(
      'sms_messages',
      where: 'isDemo = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => SMSMessage.fromMap(map)).toList();
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cleanOldRealMessages() async {
    final db = await database;
    
    final maps = await db.query(
      'sms_messages',
      where: 'isDemo = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    if (maps.length > 200) {
      final toDelete = maps.skip(200);
      for (var msg in toDelete) {
        await db.delete(
          'sms_messages',
          where: 'id = ?',
          whereArgs: [msg['id']],
        );
      }
      print('🗑️ Limpiados ${toDelete.length} SMS antiguos');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}