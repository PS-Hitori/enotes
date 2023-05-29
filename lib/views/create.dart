import 'package:flutter/material.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:enotes/theme_handler.dart';
import 'package:permission_handler/permission_handler.dart';

class Create extends StatefulWidget {
  final String? note;
  final void Function() refreshNotes;
  const Create({Key? key, this.note, required this.refreshNotes})
      : super(key: key);

  @override
  CreateState createState() => CreateState();
}

typedef RefreshCallback = void Function();

class CreateState extends State<Create> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      final noteData = widget.note!.split('\n');
      if (noteData.length >= 2) {
        _titleController.text = noteData[0];
        _noteController.text = noteData.sublist(1).join('\n');
      } else {
        _noteController.text = widget.note!;
      }
    }
    ThemeHandler.getThemeData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Note',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _titleController,
              cursorColor: const Color(0xFFCC4F4F),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle:
                    TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCC4F4F)),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  cursorColor: const Color(0xFFCC4F4F),
                  controller: _noteController,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Content',
                    hintStyle:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCC4F4F)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _checkAndSaveNote(context, widget.refreshNotes),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC4F4F),
              ),
              child: const Text(
                'Save Note',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndSaveNote(
    BuildContext context,
    RefreshCallback refreshHomeScreen,
  ) async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      final note = _noteController.text.trim();
      final title = _titleController.text.trim();
      if (note.isNotEmpty) {
        if (note.length <= 255) {
          // Add validation for note length
          if (await _isNoteTitleExists(title)) {
            _showOverwriteDialog(context, title, note);
          } else {
            _saveNoteToFile(title, note);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Description should not exceed 255 characters.',
                style: TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a note.',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        _checkAndSaveNote(context, refreshHomeScreen);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission required to save the note.',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Storage permission required to save the note.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
    }
  }

  Future<bool> _isNoteTitleExists(String title) async {
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );
    final notesDirectory = Directory('$directory/eNotes/Notes');
    if (await notesDirectory.exists()) {
      final file = File('${notesDirectory.path}/$title.txt');
      return await file.exists();
    }
    return false;
  }

  Future<void> _saveNoteToFile(String title, String note) async {
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );
    final notesDirectory = Directory('$directory/eNotes/Notes');
    if (!await notesDirectory.exists()) {
      await notesDirectory.create(recursive: true);
    }

    final fileName = '$title.txt';
    final file = File('${notesDirectory.path}/$fileName');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Note saved successfully.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
      await file.writeAsString(note);
      widget.refreshNotes();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save note.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
      Logger().e(e);
    }
  }

  void _showOverwriteDialog(BuildContext context, String title, String note) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: AlertDialog(
            title: Text(
              'Note Already Exists',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            content: Text(
              'A note with the same title already exists. Do you want to overwrite it?',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.normal,
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveNoteToFile(title, note);
                },
                child: const Text(
                  'Overwrite',
                  style: TextStyle(color: Color(0xFFCC4F4F)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFFCC4F4F)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
