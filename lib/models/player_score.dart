import 'package:hive/hive.dart';

part 'player_score.g.dart';

@HiveType(typeId: 0)
class PlayerScore extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int wins;

  @HiveField(2)
  final int totalGames;

  @HiveField(3)
  final int roundsPerGame;

  PlayerScore({
    required this.name,
    required this.wins,
    required this.totalGames,
    required this.roundsPerGame,
  });

  double get winRate => totalGames > 0 ? (wins / totalGames) * 100 : 0;
  int get losses => totalGames - wins;

  String get rank {
    if (winRate >= 80) return "Master";
    if (winRate >= 60) return "Expert";
    if (winRate >= 40) return "Skilled";
    return "Beginner";
  }
}
