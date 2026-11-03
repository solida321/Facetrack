import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/user_api.dart';
import '../../data/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      await _storage.write(key: 'access_token', value: token);
      await ApiClient.attachToken();

      currentUser = await UserApi.getMe();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
<<<<<<< HEAD
      errorMessage = 'DEBUG: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
=======
  String detail = apiErrorMessage(e, fallback: 'Login failed. Please try again.');
  if (e is DioException) {
    detail = 'DEBUG ${e.type.name} | status ${e.response?.statusCode} | ${e.requestOptions.uri} | ${e.message}';
>>>>>>> 99c1b91 (Add slides , Update)
  }
  errorMessage = detail;
  isLoading = false;
  notifyListeners();
  return false;
}
}

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.dio.post('/api/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
      });

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'DEBUG: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    currentUser = null;
    notifyListeners();
  }
}