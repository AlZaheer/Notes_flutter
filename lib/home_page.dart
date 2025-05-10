import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/note_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> notes = [];
  String selectedCategory = 'Work';

  final List<Color> noteColors = [
    Colors.red.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.purple.shade100,
    Colors.orange.shade100,
    Colors.teal.shade100,
  ];

  final List<String> categories = ['Work', 'Personal', 'Food', 'Bills', 'Other'];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Color getRandomNoteColor() {
    return noteColors[DateTime.now().millisecondsSinceEpoch % noteColors.length];
  }

  Future<void> fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .get();

    final fetchedNotes = snapshot.docs.map((doc) {
      final data = doc.data();
      final colorValue = data['color'];
      int colorInt = 0;
      if (colorValue is int) {
        colorInt = colorValue;
      } else if (colorValue is String) {
        colorInt = int.tryParse(colorValue) ?? 0;
      }
      return Note(
        id: doc.id,
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        color: Color(colorInt),
        category: data['category'] ?? 'Other',
      );
    }).toList();

    setState(() {
      notes = fetchedNotes;
    });
  }

  Future<void> addNote(String title, String content, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newNote = {
      'title': title,
      'content': content,
      'timestamp': DateTime.now(),
      'color': getRandomNoteColor().toARGB32(),
      'category': category,
    };

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .add(newNote);

    setState(() {
      notes.insert(
        0,
        Note(
          id: docRef.id,
          title: title,
          content: content,
          timestamp: DateTime.now(),
          color: Color(newNote['color'] as int),
          category: category,
        ),
      );
    });
  }

  Future<void> deleteNote(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(id)
        .delete();

    setState(() {
      notes.removeWhere((note) => note.id == id);
    });
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String localCategory = selectedCategory;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Note"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              DropdownButtonFormField<String>(
                value: localCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) localCategory = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty ||
                  contentController.text.isNotEmpty) {
                addNote(titleController.text, contentController.text, localCategory);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in both fields")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: notes.isEmpty
            ? const Center(child: Text("No notes yet"))
            : MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Dismissible(
                    key: Key(note.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      deleteNote(note.id);
                    },
                    child: Card(
                      color: note.color,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(note.category,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Text(note.content),
                            const SizedBox(height: 12),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(note.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
