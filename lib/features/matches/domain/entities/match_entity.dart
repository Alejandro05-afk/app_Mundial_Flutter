class MatchEntity {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? venue;
  final String? group;
  final String stage;
  final DateTime utcDate;

  const MatchEntity({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.venue,
    this.group,
    required this.stage,
    required this.utcDate,
  });

  String get scoreDisplay {
    if (homeScore == null || awayScore == null) return 'vs';
    return '$homeScore - $awayScore';
  }

  String get stageDisplay {
    const stages = {
      'GROUP_STAGE': 'Fase de Grupos',
      'ROUND_OF_32': 'Ronda de 32',
      'ROUND_OF_16': 'Octavos de Final',
      'QUARTER_FINALS': 'Cuartos de Final',
      'SEMI_FINALS': 'Semifinales',
      'THIRD_PLACE': 'Tercer Puesto',
      'FINAL': 'Final',
    };
    return stages[stage] ?? stage;
  }
}
