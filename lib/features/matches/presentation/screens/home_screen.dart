import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/matches_remote_datasource.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/usecases/get_matches_by_date.dart';
import '../widgets/match_card.dart';
import '../../../match_detail/presentation/screens/match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final DateTime _worldCupStart = DateTime(2026, 6, 11);
  static final DateTime _worldCupEnd   = DateTime(2026, 7, 19);

  late DateTime _selectedDate;
  late Future<List<MatchEntity>> _matchesFuture;
  late final GetMatchesByDate _getMatchesByDate;

  @override
  void initState() {
    super.initState();
    final dio        = DioClient.instance;
    final dataSource = MatchesRemoteDataSourceImpl(dio);
    final repo       = MatchesRepositoryImpl(dataSource);
    _getMatchesByDate = GetMatchesByDate(repo);

    _selectedDate = _clampToTournament(DateTime.now());
    _loadMatches();
  }

  DateTime _clampToTournament(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(_worldCupStart)) return _worldCupStart;
    if (d.isAfter(_worldCupEnd))    return _worldCupEnd;
    return d;
  }

  void _loadMatches() {
    setState(() {
      _matchesFuture = _getMatchesByDate(_selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _worldCupStart,
      lastDate:  _worldCupEnd,
      locale: const Locale('es'),
      helpText: 'Selecciona un día del Mundial 2026',
      confirmText: 'VER PARTIDOS',
      cancelText: 'CANCELAR',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'es').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mundial 2026'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Elegir fecha',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: _pickDate,
              child: Chip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(dateLabel),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MatchEntity>>(
              future: _matchesFuture,
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
                          const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            'Error al cargar partidos:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadMatches,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final matches = snapshot.data ?? [];

                if (matches.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay partidos del Mundial en esta fecha',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    return MatchCard(
                      match: matches[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchDetailScreen(matchId: matches[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
