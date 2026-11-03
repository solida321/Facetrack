// lib/core/network/api_client.dart — ASSUMED SHAPE, verify against your real file
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
     static final Dio dio = Dio(
     BaseOptions(
       baseUrl: 'https://facetrack-90w0.onrender.com',
       connectTimeout: const Duration(seconds: 60),
       receiveTimeout: const Duration(seconds: 60),
     ),
   );
  static final _storage = const FlutterSecureStorage();

  static Future<void> attachToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
   
  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}