import 'package:flutter/material.dart';
import 'package:enotes/views/create.dart';
import 'package:enotes/views/about.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:enotes/theme_handler.dart';
import 'package:enotes/views/manage.dart';

class Note {
  String title;
  String description;
  final DateTime creationTime;

  @override
  String toString() {
    return 'Note{title: $title, description: $description}';
  }

  Note({
    required this.title,
    required this.description,
    required this.creationTime,
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
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'remove_all') {
                  _showDeleteAllConfirmation();
                } else if (value == 'about') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const About()),
                  );
                } else if (value == 'theme') {
                  _showDarkModeDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'theme',
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: const Text('Theme'),
                  ),
                ),
                PopupMenuItem(
                  value: 'remove_all',
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    child: const Text('Empty Notes'),
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
          onPressed: _showCreateNotePopup,
          backgroundColor: const Color(0xFFCC4F4F),
          shape: const CircleBorder(),
          child: const Icon(Icons.create, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    return _notes.isEmpty
        ? Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note_outlined,
                  size: 48, color: _isDarkMode ? Colors.white : Colors.black),
              const SizedBox(height: 10),
              Text('No notes found',
                  style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white : Colors.black))
            ],
          ))
        : ListView.builder(
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return Dismissible(
                key: Key(note.title),
                direction: DismissDirection.horizontal,
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  color: _isDarkMode ? Colors.green : Colors.green[100],
                  child: Icon(
                    Icons.edit,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                secondaryBackground: Container(
                  color: _isDarkMode ? Colors.red : Colors.red[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(
                    Icons.delete,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    openManageNoteDialog(note);
                    return false; // Do not dismiss
                  } else if (direction == DismissDirection.endToStart) {
                    // Delete action
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
                  }
                  return false; // Default: Do not dismiss
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note deleted'),
                      ),
                    );
                  }
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
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(note.description,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
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

        final FileStat noteStat = noteFile.statSync();
        final noteCreationTime = noteStat.changed;

        loadedNotes.add(Note(
          title: noteTitle,
          description: noteDescription,
          creationTime: noteCreationTime,
        ));

        int compareByCreationTime(Note note1, Note note2) {
          return note2.creationTime.compareTo(note1.creationTime);
        }

        loadedNotes.sort(compareByCreationTime);
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
    const int maxDescriptionLength = 256;

    String description = content.replaceAll(RegExp(r'\n'), ' ').trim();

    if (description.length > maxDescriptionLength) {
      description = description.substring(0, maxDescriptionLength);
      final lastWordIndex = description.lastIndexOf(' ');

      if (lastWordIndex != -1) {
        description = description.substring(0, lastWordIndex);
      }

      description += '...';
    }

    return description;
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
          title: const Text('Empty Notes?'),
          content: Text(
              'All notes will be permanently deleted. This action cannot be undone.',
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

  void _showCreateNotePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Create(
          refreshNotes: _loadNotesFromDirectory,
        );
      },
    ).then((_) {
      _loadNotesFromDirectory();
    });
  }

  void _showDarkModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDarkMode = _isDarkMode;

        return AlertDialog(
          title: const Text('Theme'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Dark',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: isDarkMode,
                      onChanged: (bool? value) {
                        setState(() {
                          isDarkMode = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Light',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: isDarkMode,
                      onChanged: (bool? value) {
                        setState(() {
                          isDarkMode = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(
                    color: Color(0xFFCC4F4F),
                  )),
            ),
            TextButton(
              onPressed: () {
                ThemeHandler.toggleDarkMode(isDarkMode);
                setState(() {
                  _isDarkMode = isDarkMode;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save',
                  style: TextStyle(
                    color: Color(0xFFCC4F4F),
                  )),
            ),
          ],
        );
      },
    );
  }

  void openManageNoteDialog(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManageNoteDialog(
          note: note,
          originalDescription: note.description,
          onSave: (String title, String description) {},
          refreshNotes: () {
            _loadNotesFromDirectory();
          },
        );
      },
    ).then((_) {
      _loadNotesFromDirectory();
    });
  }
}
