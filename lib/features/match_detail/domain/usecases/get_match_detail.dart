import '../entities/match_detail_entity.dart';
import '../repositories/match_detail_repository.dart';

class GetMatchDetail {
  final MatchDetailRepository repository;
  const GetMatchDetail(this.repository);

  Future<MatchDetailEntity> call(int matchId) => repository.getMatchDetail(matchId);
}
