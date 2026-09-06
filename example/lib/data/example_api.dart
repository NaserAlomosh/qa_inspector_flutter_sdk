import 'package:dio/dio.dart';

class ExampleUser {
  const ExampleUser({required this.id, required this.name, required this.email});

  factory ExampleUser.fromJson(Map<String, Object?> json) => ExampleUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  final int id;
  final String name;
  final String email;
}

class ExamplePost {
  const ExamplePost({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory ExamplePost.fromJson(Map<String, Object?> json) => ExamplePost(
        id: json['id'] as int,
        userId: json['userId'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
      );

  final int id;
  final int userId;
  final String title;
  final String body;
}

class ExampleComment {
  const ExampleComment({required this.name, required this.body});

  factory ExampleComment.fromJson(Map<String, Object?> json) => ExampleComment(
        name: json['name'] as String,
        body: json['body'] as String,
      );

  final String name;
  final String body;
}

class ExampleApi {
  const ExampleApi(this._dio);

  final Dio _dio;

  Future<List<ExampleUser>> getUsers() async {
    final response = await _dio.get<List<Object?>>('/users');
    return response.data!
        .cast<Map<String, Object?>>()
        .map(ExampleUser.fromJson)
        .toList();
  }

  Future<List<ExamplePost>> getPosts(int userId) async {
    final response = await _dio.get<List<Object?>>(
      '/posts',
      queryParameters: <String, Object>{
        'userId': userId,
        'sessionId': 'qa-example-session-secret',
      },
    );
    return response.data!
        .cast<Map<String, Object?>>()
        .map(ExamplePost.fromJson)
        .toList();
  }

  Future<int?> createPost(int userId) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/posts',
      data: <String, Object>{
        'title': 'QA generated post',
        'body': 'Created from the qa_inspector example app.',
        'userId': userId,
        'password': 'super-secret-password',
        'otp': '123456',
        'accessToken': 'example-access-token',
      },
    );
    return response.data?['id'] as int?;
  }

  Future<List<ExampleComment>> getComments(int postId) async {
    final response = await _dio.get<List<Object?>>('/posts/$postId/comments');
    return response.data!
        .cast<Map<String, Object?>>()
        .map(ExampleComment.fromJson)
        .toList();
  }

  Future<void> triggerNotFound() => _dio.get<void>('/posts/999999999');

  Future<void> runParallelRequests() async {
    await Future.wait(<Future<Response<Object?>>[
      _dio.get<Object?>('/todos', queryParameters: <String, int>{'userId': 1}),
      _dio.get<Object?>('/albums', queryParameters: <String, int>{'userId': 1}),
      _dio.get<Object?>('/photos', queryParameters: <String, int>{'albumId': 1}),
    ]);
  }
}
