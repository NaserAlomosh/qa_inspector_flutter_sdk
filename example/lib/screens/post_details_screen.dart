import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/example_api.dart';
import '../widgets/error_state.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({required this.api, required this.post, super.key});

  final ExampleApi api;
  final ExamplePost post;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  List<ExampleComment>? _comments;
  String? _error;
  bool _runningParallel = false;
  bool _triggeringFailure = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _comments = null;
      _error = null;
    });
    try {
      final comments = await widget.api.getComments(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _error = error.response?.statusCode == null
            ? 'Could not load comments. Check your connection and try again.'
            : 'Could not load comments (HTTP ${error.response!.statusCode}).');
      }
    }
  }

  Future<void> _runParallelRequests() async {
    setState(() => _runningParallel = true);
    try {
      await widget.api.runParallelRequests();
      if (mounted) _showMessage('3 parallel APIs completed');
    } on DioException catch (error) {
      if (mounted) {
        _showMessage(
          'Parallel APIs failed${error.response?.statusCode == null ? '' : ' · HTTP ${error.response!.statusCode}'}',
        );
      }
    } finally {
      if (mounted) setState(() => _runningParallel = false);
    }
  }

  Future<void> _trigger404() async {
    setState(() => _triggeringFailure = true);
    try {
      await widget.api.triggerNotFound();
      if (mounted) _showMessage('Unexpected success from nonexistent resource');
    } on DioException catch (error) {
      if (mounted) {
        final status = error.response?.statusCode;
        _showMessage(
          status == null
              ? 'Failure captured · no HTTP response'
              : 'Expected failure captured · HTTP $status',
        );
      }
    } finally {
      if (mounted) setState(() => _triggeringFailure = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post ${widget.post.id} · Details')),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.post.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed:
                            _runningParallel ? null : _runParallelRequests,
                        icon: const Icon(Icons.call_split),
                        label: const Text('Run 3 parallel APIs'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _triggeringFailure ? null : _trigger404,
                        icon: const Icon(Icons.error_outline),
                        label: const Text('Trigger 404'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Comments', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ),
          if (_error case final String error)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(message: error, onRetry: _loadComments),
            )
          else if (_comments case final List<ExampleComment> comments)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: SliverList.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Card(
                    child: ListTile(
                      title: Text(comment.name),
                      subtitle: Text(comment.body),
                    ),
                  );
                },
              ),
            )
          else
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
