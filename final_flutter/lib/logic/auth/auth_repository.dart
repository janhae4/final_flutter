import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/login_result_model.dart';
import 'package:http/http.dart' as http;
import 'package:final_flutter/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class AuthRepository {
  final String backendUrl = 'https://final-flutter.onrender.com/api/auth';
  final String backendUrl2 = 'https://final-flutter-ml.onrender.com/';

  Future<void> checkHealth () async {
    try {
      await http.get(Uri.parse(backendUrl2));
      await http.get(Uri.parse(backendUrl));
    } catch (e) {
      throw Exception('Failed to check health');
    }
  }

  Future<UserModel?> getCurrentUser(String token) async {
    final res = await http.get(
      Uri.parse('$backendUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final res2 = await http.get(
      Uri.parse(backendUrl2)
    );
    print("res2: ${res2.statusCode}");
    if (res.statusCode == 200 && res2.statusCode == 200) {
      final json = jsonDecode(res.body);
      return UserModel.fromJson(json['user']);
    }
    return null;
  }

  Future<LoginResult> login(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$backendUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': phone, 'password': password}),
    );

    print(res.body);

    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    if (json['require2FA'] == true) {
      return LoginResult(requires2FA: true, tempToken: json['tempToken']);
    }
    final token = json['token'];
    await saveToken(token);
    return LoginResult(user: await getCurrentUser(token), requires2FA: false);
  }

  Future<void> verifyTwoFactorCode(String code, String token) async {
    final res = await http.post(
      Uri.parse('$backendUrl/verify-2fa'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to verify 2FA');
    }

    final json = jsonDecode(res.body);
    await saveToken(json['token']);
  }

  Future<List<String>> enable2FA(String code) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/enable-2fa'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to enable 2FA');
    }

    final json = jsonDecode(res.body);
    print(json);
    return List<String>.from(json['backupCodes']);
  }

  Future<Map<String, String>> generateQr() async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/generate-2fa'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to enable 2FA');
    }

    final json = jsonDecode(res.body);
    return {'qrCode': json['qrCode'], 'secretKey': json['manualEntryKey']};
  }

  Future<void> disable2FA(String password, String code) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/disable-2fa'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'password': password, 'code': code}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to disable 2FA');
    }
  }

  Future<void> register(String name, String phone, String password) async {
    final res = await http.post(
      Uri.parse('$backendUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'username': phone, 'password': password}),
    );

    if (res.statusCode != 201) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Register failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<UserModel> updateProfile(
    String name,
    String phone,
    String email,
  ) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$backendUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'phone': phone, 'email': email}),
    );

    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Register failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return UserModel.fromJson(json['user']);
  }

  Future<String> updatePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$backendUrl/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Register failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json['message'];
  }

  Future<UserModel> uploadImageToBackend(File imageFile) async {
    final token = await getToken();
    final url = Uri.parse('$backendUrl/upload-profile-picture');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }

    final json = jsonDecode(await response.stream.bytesToString());
    return UserModel.fromJson(json['user']);
  }

  Future<UserModel> uploadImageToBackendWeb(
    Uint8List bytes,
    String fileName,
  ) async {
    final token = await getToken();
    final url = Uri.parse('$backendUrl/upload-profile-picture');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_picture',
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }

    final json = jsonDecode(await response.stream.bytesToString());
    return UserModel.fromJson(json['user']);
  }

  Future<List<LabelModel>> addLabel(String label) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/labels'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'label': label}),
    );

    if (res.statusCode != 201) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Add label failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return List<LabelModel>.from(
      json['labels'].map((label) => LabelModel.fromJson(label)),
    );
  }

  Future<List<LabelModel>> removeLabel(String label) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$backendUrl/labels/$label'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Remove label failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return List<LabelModel>.from(
      json['labels'].map((label) => LabelModel.fromJson(label)),
    );
  }

  Future<List<LabelModel>> getLabels() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/labels'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Get labels failed';
      throw Exception(errorMessage);
    }
    final json = jsonDecode(res.body);
    return List<LabelModel>.from(json['labels'] ?? []);
  }

  Future<List<LabelModel>> updateLabel(String oldLabel, String newLabel) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('$backendUrl/labels/$oldLabel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newLabel': newLabel}),
    );

    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Update label failed';
      throw Exception(errorMessage);
    }
    final json = jsonDecode(res.body);
    return List<LabelModel>.from(
      json['labels'].map((label) => LabelModel.fromJson(label)),
    );
  }

  Future<String> recoveryPassword(String otp) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/recovery-password'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'otp': otp ?? ''}),
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Recovery password failed';
      throw Exception(errorMessage);
    }
    final json = jsonDecode(res.body);
    return json['password'];
  }
}
