---
name: mundial2026-flutter
description: >
  Genera la aplicación Flutter completa "Partidos del Mundial 2026" cumpliendo
  todas las historias de usuario HU-01, HU-02 y HU-03. Úsala cuando el usuario
  pida implementar cualquiera de los criterios de aceptación del Taller 13,
  o mencione: partidos del día, filtrar por fecha, detalle de partido, DatePicker
  Mundial, FutureBuilder, Dio, Navigator.push, Clean Architecture + Vertical Slicing,
  football-data.org, icono APK, o cualquier combinación de estas.
stack:
  - Flutter (framework UI + lógica)
  - Dio (cliente HTTP, headers centralizados, timeouts)
  - football-data.org v4 (free tier, sin tarjeta, WC = "WC", 10 req/min)
  - Navigator.push (navegación imperativa home → detalle)
  - FutureBuilder (estados loading / error / data)
  - Clean Architecture + Vertical Slicing (data / domain / presentation por feature)
compatibility: Flutter 3.x, Dart 3.x, flutter_localizations
---

# Skill: Mundial 2026 Flutter — Taller 13

## 0. Análisis de APIs gratuitas y elección

| API | Free tier | Mundial 2026 | Auth | Límite |
|-----|-----------|--------------|------|--------|
| **football-data.org v4** ✅ | Sí, permanente | Código `WC`, datos reales | API Key header | 10 req/min |
| API-Football (api-sports.io) | 100 req/día | `league=1 season=2026` | API Key header | 100 req/día |
| worldcup26.ir (rezarahiminia) | Sí, sin key demo | 104 partidos, grupos, estadios | Bearer token | Sin documentar |
| Zafronix WC API | 250 req/día | Completo 1930-2026 | API Key | 250 req/día |

**Elección: `football-data.org v4`**

Razones:
- Tier gratuito **permanente y público** (desde 2013, el fundador se comprometió a mantenerlo free).
- Incluye el **Mundial 2026** bajo el código de competición `WC`.
- Endpoints directos por fecha: `GET /v4/competitions/WC/matches?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD`
- Detalle de partido: `GET /v4/matches/{id}` — devuelve estadio, marcador, grupo, fase, hora UTC.
- Rate limit de 10 req/min es tolerable para un taller académico con cacheo mínimo.
- Registro en 60 segundos en https://www.football-data.org/client/register — sin tarjeta.

---

## 1. Estructura del proyecto (Vertical Slicing + Clean Architecture)

```
lib/
├── core/
│   ├── network/
│   │   └── dio_client.dart          # Configuración centralizada de Dio
│   └── error/
│       └── failures.dart            # Tipos de error del dominio
├── features/
│   ├── matches/                     # Feature: lista de partidos (HU-01, HU-02)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── matches_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── match_model.dart
│   │   │   └── repositories/
│   │   │       └── matches_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── match_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── matches_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_matches_by_date.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           └── match_card.dart
│   └── match_detail/               # Feature: detalle (HU-03)
│       ├── data/
│       │   ├── datasources/
│       │   │   └── match_detail_remote_datasource.dart
│       │   ├── models/
│       │   │   └── match_detail_model.dart
│       │   └── repositories/
│       │       └── match_detail_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── match_detail_entity.dart
│       │   ├── repositories/
│       │   │   └── match_detail_repository.dart
│       │   └── usecases/
│       │       └── get_match_detail.dart
│       └── presentation/
│           └── screens/
│               └── match_detail_screen.dart
└── main.dart
```

---

## 2. `pubspec.yaml` — dependencias necesarias

```yaml
name: mundial_2026
description: Partidos del Mundial 2026 - Taller 13

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.3+1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icon/
```

---

## 3. `core/network/dio_client.dart` — Dio centralizado

```dart
import 'package:dio/dio.dart';

class DioClient {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  // Obtener la API key en: https://www.football-data.org/client/register
  static const String _apiKey = 'TU_API_KEY_AQUI';

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'X-Auth-Token': _apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor de logging para desarrollo
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  }
}
```

---

## 4. `core/error/failures.dart`

```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('La solicitud tardó demasiado. Verifica tu conexión.');
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
```

---

## 5. Feature `matches` — HU-01 (partidos del día) y HU-02 (filtrar por fecha)

### 5.1 Entidad de dominio

