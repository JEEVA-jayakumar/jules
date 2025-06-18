import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task_model.dart'; // Assuming task_model.dart is in lib

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final String tableName = 'tasks';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        creationDate INTEGER NOT NULL
      )
    ''');
  }

  // Insert a task
  Future<int> insertTask(Task task) async {
    Database db = await database;
    // Use toMap without the id, as it's autoincremented
    Map<String, dynamic> taskMap = task.toMap();
    taskMap.remove('id'); // Ensure id is not passed for autoincrement
    return await db.insert(tableName, taskMap);
  }

  // Get all tasks (for debugging or future use)
  Future<List<Task>> getAllTasks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'creationDate DESC');
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Get tasks for a specific date
  // This requires storing date in a queryable format, like start/end of day timestamps
  Future<List<Task>> getTasksForDate(DateTime date) async {
    Database db = await database;
    DateTime startDate = DateTime(date.year, date.month, date.day); // Start of the day
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999); // End of the day

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'creationDate >= ? AND creationDate <= ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'creationDate ASC',
    );
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Update a task
  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task
  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database (optional, typically not needed for app lifecycle)
  // Future<void> close() async {
  //   Database db = await database;
  //   db.close();
  // }
}
