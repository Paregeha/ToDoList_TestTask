import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<void> updateTaskOrder(int id, int task_order) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      {'task_order': task_order},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateAllTaskOrder() async {
    final db = await instance.database;

    await db.rawUpdate('UPDATE tasks SET task_order = task_order + 1');
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

  Future _createDB(Database db, int version) async {
    const idType =
        'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType, -- Унікальний ідентифікатор
        task $textType, -- Текст завдання
        task_order INTEGER
      )
    ''');
  }

  Future<void> insertTask(String task, {required int taskOrder}) async {
    final db = await instance.database;

    await db.insert(
      'tasks',
      {
        'task': task,
        'task_order': taskOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await instance.database;
    return await db.query(
      'tasks',
      orderBy: 'task_order ASC',
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db
        .delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
