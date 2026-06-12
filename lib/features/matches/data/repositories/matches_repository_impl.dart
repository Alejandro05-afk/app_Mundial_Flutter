import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDataSource remoteDataSource;
  MatchesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<MatchEntity>> getMatchesByDate(DateTime date) {
    return remoteDataSource.getMatchesByDate(date);
  }
}
