import 'package:dio/dio.dart';
import '../models/match_model.dart';

abstract class MatchesRemoteDataSource {
  Future<List<MatchModel>> getMatchesByDate(DateTime date);
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final Dio dio;
  MatchesRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MatchModel>> getMatchesByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

    try {
      final response = await dio.get(
        '/competitions/WC/matches',
        queryParameters: {
          'dateFrom': dateStr,
          'dateTo': dateStr,
        },
      );

      if (response.statusCode == 200) {
        final matches = response.data['matches'] as List<dynamic>;
        return matches
            .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Timeout: La API no respondió a tiempo (${e.type.name})');
        case DioExceptionType.connectionError:
          throw Exception('Error de red: No se pudo conectar a la API (${e.message})');
        case DioExceptionType.badResponse:
          throw Exception('Respuesta inválida: HTTP ${e.response?.statusCode} — ${e.response?.statusMessage}');
        default:
          throw Exception('Error desconocido al contactar la API: ${e.message}');
      }
    }
  }
}
