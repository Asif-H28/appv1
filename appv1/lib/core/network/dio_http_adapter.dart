import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appv1/core/network/dio_client.dart';
import 'package:http/http.dart' as http_pkg;

export 'package:http/http.dart' show MultipartRequest, MultipartFile, StreamedResponse, ByteStream, Request, Response;

Future<http_pkg.Response> get(Uri url, {Map<String, String>? headers}) async {
  try {
    final res = await DioClient.instance.get(
      url.toString(),
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : null),
    );
    final bodyString = res.data is String ? res.data as String : jsonEncode(res.data);
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      res.statusCode ?? 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...?res.headers.map.map((key, value) => MapEntry(key, value.join(','))),
      },
      request: http_pkg.Request('GET', url),
    );
  } catch (e) {
    debugPrint('[DioHttpAdapter] ❌ GET Error for $url: $e');
    int statusCode = 500;
    dynamic responseData;
    
    try {
      final dynamic err = e;
      if (err.response != null) {
        statusCode = err.response.statusCode ?? 500;
        responseData = err.response.data;
      }
    } catch (_) {}

    final bodyString = responseData is String ? responseData : jsonEncode(responseData ?? {'error': e.toString()});
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: http_pkg.Request('GET', url),
    );
  }
}

Future<http_pkg.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
  try {
    final res = await DioClient.instance.post(
      url.toString(),
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : null),
      data: body,
    );
    final bodyString = res.data is String ? res.data as String : jsonEncode(res.data);
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      res.statusCode ?? 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...?res.headers.map.map((key, value) => MapEntry(key, value.join(','))),
      },
      request: http_pkg.Request('POST', url),
    );
  } catch (e) {
    debugPrint('[DioHttpAdapter] ❌ POST Error for $url: $e');
    int statusCode = 500;
    dynamic responseData;
    
    try {
      final dynamic err = e;
      if (err.response != null) {
        statusCode = err.response.statusCode ?? 500;
        responseData = err.response.data;
      }
    } catch (_) {}

    final bodyString = responseData is String ? responseData : jsonEncode(responseData ?? {'error': e.toString()});
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: http_pkg.Request('POST', url),
    );
  }
}

Future<http_pkg.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
  try {
    final res = await DioClient.instance.put(
      url.toString(),
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : null),
      data: body,
    );
    final bodyString = res.data is String ? res.data as String : jsonEncode(res.data);
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      res.statusCode ?? 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...?res.headers.map.map((key, value) => MapEntry(key, value.join(','))),
      },
      request: http_pkg.Request('PUT', url),
    );
  } catch (e) {
    debugPrint('[DioHttpAdapter] ❌ PUT Error for $url: $e');
    int statusCode = 500;
    dynamic responseData;
    
    try {
      final dynamic err = e;
      if (err.response != null) {
        statusCode = err.response.statusCode ?? 500;
        responseData = err.response.data;
      }
    } catch (_) {}

    final bodyString = responseData is String ? responseData : jsonEncode(responseData ?? {'error': e.toString()});
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: http_pkg.Request('PUT', url),
    );
  }
}

Future<http_pkg.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) async {
  try {
    final res = await DioClient.instance.delete(
      url.toString(),
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : null),
      data: body,
    );
    final bodyString = res.data is String ? res.data as String : jsonEncode(res.data);
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      res.statusCode ?? 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...?res.headers.map.map((key, value) => MapEntry(key, value.join(','))),
      },
      request: http_pkg.Request('DELETE', url),
    );
  } catch (e) {
    debugPrint('[DioHttpAdapter] ❌ DELETE Error for $url: $e');
    int statusCode = 500;
    dynamic responseData;
    
    try {
      final dynamic err = e;
      if (err.response != null) {
        statusCode = err.response.statusCode ?? 500;
        responseData = err.response.data;
      }
    } catch (_) {}

    final bodyString = responseData is String ? responseData : jsonEncode(responseData ?? {'error': e.toString()});
    return http_pkg.Response.bytes(
      utf8.encode(bodyString),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: http_pkg.Request('DELETE', url),
    );
  }
}
