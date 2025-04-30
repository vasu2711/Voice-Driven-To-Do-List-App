import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../services/voice_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) => VoiceService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

class TodoNotifier extends StateNotifier<List<Todo>> {
  final DatabaseService _databaseService;
  final FirebaseService _firebaseService;
  final VoiceService _voiceService;

  TodoNotifier(
    this._databaseService,
    this._firebaseService,
    this._voiceService,
  ) : super([]) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _databaseService.getTodos();
    state = todos;
  }

  Future<void> addTodo(String title) async {
    final todo = Todo(title: title);
    await _databaseService.insertTodo(todo);
    state = [...state, todo];
    
    try {
      await _firebaseService.syncTodo(todo);
      await _databaseService.markAsSynced(todo.id);
      await _voiceService.speak('Task added: $title');
    } catch (e) {
      print('Error syncing todo: $e');
    }
  }

  Future<void> toggleTodo(String id) async {
    final todo = state.firstWhere((t) => t.id == id);
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );
    
    await _databaseService.updateTodo(updatedTodo);
    state = state.map((t) => t.id == id ? updatedTodo : t).toList();
    
    try {
      await _firebaseService.syncTodo(updatedTodo);
      await _databaseService.markAsSynced(updatedTodo.id);
      await _voiceService.speak(
        updatedTodo.isCompleted ? 'Task completed: ${updatedTodo.title}' : 'Task reopened: ${updatedTodo.title}'
      );
    } catch (e) {
      print('Error syncing todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    await _databaseService.deleteTodo(id);
    state = state.where((t) => t.id != id).toList();
    
    try {
      await _firebaseService.deleteTodo(id);
    } catch (e) {
      print('Error deleting todo: $e');
    }
  }

  Future<void> syncTodos() async {
    try {
      // First, push any unsynced local changes to Firebase
      final unsyncedTodos = await _databaseService.getUnsyncedTodos();
      if (unsyncedTodos.isNotEmpty) {
        await _firebaseService.syncAllTodos(unsyncedTodos);
        for (final todo in unsyncedTodos) {
          await _databaseService.markAsSynced(todo.id);
        }
      }

      // Then, fetch all todos from Firebase
      final firebaseTodos = await _firebaseService.getTodos();
      
      // Get current local todos
      final localTodos = await _databaseService.getTodos();
      
      // Create a map of local todos for easy lookup
      final localTodoMap = {for (var todo in localTodos) todo.id: todo};
      
      // Merge Firebase todos with local todos
      for (final firebaseTodo in firebaseTodos) {
        if (!localTodoMap.containsKey(firebaseTodo.id)) {
          // If the todo doesn't exist locally, add it
          await _databaseService.insertTodo(firebaseTodo);
        } else {
          // If the todo exists locally, update it if the Firebase version is newer
          final localTodo = localTodoMap[firebaseTodo.id]!;
          if (firebaseTodo.createdAt.isAfter(localTodo.createdAt)) {
            await _databaseService.updateTodo(firebaseTodo);
          }
        }
      }
      
      // Update the state with the merged todos
      final mergedTodos = await _databaseService.getTodos();
      state = mergedTodos;
      
      await _voiceService.speak('Sync completed');
    } catch (e) {
      print('Error syncing todos: $e');
      await _voiceService.speak('Sync failed');
    }
  }
}

final todosProvider = StateNotifierProvider<TodoNotifier, List<Todo>>((ref) {
  return TodoNotifier(
    ref.watch(databaseServiceProvider),
    ref.watch(firebaseServiceProvider),
    ref.watch(voiceServiceProvider),
  );
}); 