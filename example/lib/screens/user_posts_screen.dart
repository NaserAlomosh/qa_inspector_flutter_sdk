import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/example_api.dart';
import '../widgets/error_state.dart';
import 'post_details_screen.dart';

class UserPostsScreen extends StatefulWidget {
  const UserPostsScreen({required this.api, required this.user, super.key});

  final ExampleApi api;
  final ExampleUser user;

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  List<ExamplePost>? _posts;
  String? _error;
  bool _creatingPost = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _posts = null;
      _error = null;
    });
    try {
      final posts = await widget.api.getPosts(widget.user.id);
      if (mounted) setState(() => _posts = posts);
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _error = error.response?.statusCode == null
            ? 'Could not load posts. Check your connection and try again.'
            : 'Could not load posts (HTTP ${error.response!.statusCode}).');
      }
    }
  }

  Future<void> _createPost() async {
    setState(() => _creatingPost = true);
    try {
      final id = await widget.api.createPost(widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('POST /posts succeeded · id: ${id ?? 'unknown'}')),
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'POST /posts failed${error.response?.statusCode == null ? '' : ' · HTTP ${error.response!.statusCode}'}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingPost = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.name} · Posts')),
      body: switch ((_posts, _error)) {
        (_, final String error) =>
          ErrorState(message: error, onRetry: _loadPosts),
        (final List<ExamplePost> posts, _) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      settings: RouteSettings(name: '/posts/${post.id}'),
                      builder: (_) =>
                          PostDetailsScreen(api: widget.api, post: post),
                    ),
                  ),
                ),
              );
            },
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creatingPost ? null : _createPost,
        icon: _creatingPost
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Create post'),
      ),
    );
  }
}
