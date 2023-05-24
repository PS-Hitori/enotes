import 'package:flutter/material.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:enotes/theme_handler.dart';
import 'package:permission_handler/permission_handler.dart';

class Create extends StatefulWidget {
  final String? note;
  final VoidCallback refreshHomeScreen;
  const Create({Key? key, this.note, required this.refreshHomeScreen})
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
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Create Note', style: TextStyle(fontFamily: 'Roboto')),
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontFamily: 'Roboto',
                  ),
              decoration: const InputDecoration(
                  hintText: 'Enter note title',
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCC4F4F)))),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  controller: _noteController,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontFamily: 'Roboto',
                      ),
                  maxLines: null,
                  decoration: const InputDecoration(
                      hintText: 'Enter note description',
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCC4F4F)))),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () =>
                  _checkAndSaveNote(context, widget.refreshHomeScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC4F4F),
              ),
              child: const Text(
                'Save Note',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndSaveNote(
      BuildContext context, RefreshCallback refreshHomeScreen) async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      final note = _noteController.text.trim();
      if (note.isNotEmpty) {
        _writeNoteToFile(note);
        refreshHomeScreen();
        Navigator.pop(context);
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

  Future<void> _writeNoteToFile(String note) async {
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );
    final notesDirectory = Directory('$directory/eNotes/Notes');
    if (!await notesDirectory.exists()) {
      await notesDirectory.create(recursive: true);
    }

    final title = _titleController.text.trim();
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
}
