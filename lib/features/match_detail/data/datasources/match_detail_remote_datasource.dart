import 'package:dio/dio.dart';
import '../models/match_detail_model.dart';

abstract class MatchDetailRemoteDataSource {
  Future<MatchDetailModel> getMatchDetail(int matchId);
}

class MatchDetailRemoteDataSourceImpl implements MatchDetailRemoteDataSource {
  final Dio dio;
  MatchDetailRemoteDataSourceImpl(this.dio);

  @override
  Future<MatchDetailModel> getMatchDetail(int matchId) async {
    try {
      final response = await dio.get('/matches/$matchId');
      if (response.statusCode == 200) {
        return MatchDetailModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Timeout al obtener el detalle del partido (${e.type.name})');
        case DioExceptionType.connectionError:
          throw Exception('Sin conexión al obtener detalle: ${e.message}');
        case DioExceptionType.badResponse:
          throw Exception('Respuesta inválida: HTTP ${e.response?.statusCode}');
        default:
          throw Exception('Error desconocido: ${e.message}');
      }
    }
  }
}
