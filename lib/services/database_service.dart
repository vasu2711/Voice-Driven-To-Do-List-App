import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static SharedPreferences? _prefs;
  static const String _todosKey = 'todos';

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // For web platform, we'll use SharedPreferences
      // Return a dummy database instance for web
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (Database db, int version) async {},
      );
    } else {
      // For other platforms, use SQLite
      String path = join(await getDatabasesPath(), 'todo_database.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            '''CREATE TABLE todos(
              id TEXT PRIMARY KEY,
              title TEXT,
              isCompleted INTEGER,
              createdAt TEXT,
              completedAt TEXT,
              isSynced INTEGER
            )''',
          );
        },
      );
    }
  }

  Future<List<Todo>> getTodos() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getStringList('todos') ?? [];
      return todosJson.map((jsonStr) => Todo.fromJson(jsonDecode(jsonStr))).toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('todos');
      return List.generate(maps.length, (i) {
        return Todo(
          id: maps[i]['id'],
          title: maps[i]['title'],
          isCompleted: maps[i]['isCompleted'] == 1,
          createdAt: DateTime.parse(maps[i]['createdAt']),
          completedAt: maps[i]['completedAt'] != null ? DateTime.parse(maps[i]['completedAt']) : null,
          isSynced: maps[i]['isSynced'] == 1,
        );
      });
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = todos.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('todos', todosJson);
    } else {
      final db = await database;
      await db.delete('todos');
      for (var todo in todos) {
        await db.insert('todos', {
          'id': todo.id,
          'title': todo.title,
          'isCompleted': todo.isCompleted ? 1 : 0,
          'createdAt': todo.createdAt.toIso8601String(),
          'completedAt': todo.completedAt?.toIso8601String(),
          'isSynced': todo.isSynced ? 1 : 0,
        });
      }
    }
  }

  Future<void> insertTodo(Todo todo) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final todos = await getTodos();
      todos.add(todo);
      await prefs.setStringList(
        _todosKey,
        todos.map((t) => jsonEncode(t.toJson())).toList(),
      );
    } else {
      final db = await database;
      await db.insert(
        'todos',
        {
          'id': todo.id,
          'title': todo.title,
          'isCompleted': todo.isCompleted ? 1 : 0,
          'createdAt': todo.createdAt.toIso8601String(),
          'completedAt': todo.completedAt?.toIso8601String(),
          'isSynced': todo.isSynced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateTodo(Todo todo) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final todos = await getTodos();
      final index = todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        todos[index] = todo;
        await prefs.setStringList(
          _todosKey,
          todos.map((t) => jsonEncode(t.toJson())).toList(),
        );
      }
    } else {
      final db = await database;
      await db.update(
        'todos',
        {
          'title': todo.title,
          'isCompleted': todo.isCompleted ? 1 : 0,
          'completedAt': todo.completedAt?.toIso8601String(),
          'isSynced': todo.isSynced ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [todo.id],
      );
    }
  }

  Future<void> deleteTodo(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final todos = await getTodos();
      todos.removeWhere((t) => t.id == id);
      await prefs.setStringList(
        _todosKey,
        todos.map((t) => jsonEncode(t.toJson())).toList(),
      );
    } else {
      final db = await database;
      await db.delete(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<Todo>> getUnsyncedTodos() async {
    if (kIsWeb) {
      return []; // Web platform doesn't support sync status
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'todos',
        where: 'isSynced = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) {
        return Todo(
          id: maps[i]['id'],
          title: maps[i]['title'],
          isCompleted: maps[i]['isCompleted'] == 1,
          createdAt: DateTime.parse(maps[i]['createdAt']),
          completedAt: maps[i]['completedAt'] != null ? DateTime.parse(maps[i]['completedAt']) : null,
          isSynced: maps[i]['isSynced'] == 1,
        );
      });
    }
  }

  Future<void> markAsSynced(String id) async {
    if (kIsWeb) {
      // Web platform doesn't support sync status
      return;
    } else {
      final db = await database;
      await db.update(
        'todos',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
} 