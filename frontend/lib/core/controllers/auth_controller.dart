import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../network/user_api.dart';
import '../../data/models/user_model.dart';
import '../network/api_error.dart';


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
      errorMessage = apiErrorMessage(e, fallback: 'Login failed. Please try again.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,        // ← new
    String? externalId,   // ← new
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
            await ApiClient.dio.post('/api/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (externalId != null && externalId.isNotEmpty) 'external_id': externalId,
      });
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback: 'Registration failed. Please try again.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    ApiClient.clearToken();
    currentUser = null;
    notifyListeners();
  }
}