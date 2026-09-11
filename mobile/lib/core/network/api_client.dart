import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  static const Duration _defaultTimeout = Duration(seconds: 20);
  String? authToken;
  void Function()? onUnauthorized;

  ApiClient({http.Client? client, this.authToken, this.onUnauthorized})
      : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...stringParams,
        });
      }

      final combinedHeaders = {..._headers, ...(headers ?? {})};
      final response = await _client
          .get(uri, headers: combinedHeaders)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your internet connection and backend status.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. Please try again.',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Network error: ${e.message}',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  /// Downloads raw byte content (such as images/audio) from a URL
  Future<Uint8List> getRawBytes(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final combinedHeaders = {..._headers, ...(headers ?? {})};
      final response = await _client
          .get(uri, headers: combinedHeaders)
          .timeout(timeout ?? _defaultTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw ApiException('Failed to download file (HTTP ${response.statusCode})', statusCode: response.statusCode);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your connection.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out while downloading file.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error downloading file: $e');
    }
  }

  Future<dynamic> post(
    String url, {
    required Map<String, dynamic> body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your connection.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error while creating: $e');
    }
  }

  Future<dynamic> put(
    String url, {
    required Map<String, dynamic> body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your connection.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error while updating: $e');
    }
  }

  Future<dynamic> delete(
    String url, {
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your connection.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error while deleting: $e');
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    required List<int> fileBytes,
    required String filename,
    String fileField = 'file',
    Map<String, String>? fields,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...stringParams,
        });
      }

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
      });
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await _client.send(request).timeout(timeout ?? const Duration(seconds: 35));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please check your connection.',
        statusCode: 0,
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out during photo processing. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error during image upload: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    dynamic responseBody;
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    // Handle 401 Unauthorized globally
    if (response.statusCode == 401) {
      authToken = null;
      onUnauthorized?.call();
    }

    String errorMessage = 'Something went wrong. Please try again.';
    if (responseBody is Map && responseBody.containsKey('detail')) {
      final detail = responseBody['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first.containsKey('msg')) {
          errorMessage = first['msg'].toString();
        }
      }
    } else if (response.statusCode == 401) {
      errorMessage = 'Session expired or unauthorized. Please log in again.';
    } else if (response.statusCode == 403) {
      errorMessage = 'Access denied. You do not have permission for this action.';
    } else if (response.statusCode == 404) {
      errorMessage = 'Resource not found.';
    } else if (response.statusCode == 422) {
      errorMessage = 'Validation error. Please check your inputs.';
    } else if (response.statusCode == 500) {
      errorMessage = 'Server error occurred. Please try again later.';
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      data: responseBody,
    );
  }
}
