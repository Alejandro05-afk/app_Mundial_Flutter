import '../../domain/entities/match_entity.dart';

class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.homeTeam,
    required super.awayTeam,
    super.homeScore,
    super.awayScore,
    super.venue,
    super.group,
    required super.stage,
    required super.utcDate,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final score = json['score'] as Map<String, dynamic>?;
    final fullTime = score?['fullTime'] as Map<String, dynamic>?;
    int? home = fullTime?['home'] as int?;
    int? away = fullTime?['away'] as int?;

    if (home == null) {
      final reg = score?['regularTime'] as Map<String, dynamic>?;
      home = reg?['home'] as int?;
      away = reg?['away'] as int?;
    }

    return MatchModel(
      id: json['id'] as int,
      homeTeam: (json['homeTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      awayTeam: (json['awayTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      homeScore: home,
      awayScore: away,
      venue: json['venue'] as String?,
      group: json['group'] as String?,
      stage: json['stage'] as String? ?? 'UNKNOWN',
      utcDate: DateTime.parse(json['utcDate'] as String),
    );
  }
}
