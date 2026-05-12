import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/packet.dart';
import '../models/packet_model.dart';

class SqliteBuffer {
  static Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'packet_buffer.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE packets (
          id TEXT PRIMARY KEY,
          timestamp INTEGER NOT NULL,
          heartRate INTEGER NOT NULL,
          activity INTEGER NOT NULL,
          sent INTEGER NOT NULL DEFAULT 0
        )
      '''),
    );
  }

  Future<void> insert(Packet packet) async {
    final db = await _database;
    final model = packet is PacketModel
        ? packet
        : PacketModel(
            id: packet.id,
            timestamp: packet.timestamp,
            heartRate: packet.heartRate,
            activity: packet.activity,
          );
    await db.insert('packets', model.toSqlMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PacketModel>> getPending() async {
    final db = await _database;
    final rows = await db.query('packets',
        where: 'sent = ?', whereArgs: [0], orderBy: 'timestamp ASC');
    return rows.map(PacketModel.fromMap).toList();
  }

  Future<void> remove(String id) async {
    final db = await _database;
    await db.delete('packets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> pendingCount() async {
    final db = await _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM packets WHERE sent = 0');
    return result.first['cnt'] as int? ?? 0;
  }
}
