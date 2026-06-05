import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _baseUrlKey = 'api_base_url';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  String baseUrl;

  ApiService._(this.baseUrl);

  dynamic _decodeJson(http.Response resp) {
    return jsonDecode(utf8.decode(resp.bodyBytes));
  }

  static Future<ApiService> create({String? defaultUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrl = prefs.getString(_baseUrlKey);
    final url = storedUrl ?? defaultUrl ?? 'http://10.0.2.2:8000';
    return ApiService._(url);
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final resp = await http.get(url);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final data = _decodeJson(resp);
      final token = data['access_token'];
      if (token != null) {
        await _storage.write(key: 'access_token', value: token);
        return token;
      }
    }

    final urlForm = Uri.parse('$baseUrl/api/auth/login/form');
    final respForm = await http.post(
      urlForm,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (respForm.statusCode == 200) {
      final data = _decodeJson(respForm);
      final token = data['access_token'];
      if (token != null) {
        await _storage.write(key: 'access_token', value: token);
        return token;
      }
    }

    return null;
  }

  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/users/register');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  Future<bool> logout() async {
    final token = await getToken();
    if (token != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout');
      await http.post(url, headers: {'Authorization': 'Bearer $token'});
    }
    await _storage.delete(key: 'access_token');
    return true;
  }

  Future<String?> getToken() async => await _storage.read(key: 'access_token');

  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;
    final url = Uri.parse('$baseUrl/api/users/me');
    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/api/users/me');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return resp.statusCode == 200;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/api/users/me/password');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    return resp.statusCode == 200;
  }

  Future<List<dynamic>> getRooms() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/rooms');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }

  Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/rooms');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<bool> updateRoom(int roomId, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/rooms/$roomId');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return resp.statusCode == 200;
  }

  Future<bool> deleteRoom(int roomId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/rooms/$roomId');
    final resp = await http.delete(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 204;
  }

  Future<List<dynamic>> getSensors() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/sensors');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }


  Future<Map<String, dynamic>> requestWithResponse(
    String method,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');
    late http.Response resp;

    if (method.toUpperCase() == 'POST') {
      resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
    } else if (method.toUpperCase() == 'PUT') {
      resp = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
    } else if (method.toUpperCase() == 'PATCH') {
      resp = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
    }

    dynamic body;
    try {
      body = _decodeJson(resp);
    } catch (_) {
      body = resp.body;
    }
    return {'status': resp.statusCode, 'body': body};
  }

  Future<Map<String, dynamic>> postWithResponse(String endpoint, Map<String, dynamic> data) async {
    return requestWithResponse('POST', endpoint, data);
  }

  Future<Map<String, dynamic>?> createSensor(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/sensors');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<bool> updateSensor(int sensorId, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/sensors/$sensorId');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return resp.statusCode == 200;
  }

  Future<bool> deleteSensor(int sensorId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/sensors/$sensorId');
    final resp = await http.delete(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 204;
  }

  Future<List<dynamic>> getClimateDevices() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-devices');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }

  Future<Map<String, dynamic>?> createClimateDevice(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-devices');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<bool> updateClimateDevice(int deviceId, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-devices/$deviceId');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return resp.statusCode == 200;
  }

  Future<bool> deleteClimateDevice(int deviceId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-devices/$deviceId');
    final resp = await http.delete(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 204;
  }

  Future<Map<String, dynamic>?> getClimateThresholdForRoom(int roomId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-thresholds/room/$roomId');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<Map<String, dynamic>?> createClimateThreshold(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-thresholds');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<List<dynamic>> getClimateThresholds() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-thresholds');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }

  Future<bool> deleteClimateThreshold(int thresholdId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-thresholds/$thresholdId');
    final resp = await http.delete(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 204;
  }

  Future<bool> updateClimateThreshold(int thresholdId, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-thresholds/$thresholdId');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return resp.statusCode == 200;
  }

  Future<List<dynamic>> getAlerts() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/alerts');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }

  Future<Map<String, dynamic>?> createAlert(Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/alerts');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return _decodeJson(resp);
    }
    return null;
  }

  Future<bool> markAlertRead(int alertId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/alerts/$alertId/read');
    final resp = await http.put(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 200;
  }

  Future<bool> deleteAlert(int alertId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/alerts/$alertId');
    final resp = await http.delete(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    return resp.statusCode == 204;
  }

  Future<bool> sendDeviceCommand(int deviceId, String command, [Map<String, dynamic>? params]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/climate-devices/$deviceId/control');
    final Map<String, dynamic> body = {'command': command};
    if (params != null) body['parameters'] = params;
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  Future<List<dynamic>> getSensorReadings(int sensorId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/sensors/$sensorId/readings');
    final resp = await http.get(url, headers: token != null ? {'Authorization': 'Bearer $token'} : {});
    if (resp.statusCode == 200) {
      return List<dynamic>.from(_decodeJson(resp));
    }
    return [];
  }
}

