import '../entities/match_entity.dart';

abstract class MatchesRepository {
  Future<List<MatchEntity>> getMatchesByDate(DateTime date);
}
