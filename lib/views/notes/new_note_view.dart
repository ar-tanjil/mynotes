import 'package:flutter/material.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Note",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shadowColor: Colors.black,
        elevation: 10,
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
      ),
      body: const Text("New Note View"),
    );
  }
}
