import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'constants.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, String> get _authHeader => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<List<dynamic>> getList(String path) async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
    );
    final data = _parse(res);
    if (data['data'] is List) return data['data'] as List;
    throw Exception(data['message'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  /// Upload a single file (e.g. avatar)
  Future<Map<String, dynamic>> uploadFile(
    String path,
    String fieldName,
    XFile file,
  ) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}$path'),
    )..headers.addAll(_authHeader);
    final bytes = await file.readAsBytes();
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: file.name),
    );
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  /// Multipart POST for ad submission with images
  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields,
    List<File> files,
  ) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}$path'))
          ..headers.addAll(_authHeader)
          ..fields.addAll(fields);

    for (final file in files) {
      req.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  /// Multipart POST using XFile bytes — works on Flutter Web
  Future<Map<String, dynamic>> postMultipartWeb(
    String path,
    Map<String, String> fields,
    List<XFile> files,
  ) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}$path'))
          ..headers.addAll(_authHeader)
          ..fields.addAll(fields);

    for (final file in files) {
      final bytes = await file.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes('images', bytes, filename: file.name),
      );
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return {'data': body};
      return body as Map<String, dynamic>;
    }
    throw Exception((body as Map)['message'] ?? 'Request failed');
  }
}