```dart
// features/matches/domain/entities/match_entity.dart
class MatchEntity {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;      // null si no ha comenzado
  final int? awayScore;      // null si no ha comenzado
  final String? venue;       // estadio (puede ser null)
  final String? group;       // null en fases eliminatorias
  final String stage;        // e.g. "GROUP_STAGE", "ROUND_OF_32"
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

  /// Devuelve el marcador formateado o 'vs' si el partido no ha comenzado
  String get scoreDisplay {
    if (homeScore == null || awayScore == null) return 'vs';
    return '$homeScore - $awayScore';
  }

  /// Fase legible para el usuario
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
```

### 5.2 Repositorio (interfaz)

```dart
// features/matches/domain/repositories/matches_repository.dart
import '../entities/match_entity.dart';

abstract class MatchesRepository {
  /// Lanza [Exception] con mensaje descriptivo si falla la API (HU-01 Escenario 3)
  Future<List<MatchEntity>> getMatchesByDate(DateTime date);
}
```

### 5.3 Use case

```dart
// features/matches/domain/usecases/get_matches_by_date.dart
import '../entities/match_entity.dart';
import '../repositories/matches_repository.dart';

class GetMatchesByDate {
  final MatchesRepository repository;
  const GetMatchesByDate(this.repository);

  Future<List<MatchEntity>> call(DateTime date) {
    return repository.getMatchesByDate(date);
  }
}
```

### 5.4 Modelo (capa de datos)

```dart
// features/matches/data/models/match_model.dart
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
    final halfTime = score?['halfTime'] as Map<String, dynamic>?;

    // Para partidos en curso usamos halfTime o los scores disponibles
    int? home = fullTime?['home'] as int?;
    int? away = fullTime?['away'] as int?;

    // Si aún no terminó pero está en curso, intentar con regularTime
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
```

### 5.5 DataSource remoto

```dart
// features/matches/data/datasources/matches_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/match_model.dart';

abstract class MatchesRemoteDataSource {
  Future<List<MatchModel>> getMatchesByDate(DateTime date);
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final Dio dio;
  MatchesRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MatchModel>> getMatchesByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

    try {
      final response = await dio.get(
        '/competitions/WC/matches',
        queryParameters: {
          'dateFrom': dateStr,
          'dateTo': dateStr,
        },
      );

      if (response.statusCode == 200) {
        final matches = response.data['matches'] as List<dynamic>;
        return matches
            .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      // Mapear errores de Dio a mensajes descriptivos (HU-01 Escenario 3)
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Timeout: La API no respondió a tiempo (${e.type.name})');
        case DioExceptionType.connectionError:
          throw Exception('Error de red: No se pudo conectar a la API (${e.message})');
        case DioExceptionType.badResponse:
          throw Exception('Respuesta inválida: HTTP ${e.response?.statusCode} — ${e.response?.statusMessage}');
        default:
          throw Exception('Error desconocido al contactar la API: ${e.message}');
      }
    }
  }
}
```

### 5.6 Repositorio implementado

```dart
// features/matches/data/repositories/matches_repository_impl.dart
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
```

### 5.7 `HomeScreen` — HU-01 + HU-02 (DatePicker, FutureBuilder, estados)

```dart
// features/matches/presentation/screens/home_screen.dart
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
  // Rango del Mundial 2026: 11 jun – 19 jul (HU-02 Escenario 3)
  static final DateTime _worldCupStart = DateTime(2026, 6, 11);
  static final DateTime _worldCupEnd   = DateTime(2026, 7, 19);

  late DateTime _selectedDate;
  late Future<List<MatchEntity>> _matchesFuture;
  late final GetMatchesByDate _getMatchesByDate;

  @override
  void initState() {
    super.initState();
    // Inicialización del grafo de dependencias en presentación
    final dio        = DioClient.instance;
    final dataSource = MatchesRemoteDataSourceImpl(dio);
    final repo       = MatchesRepositoryImpl(dataSource);
    _getMatchesByDate = GetMatchesByDate(repo);

    // HU-01: mostrar partidos del día actual al abrir la app
    _selectedDate = _clampToTournament(DateTime.now());
    _loadMatches();
  }

  /// Ajusta la fecha al rango del torneo si el usuario abre la app fuera del rango
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

  /// HU-02: abrir DatePicker con rango limitado al torneo
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _worldCupStart,   // HU-02 Escenario 3: límite inferior
      lastDate:  _worldCupEnd,     // HU-02 Escenario 3: límite superior
      locale: const Locale('es'),
      helpText: 'Selecciona un día del Mundial 2026',
      confirmText: 'VER PARTIDOS',
      cancelText: 'CANCELAR',
    );

    // HU-02 Escenario 4: si se cierra sin confirmar, no cambia nada
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadMatches();   // HU-02 Escenario 1: nueva llamada a la API
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'es').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚽ Mundial 2026'),
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
          // Chip de fecha seleccionada
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

                // HU-01 Escenario 4: estado de carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // HU-01 Escenario 3: error de red / timeout / respuesta inválida
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

                // HU-01 Escenario 2 / HU-02 Escenario 2: no hay partidos
                if (matches.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay partidos del Mundial en esta fecha',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // HU-01 Escenario 1 / HU-02 Escenario 1: lista de partidos
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    return MatchCard(
                      match: matches[index],
                      // HU-03 Escenario 1: navegar al detalle con Navigator.push
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
```

