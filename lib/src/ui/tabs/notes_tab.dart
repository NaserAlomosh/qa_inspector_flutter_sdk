import 'package:flutter/material.dart';

import '../../core/qa_inspector_controller.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({required this.controller, super.key});
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
    if (_controller.text != widget.controller.notes) _controller.value = TextEditingValue(text: widget.controller.notes, selection: TextSelection.collapsed(offset: widget.controller.notes.length));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Text('Reproduction Notes', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text('Add steps, expected behavior, or anything developers should know.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
      const SizedBox(height: 14),
      TextField(
        key: const Key('qa-notes-field'), controller: _controller, minLines: 9, maxLines: null,
        maxLength: QaInspectorController.maxNotesLength, onChanged: (value) { widget.controller.updateNotes(value); setState(() {}); },
        decoration: const InputDecoration(hintText: '1. Open…\n2. Tap…\nExpected…', alignLabelWithHint: true),
      ),
    ]));
  }
}
