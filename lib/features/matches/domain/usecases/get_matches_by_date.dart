import '../entities/match_entity.dart';
import '../repositories/matches_repository.dart';

class GetMatchesByDate {
  final MatchesRepository repository;
  const GetMatchesByDate(this.repository);

  Future<List<MatchEntity>> call(DateTime date) {
    return repository.getMatchesByDate(date);
  }
}
