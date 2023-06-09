import 'package:flutter/material.dart';
import 'package:enotes/views/home.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';
import 'package:logger/logger.dart';

class ManageNoteDialog extends StatefulWidget {
  final Note note;
  final String originalDescription;
  final void Function(String title, String description) onSave;
  final void Function() refreshNotes;
  const ManageNoteDialog(
      {Key? key,
      required this.note,
      required this.originalDescription,
      required this.onSave,
      required this.refreshNotes})
      : super(key: key);

  @override
  _ManageNoteDialogState createState() => _ManageNoteDialogState();
}

class _ManageNoteDialogState extends State<ManageNoteDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.note.title;
    _descriptionController.text =
        widget.originalDescription.replaceAll('<br>', '\n');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    String updatedTitle = _titleController.text.trim();
    String updatedDescription = _descriptionController.text.trim();

    if (updatedTitle.isNotEmpty && updatedDescription.isNotEmpty) {
      if (updatedDescription.length <= 255) {
        widget.onSave(updatedTitle, updatedDescription);
        _saveNoteToFile(updatedTitle, updatedDescription);
        Navigator.pop(context);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Note Validation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Description should not exceed 255 characters.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK',
                      style: TextStyle(color: Color(0xFFCC4F4F))),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Note Validation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Fields cannot be empty.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK',
                    style: TextStyle(color: Color(0xFFCC4F4F))),
              ),
            ],
          );
        },
      );
    }
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
              'Manage Note',
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
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCC4F4F)),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              cursorColor: const Color(0xFFCC4F4F),
              controller: _descriptionController,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
              maxLines: null,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCC4F4F)),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC4F4F),
              ),
              child: const Text(
                'Save Changes',
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

  void _saveNoteToFile(String title, String note) async {
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );
    final notesDirectory = Directory('$directory/eNotes/Notes');
    if (!await notesDirectory.exists()) {
      await notesDirectory.create(recursive: true);
    }

    final oldFileName = '${widget.note.title}.txt';
    final newFileName = '$title.txt';
    final oldFile = File('${notesDirectory.path}/$oldFileName');
    final newFile = File('${notesDirectory.path}/$newFileName');

    try {
      if (await newFile.exists()) {
        await oldFile.delete();
      } else {
        await oldFile.rename(newFile.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Note edited successfully.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
      await newFile.writeAsString(note);
      widget.refreshNotes();
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
