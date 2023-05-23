import 'package:flutter/material.dart';
import 'package:enotes/views/create.dart';
import 'package:enotes/views/about.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  List<String> _notes = [];
  final Logger logger = Logger();
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    logger.d('Initializing home screen');
    _loadNotesFromDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNoteListEmpty = _notes.isEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('eNotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshNotes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: isNoteListEmpty ? null : _deleteAllNotes,
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const About()),
              );
            },
          ),
        ],
      ),
      body: _buildNoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Create(refreshHomeScreen: _refreshNotes),
            ),
          ).then((_) {
            _refreshNotes();
          });
        },
        backgroundColor: const Color(0xFFCC4F4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteList() {
    return _notes.isEmpty
        ? const Center(
            child: Text(
              'No note entries',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Dismissible(
                key: Key(note),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Note'),
                        content: const Text(
                            'Are you sure you want to delete this note?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _delete(note);
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted'),
                    ),
                  );
                },
                child: ListTile(
                  title: Text(note),
                  leading: const Icon(Icons.note_alt_rounded),
                ),
              );
            },
          );
  }

  Future<void> _loadNotesFromDirectory() async {
    try {
      final externalPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOCUMENTS);
      final notesDir = Directory('$externalPath/eNotes/Notes');
      logger.d('Notes directory: $notesDir');
      if (!notesDir.existsSync()) {
        notesDir.createSync(recursive: true);
      }

      final noteFiles = notesDir
          .listSync()
          .where((file) => file.path.endsWith('.txt'))
          .toList();

      setState(() {
        _notes = noteFiles
            .map((noteFile) => File(noteFile.path).readAsStringSync())
            .toList();
      });

      logger.d('Loaded notes: $_notes');
    } catch (e) {
      logger.d('Error loading notes: $e');
    }
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _refreshing = true;
    });

    await _loadNotesFromDirectory();

    setState(() {
      _refreshing = false;
    });
  }

  void _delete(String note) {
    setState(() {
      _notes.remove(note);
    });

    final externalPath = ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS);
    final notesDir = Directory('$externalPath/eNotes/Notes');
    final noteFile = File('${notesDir.path}/$note.txt');

    if (!notesDir.existsSync()) {
      logger.d('Notes directory does not exist');
      return;
    }

    try {
      if (noteFile.existsSync()) {
        noteFile.deleteSync(recursive: true);
      }
    } catch (e) {
      logger.e('Error deleting file: $e');
    }
  }

  void _deleteAllNotes() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notes'),
          content: const Text('Are you sure you want to delete all notes?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllNotesConfirmed();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllNotesConfirmed() async {
    setState(() {
      _notes.clear();
    });

    final externalPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS);
    final notesDir = Directory('$externalPath/eNotes/Notes');

    if (!notesDir.existsSync()) {
      logger.d('Notes directory does not exist');
      return;
    }

    try {
      notesDir.deleteSync(recursive: true);
      notesDir.createSync(recursive: true);
    } catch (e) {
      logger.e('Error deleting notes: $e');
    }
  }
}