### 5.8 Widget `MatchCard`

```dart
// features/matches/presentation/widgets/match_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/match_entity.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // HU-01 Escenario 1: nombre de equipos, marcador o 'vs', estadio o fase
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
```

---

## 6. Feature `match_detail` — HU-03

### 6.1 Entidad de detalle

```dart
// features/match_detail/domain/entities/match_detail_entity.dart
class MatchDetailEntity {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? venue;
  final String? group;        // HU-03 Escenario 4: null en eliminatorias → no mostrar
  final String stage;
  final DateTime utcDate;     // HU-03 Escenario 2: convertir a hora local del dispositivo

  const MatchDetailEntity({
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

  String get scoreDisplay => (homeScore == null || awayScore == null)
      ? 'vs'
      : '$homeScore - $awayScore';

  String get stageDisplay {
    const stages = {
      'GROUP_STAGE'   : 'Fase de Grupos',
      'ROUND_OF_32'   : 'Ronda de 32',
      'ROUND_OF_16'   : 'Octavos de Final',
      'QUARTER_FINALS': 'Cuartos de Final',
      'SEMI_FINALS'   : 'Semifinales',
      'THIRD_PLACE'   : 'Tercer Puesto',
      'FINAL'         : 'Final',
    };
    return stages[stage] ?? stage;
  }

  /// Hora local del dispositivo (HU-03 Escenario 2)
  DateTime get localDate => utcDate.toLocal();
}
```

### 6.2 Repositorio, datasource, modelo y use case (detalle)

```dart
// features/match_detail/domain/repositories/match_detail_repository.dart
import '../entities/match_detail_entity.dart';
abstract class MatchDetailRepository {
  Future<MatchDetailEntity> getMatchDetail(int matchId);
}

// ---

// features/match_detail/data/models/match_detail_model.dart
import '../../domain/entities/match_detail_entity.dart';
class MatchDetailModel extends MatchDetailEntity {
  const MatchDetailModel({
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

  factory MatchDetailModel.fromJson(Map<String, dynamic> json) {
    final score    = json['score']    as Map<String, dynamic>?;
    final fullTime = score?['fullTime'] as Map<String, dynamic>?;
    int? home = fullTime?['home'] as int?;
    int? away = fullTime?['away'] as int?;
    if (home == null) {
      final reg = score?['regularTime'] as Map<String, dynamic>?;
      home = reg?['home'] as int?;
      away = reg?['away'] as int?;
    }
    return MatchDetailModel(
      id:       json['id'] as int,
      homeTeam: (json['homeTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      awayTeam: (json['awayTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      homeScore: home,
      awayScore: away,
      venue:  json['venue']  as String?,
      group:  json['group']  as String?,
      stage:  json['stage']  as String? ?? 'UNKNOWN',
      utcDate: DateTime.parse(json['utcDate'] as String),
    );
  }
}

// ---

// features/match_detail/data/datasources/match_detail_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/match_detail_model.dart';

abstract class MatchDetailRemoteDataSource {
  Future<MatchDetailModel> getMatchDetail(int matchId);
}

class MatchDetailRemoteDataSourceImpl implements MatchDetailRemoteDataSource {
  final Dio dio;
  MatchDetailRemoteDataSourceImpl(this.dio);

  @override
  Future<MatchDetailModel> getMatchDetail(int matchId) async {
    try {
      final response = await dio.get('/matches/$matchId');
      if (response.statusCode == 200) {
        return MatchDetailModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Error del servidor: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Timeout al obtener el detalle del partido (${e.type.name})');
        case DioExceptionType.connectionError:
          throw Exception('Sin conexión al obtener detalle: ${e.message}');
        case DioExceptionType.badResponse:
          throw Exception('Respuesta inválida: HTTP ${e.response?.statusCode}');
        default:
          throw Exception('Error desconocido: ${e.message}');
      }
    }
  }
}

// ---

// features/match_detail/data/repositories/match_detail_repository_impl.dart
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

// ---

// features/match_detail/domain/usecases/get_match_detail.dart
import '../entities/match_detail_entity.dart';
import '../repositories/match_detail_repository.dart';

class GetMatchDetail {
  final MatchDetailRepository repository;
  const GetMatchDetail(this.repository);

  Future<MatchDetailEntity> call(int matchId) => repository.getMatchDetail(matchId);
}
```

