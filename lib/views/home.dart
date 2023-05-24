import 'package:flutter/material.dart';
import 'package:enotes/views/create.dart';
import 'package:enotes/views/about.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:enotes/theme_handler.dart';

class Note {
  final String title;
  final String description;

  @override
  String toString() {
    return 'Note{title: $title, description: $description}';
  }

  Note({
    required this.title,
    required this.description,
  });
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final Logger logger = Logger();
  bool _refreshing = false;
  bool _isDarkMode = false;
  String _searchTerm = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    logger.d('Initializing home screen');
    _loadNotesFromDirectory();
    _loadDarkMode();
    ThemeHandler.getThemeData();
  }

  Future<void> _loadDarkMode() async {
    final isDarkMode = await ThemeHandler.getDarkMode();
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: null,
          elevation: 0.0,
          actions: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextField(
                    focusNode: _searchFocusNode,
                    onChanged: (value) => _filterNotes(value),
                    autofocus: false,
                    cursorColor: const Color(0xFFCC4F4F),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                          fontFamily: 'Roboto',
                        ),
                    decoration: InputDecoration(
                      hintText: 'Search your notes',
                      filled: false,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.0),
                        borderSide: const BorderSide(color: Color(0xFFCC4F4F)),
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFFCC4F4F)),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  final newMode = !_isDarkMode;
                  ThemeHandler.toggleDarkMode(newMode);
                  setState(() {
                    _isDarkMode = newMode;
                  });
                },
              ),
            ),
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'remove_all') {
                  _showDeleteAllConfirmation();
                } else if (value == 'about') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const About()),
                  );
                } else if (value == 'refresh') {
                  _refreshNotes();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: const Text('Refresh'),
                  ),
                ),
                PopupMenuItem(
                  value: 'remove_all',
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: const Text('Remove All'),
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: const Text('About'),
                  ),
                ),
              ],
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
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    return _notes.isEmpty
        ? const Center(
            child: Text(
              'No note entries',
              style: TextStyle(fontSize: 18, fontFamily: 'Roboto'),
            ),
          )
        : ListView.builder(
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return Dismissible(
                key: Key(note.title),
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
                        title: const Text('Delete Note',
                            style: TextStyle(fontFamily: 'Roboto')),
                        content: Text(
                            'Are you sure you want to delete this note?',
                            style: TextStyle(
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                                fontFamily: 'Roboto')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFCC4F4F)),
                            child: const Text('Cancel',
                                style: TextStyle(fontFamily: 'Roboto')),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteNote(note.title);
                              Navigator.of(context).pop(true);
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFCC4F4F)),
                            child: const Text('Delete',
                                style: TextStyle(fontFamily: 'Roboto')),
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
                child: Card(
                  elevation: 0.0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        note.title,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontFamily: 'Roboto',
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(note.description,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontFamily: 'Roboto',
                            fontSize: 14.0,
                          )),
                    ),
                  ),
                ),
              );
            },
          );
  }

  void _filterNotes(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      if (_searchTerm.isEmpty) {
        _filteredNotes = List.from(_notes);
      } else {
        _filteredNotes = _notes.where((note) {
          final titleMatch =
              note.title.toLowerCase().contains(_searchTerm.toLowerCase());
          final descriptionMatch = note.description
              .toLowerCase()
              .contains(_searchTerm.toLowerCase());
          return titleMatch || descriptionMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadNotesFromDirectory() async {
    try {
      final externalPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS,
      );
      final notesDir = Directory('$externalPath/eNotes/Notes');
      logger.d('Notes directory: $notesDir');
      if (!notesDir.existsSync()) {
        notesDir.createSync(recursive: true);
      }

      final noteFiles = notesDir
          .listSync()
          .where((file) => file.path.endsWith('.txt'))
          .toList();

      final List<Note> loadedNotes = [];
      for (final noteFile in noteFiles) {
        final notePath = noteFile.path;
        final noteTitle = path.basenameWithoutExtension(notePath);
        final noteContent = File(notePath).readAsStringSync();
        final noteDescription = _extractDescriptionFromContent(noteContent);
        loadedNotes.add(Note(
          title: noteTitle,
          description: noteDescription,
        ));
      }

      setState(() {
        _notes = loadedNotes;
        _filteredNotes = loadedNotes;
      });

      logger.d('Loaded notes: $_notes');
    } catch (e) {
      logger.d('Error loading notes: $e');
    }
  }

  String _extractDescriptionFromContent(String content) {
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      return lines.first.trim();
    }
    return '';
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

  void _deleteNote(String noteTitle) async {
    setState(() {
      _notes.removeWhere((note) => note.title == noteTitle);
      _filteredNotes.removeWhere((note) => note.title == noteTitle);
    });

    try {
      final externalPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS,
      );

      final noteFile = File('$externalPath/eNotes/Notes/$noteTitle.txt');

      if (noteFile.existsSync()) {
        noteFile.deleteSync();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
          ),
        );
        logger.d('Note deleted: $noteTitle');
      } else {
        logger.d('Note file does not exist: $noteTitle');
      }
    } catch (e) {
      logger.e('Error deleting note: $e');
    }
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove All Notes'),
          content: Text('Are you sure you want to remove all notes?',
              style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'Roboto')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCC4F4F),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAllNotes();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCC4F4F),
              ),
              child: const Text('Remove All'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllNotes() async {
    final externalPath = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );

    final notesDir = Directory('$externalPath/eNotes/Notes');

    if (notesDir.existsSync()) {
      final noteFiles = notesDir
          .listSync()
          .where((file) => file.path.endsWith('.txt'))
          .toList();

      if (noteFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The directory is empty, nothing to remove.'),
          ),
        );
        return;
      }

      for (final file in noteFiles) {
        file.deleteSync();
        logger.d('All notes removed');
      }
    }

    setState(() {
      _notes.clear();
      _filteredNotes.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notes removed.')),
      );
    });
  }
}
