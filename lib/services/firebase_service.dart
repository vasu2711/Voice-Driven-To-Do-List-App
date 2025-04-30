import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'todos';

  Future<void> syncTodo(Todo todo) async {
    try {
      await _firestore.collection(_collection).doc(todo.id).set(todo.toJson());
    } catch (e) {
      print('Error syncing todo: $e');
      rethrow;
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting todo: $e');
      rethrow;
    }
  }

  Stream<List<Todo>> getTodosStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Todo.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> syncAllTodos(List<Todo> todos) async {
    final batch = _firestore.batch();
    
    for (final todo in todos) {
      final docRef = _firestore.collection(_collection).doc(todo.id);
      batch.set(docRef, todo.toJson());
    }
    
    try {
      await batch.commit();
    } catch (e) {
      print('Error syncing todos: $e');
      rethrow;
    }
  }
} 