### 6.3 `MatchDetailScreen` — HU-03

```dart
// features/match_detail/presentation/screens/match_detail_screen.dart
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
    // HU-03 Escenario 1: consultar la API con el id del partido
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
        // HU-03 Escenario 3: botón de retroceso del AppBar → Navigator.pop automático
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
          // HU-03 Escenario 2: fecha y hora local del dispositivo
          final localDateStr = DateFormat('EEEE d MMMM yyyy, HH:mm', 'es')
              .format(match.localDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Equipos y marcador
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

                // Información adicional
                _InfoRow(icon: Icons.emoji_events, label: 'Fase', value: match.stageDisplay),

                // HU-03 Escenario 4: solo mostrar grupo si está definido (no null)
                if (match.group != null)
                  _InfoRow(icon: Icons.group_work, label: 'Grupo', value: match.group!),

                // HU-03 Escenario 2: estadio si está disponible
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
```

---

## 7. `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/matches/presentation/screens/home_screen.dart';

void main() {
  runApp(const Mundial2026App());
}

class Mundial2026App extends StatelessWidget {
  const Mundial2026App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundial 2026',
      debugShowCheckedModeBanner: false,

      // Localización en español para DatePicker (HU-02 Escenario 3)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'EC'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'EC'),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[700]!),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## 8. Icono del APK

El taller pide explícitamente crear un icono para el APK.

### 8.1 Preparar el asset

Coloca tu imagen PNG (1024×1024 px mínimo) en `assets/icon/app_icon.png`.

### 8.2 Generación con `flutter_launcher_icons`

Agrega en `pubspec.yaml` (dev_dependencies):

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
```

Agrega la configuración al final del mismo `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false           # Solo APK Android para este taller
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#1B5E20"  # Verde oscuro del tema
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  min_sdk_android: 21
```

Ejecuta:

```bash
dart run flutter_launcher_icons
flutter build apk --release
```

---

## 9. Pasos de configuración inicial

1. **Obtener API key gratuita** en https://www.football-data.org/client/register (sin tarjeta, en 60 seg).
2. Reemplazar `TU_API_KEY_AQUI` en `lib/core/network/dio_client.dart`.
3. Agregar `flutter_localizations` al `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
   ```
4. Ejecutar `flutter pub get`.
5. Ejecutar `flutter run`.

---

## 10. Matriz de cobertura — Criterios de Aceptación

| HU | Escenario | Cómo se cumple |
|----|-----------|----------------|
| HU-01 | E1: Hay partidos hoy | `ListView.builder` muestra tarjetas con equipos, marcador/vs, estadio o fase |
| HU-01 | E2: No hay partidos hoy | `matches.isEmpty` → `Text('No hay partidos del Mundial en esta fecha')` centrado |
| HU-01 | E3: API falla / timeout | `DioException` capturado → `snapshot.hasError` → mensaje descriptivo con tipo de error |
| HU-01 | E4: Cargando | `ConnectionState.waiting` → `CircularProgressIndicator()` centrado |
| HU-02 | E1: Fecha con partidos | `showDatePicker` → nueva llamada `_getMatchesByDate(_selectedDate)` |
| HU-02 | E2: Fecha sin partidos | Misma lógica que HU-01 E2 |
| HU-02 | E3: DatePicker limita rango | `firstDate: _worldCupStart` / `lastDate: _worldCupEnd` en `showDatePicker` |
| HU-02 | E4: Cierra sin confirmar | `if (picked != null && picked != _selectedDate)` — no recarga si se cancela |
| HU-03 | E1: Navegar al detalle | `Navigator.push(…, MatchDetailScreen(matchId: …))` desde `MatchCard.onTap` |
| HU-03 | E2: Detalle completo | Muestra equipos, marcador/vs, estadio, grupo (si aplica), fase, hora local |
| HU-03 | E3: Volver al home | AppBar con `leading` automático → `Navigator.pop`; botón físico de Android |
| HU-03 | E4: Sin grupo (eliminatoria) | `if (match.group != null)` → campo omitido sin error ni espacio vacío |
| Icono APK | — | `flutter_launcher_icons` genera icono adaptativo para el APK release |