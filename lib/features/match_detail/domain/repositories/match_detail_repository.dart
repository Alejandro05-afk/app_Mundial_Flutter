import '../entities/match_detail_entity.dart';

abstract class MatchDetailRepository {
  Future<MatchDetailEntity> getMatchDetail(int matchId);
}
