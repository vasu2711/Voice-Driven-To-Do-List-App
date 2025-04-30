import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../services/voice_service.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);
    final voiceService = ref.read(voiceServiceProvider);
    
    await voiceService.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          ref.read(todosProvider.notifier).addTodo(text);
        }
        setState(() => _isListening = false);
      },
      onError: () {
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _stopListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.stopListening();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final voiceService = ref.watch(voiceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Todo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type or speak a task...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        ref.read(todosProvider.notifier).addTodo(text);
                        _textController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          ref.read(todosProvider.notifier).deleteTodo(todo.id);
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) {
                        ref.read(todosProvider.notifier).toggleTodo(todo.id);
                      },
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Created: ${todo.createdAt.toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(todosProvider.notifier).syncTodos();
        },
        child: const Icon(Icons.sync),
      ),
    );
  }
} 