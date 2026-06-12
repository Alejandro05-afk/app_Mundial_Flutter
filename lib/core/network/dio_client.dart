import 'package:dio/dio.dart';

class DioClient {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  static const String _apiKey = 'b4515c2674eb44979d009a1b5dbdf6ca';

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'X-Auth-Token': _apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  }
}
