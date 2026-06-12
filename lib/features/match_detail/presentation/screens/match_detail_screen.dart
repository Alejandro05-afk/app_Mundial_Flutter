import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/match_detail_remote_datasource.dart';
import '../../data/repositories/match_detail_repository_impl.dart';
import '../../domain/entities/match_detail_entity.dart';
import '../../domain/usecases/get_match_detail.dart';

class MatchDetailScreen extends StatefulWidget {
  final int matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late final Future<MatchDetailEntity> _detailFuture;

  @override
  void initState() {
    super.initState();
    final dio        = DioClient.instance;
    final dataSource = MatchDetailRemoteDataSourceImpl(dio);
    final repo       = MatchDetailRepositoryImpl(dataSource);
    final useCase    = GetMatchDetail(repo);
    _detailFuture    = useCase(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Partido'),
        centerTitle: true,
      ),
      body: FutureBuilder<MatchDetailEntity>(
        future: _detailFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar el detalle:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          final match = snapshot.data!;
          final localDateStr = DateFormat('EEEE d MMMM yyyy, HH:mm', 'es')
              .format(match.localDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                Text(
                  match.homeTeam,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  match.scoreDisplay,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  match.awayTeam,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const Divider(height: 40),

                _InfoRow(icon: Icons.emoji_events, label: 'Fase', value: match.stageDisplay),

                if (match.group != null)
                  _InfoRow(icon: Icons.group_work, label: 'Grupo', value: match.group!),

                if (match.venue != null)
                  _InfoRow(icon: Icons.stadium, label: 'Estadio', value: match.venue!),

                _InfoRow(
                  icon: Icons.schedule,
                  label: 'Fecha y hora local',
                  value: localDateStr,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
