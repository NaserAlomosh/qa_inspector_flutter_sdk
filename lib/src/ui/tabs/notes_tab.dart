import 'package:flutter/material.dart';

import '../../core/qa_inspector_controller.dart';

/// Edits the notes stored for the current inspector session.
class NotesTab extends StatefulWidget {
  /// Creates the notes tab.
  const NotesTab({required this.controller, super.key});

  /// The controller that owns the session notes.
  final QaInspectorController controller;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller = TextEditingController(text: widget.controller.notes);

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(NotesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.controller.notes) {
      _controller.value = TextEditingValue(
        text: widget.controller.notes,
        selection: TextSelection.collapsed(offset: widget.controller.notes.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TextField(
        key: const Key('qa-notes-field'),
        controller: _controller,
        minLines: 8,
        maxLines: null,
        maxLength: QaInspectorController.maxNotesLength,
        onChanged: widget.controller.updateNotes,
        decoration: const InputDecoration(
          labelText: 'QA Notes',
          hintText: 'Describe the issue and steps to reproduce it…',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
