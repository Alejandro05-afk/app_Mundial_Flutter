import 'package:flutter/material.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = match.venue != null
        ? match.venue!
        : match.stageDisplay;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${match.homeTeam}  ${match.scoreDisplay}  ${match.awayTeam}',
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        subtitle: Text(subtitle, textAlign: TextAlign.center),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
