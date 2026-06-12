import '../../domain/entities/match_detail_entity.dart';
import '../../domain/repositories/match_detail_repository.dart';
import '../datasources/match_detail_remote_datasource.dart';

class MatchDetailRepositoryImpl implements MatchDetailRepository {
  final MatchDetailRemoteDataSource remoteDataSource;
  MatchDetailRepositoryImpl(this.remoteDataSource);

  @override
  Future<MatchDetailEntity> getMatchDetail(int matchId) =>
      remoteDataSource.getMatchDetail(matchId);
}
