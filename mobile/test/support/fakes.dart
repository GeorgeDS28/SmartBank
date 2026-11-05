import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/storage/token_storage.dart';

/// Canned response returned by [FakeApiAdapter] for a matching request.
class StubbedResponse {
  final int statusCode;
  final Object body;

  const StubbedResponse(this.statusCode, this.body);

  const StubbedResponse.ok(this.body) : statusCode = 200;
}

/// In-memory [HttpClientAdapter] so repositories can be exercised without a
/// running backend. Responses are matched on "METHOD /path".
class FakeApiAdapter implements HttpClientAdapter {
  final Map<String, StubbedResponse> stubs;
  final List<RequestLog> log = [];

  FakeApiAdapter(this.stubs);

  String _key(RequestOptions options) =>
      '${options.method} ${options.uri.path}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    log.add(RequestLog(_key(options), options.data, Map.of(options.headers)));

    final stub = stubs[_key(options)];
    if (stub == null) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'No stub for ${_key(options)}'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(stub.body),
      stub.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  RequestLog? get lastRequest => log.isEmpty ? null : log.last;
}

class RequestLog {
  final String key;
  final dynamic body;
  final Map<String, dynamic> headers;

  const RequestLog(this.key, this.body, this.headers);
}

/// Token storage that never touches platform channels, so tests do not need
/// the secure-storage plugin registered.
class FakeTokenStorage extends TokenStorage {
  String? token;

  FakeTokenStorage({this.token});

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

ApiClient buildFakeClient(
  Map<String, StubbedResponse> stubs, {
  String? token = 'test-jwt',
}) {
  final client = ApiClient(tokenStorage: FakeTokenStorage(token: token));
  client.dio.httpClientAdapter = FakeApiAdapter(stubs);
  return client;
}

/// Builds a token whose payload carries the email as `sub`, matching what the
/// backend signs, so tests can exercise the identity shown to the user.
String tokenFor(String email) {
  String encode(Map<String, Object> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'sub': email})}.signature';
}
