import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/example_api.dart';
import '../widgets/error_state.dart';
import 'user_posts_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({required this.api, super.key});

  final ExampleApi api;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<ExampleUser>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _users = null;
      _error = null;
    });
    try {
      final users = await widget.api.getUsers();
      if (mounted) setState(() => _users = users);
    } on DioException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  String _message(DioException error) =>
      error.response?.statusCode == null
          ? 'Could not load users. Check your connection and try again.'
          : 'Could not load users (HTTP ${error.response!.statusCode}).';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA Journey · Users'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadUsers,
            tooltip: 'Reload users',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch ((_users, _error)) {
        (_, final String error) =>
          ErrorState(message: error, onRetry: _loadUsers),
        (final List<ExampleUser> users, _) => ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      settings: RouteSettings(name: '/users/${user.id}'),
                      builder: (_) => UserPostsScreen(api: widget.api, user: user),
                    ),
                  ),
                ),
              );
            },
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
