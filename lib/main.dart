import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

// Player Score Model
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

// Hive Type Adapter
class PlayerScoreAdapter extends TypeAdapter<PlayerScore> {
  @override
  final int typeId = 0;

  @override
  PlayerScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerScore(
      name: fields[0] as String,
      wins: fields[1] as int,
      totalGames: fields[2] as int,
      roundsPerGame: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerScore obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.wins)
      ..writeByte(2)
      ..write(obj.totalGames)
      ..writeByte(3)
      ..write(obj.roundsPerGame);
  }
}

// Score Manager using Hive
class ScoreManager {
  static const String _boxName = 'player_scores';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PlayerScoreAdapter());
    await Hive.openBox<PlayerScore>(_boxName);
  }

  static Future<List<PlayerScore>> getScores({int? roundsFilter}) async {
    final box = Hive.box<PlayerScore>(_boxName);
    final scores = box.values.toList();

    // Apply rounds filter if specified
    if (roundsFilter != null) {
      return scores
          .where((score) => score.roundsPerGame == roundsFilter)
          .toList()
        ..sort((a, b) => b.winRate.compareTo(a.winRate));
    }

    // Sort by win rate
    scores.sort((a, b) => b.winRate.compareTo(a.winRate));
    return scores;
  }

  static Future<List<int>> getAvailableRoundFilters() async {
    final box = Hive.box<PlayerScore>(_boxName);
    return box.values.map((score) => score.roundsPerGame).toSet().toList()
      ..sort();
  }

  static Future<void> saveScore(PlayerScore newScore) async {
    final box = Hive.box<PlayerScore>(_boxName);

    // Find existing player with the same name and rounds
    final existingScores = box.values
        .where((score) =>
            score.name == newScore.name &&
            score.roundsPerGame == newScore.roundsPerGame)
        .toList();

    if (existingScores.isNotEmpty) {
      // Update existing player's score
      final existingScore = existingScores.first;
      final updatedScore = PlayerScore(
        name: newScore.name,
        wins: existingScore.wins + newScore.wins,
        totalGames: existingScore.totalGames + newScore.totalGames,
        roundsPerGame: newScore.roundsPerGame,
      );

      // Delete old entry
      await existingScore.delete();

      // Add updated entry
      await box.add(updatedScore);
    } else {
      // Add new player
      await box.add(newScore);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await ScoreManager.initialize();

  // Now run the app
  runApp(const RockPaperScissorsApp());
}

class RockPaperScissorsApp extends StatelessWidget {
  const RockPaperScissorsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rock Paper Scissors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedRounds = 3;
  final List<int> _roundOptions = [1, 3, 5, 7, 10];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF2D0036),
              Color(0xFF5B0085),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ROCK PAPER SCISSORS',
                      style: GoogleFonts.audiowide(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 50),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Enter Your Name',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              hintStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.purple.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.purple, width: 2),
                              ),
                              prefixIcon:
                                  Icon(Icons.person, color: Colors.purple[200]),
                            ),
                          ),
                          SizedBox(height: 25),
                          Text(
                            'Select Number of Rounds',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _roundOptions.map((rounds) {
                                bool isSelected = _selectedRounds == rounds;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedRounds = rounds;
                                    });
                                  },
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.purple
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        rounds.toString(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              if (_nameController.text.trim().isNotEmpty) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                      playerName: _nameController.text.trim(),
                                      rounds: _selectedRounds,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter your name'),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'START GAME',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RankingsScreen(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.leaderboard,
                                    color: Colors.purple[300]),
                                SizedBox(width: 8),
                                Text(
                                  'VIEW RANKINGS',
                                  style: TextStyle(
                                    color: Colors.purple[300],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String playerName;
  final int rounds;

  const GameScreen({
    Key? key,
    required this.playerName,
    required this.rounds,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final List<String> choices = ['Rock', 'Paper', 'Scissors'];
  final Map<String, IconData> choiceIcons = {
    'Rock': Icons.sports_mma,
    'Paper': Icons.article_outlined,
    'Scissors': Icons.content_cut,
  };

  String? userChoice;
  String? computerChoice;
  String? result;
  bool showResult = false;
  int currentRound = 1;
  int playerWins = 0;
  int computerWins = 0;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playGame(String selectedChoice) {
    // Reset animation if it's showing
    if (showResult) {
      _animationController.reverse().then((_) {
        setState(() {
          showResult = false;
        });
        _playTurn(selectedChoice);
      });
    } else {
      _playTurn(selectedChoice);
    }
  }

  void _playTurn(String selectedChoice) {
    final random = Random();
    final computerSelectedChoice = choices[random.nextInt(choices.length)];

    String gameResult;
    if (selectedChoice == computerSelectedChoice) {
      gameResult = "It's a tie!";
    } else if ((selectedChoice == 'Rock' &&
            computerSelectedChoice == 'Scissors') ||
        (selectedChoice == 'Paper' && computerSelectedChoice == 'Rock') ||
        (selectedChoice == 'Scissors' && computerSelectedChoice == 'Paper')) {
      gameResult = "You Won!";
      playerWins++;
    } else {
      gameResult = "You Lost!";
      computerWins++;
    }

    setState(() {
      userChoice = selectedChoice;
      computerChoice = computerSelectedChoice;
      result = gameResult;
      showResult = true;
    });

    _animationController.forward();

    // Check if game is over
    if (currentRound >= widget.rounds) {
      // Save the score
      ScoreManager.saveScore(
        PlayerScore(
          name: widget.playerName,
          wins: playerWins,
          totalGames: widget.rounds,
          roundsPerGame: widget.rounds,
        ),
      );

      // Show game over dialog after a delay
      Future.delayed(Duration(milliseconds: 800), () {
        _showGameOverDialog();
      });
    } else {
      setState(() {
        currentRound++;
      });
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D0036),
                Color(0xFF5B0085),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Over!',
                style: GoogleFonts.audiowide(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                playerWins > computerWins
                    ? 'Congratulations, ${widget.playerName}!'
                    : playerWins == computerWins
                        ? "It's a tie!"
                        : 'Better luck next time!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildScoreRow('Your Score', playerWins),
                    SizedBox(height: 10),
                    _buildScoreRow('Computer Score', computerWins),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => RankingsScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'RANKINGS',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'PLAY AGAIN',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF2D0036),
              Color(0xFF5B0085),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with rankings button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.leaderboard, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RankingsScreen(),
                          ),
                        );
                      },
                    ),
                    Text(
                      'Round $currentRound/${widget.rounds}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Score: $playerWins-$computerWins',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          'ROCK PAPER SCISSORS',
                          style: GoogleFonts.audiowide(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Text(
                        widget.playerName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      // Game result area
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _animation.value,
                              child: Transform.scale(
                                scale: 0.8 + (_animation.value * 0.2),
                                child: child,
                              ),
                            );
                          },
                          child: showResult
                              ? Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 30, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: result == "You Won!"
                                        ? Colors.purple.withOpacity(0.7)
                                        : result == "You Lost!"
                                            ? Colors.deepPurple.withOpacity(0.7)
                                            : Colors.grey.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        result!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildChoiceDisplay(
                                              'You', userChoice!),
                                          Text(
                                            'VS',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          _buildChoiceDisplay(
                                              'CPU', computerChoice!),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.purple.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Make your move',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Game controls
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'Choose your weapon',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: choices.map((choice) {
                                return _buildChoiceButton(choice);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String choice) {
    return GestureDetector(
      onTap: () => _playGame(choice),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              choiceIcons[choice],
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              choice,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceDisplay(String player, String choice) {
    return Column(
      children: [
        Text(
          player,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white24,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                choiceIcons[choice],
                size: 30,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Text(
                choice,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  List<PlayerScore> _playerScores = [];
  bool _isLoading = true;
  int? _selectedRoundFilter;
  List<int> _availableRoundFilters = [];

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
    });

    // Get available round filters
    final roundFilters = await ScoreManager.getAvailableRoundFilters();

    // Load scores (initially without filter)
    final scores = await ScoreManager.getScores();

    setState(() {
      _playerScores = scores;
      _availableRoundFilters = roundFilters;
      _isLoading = false;
    });
  }

  Future<void> _applyRoundFilter(int? rounds) async {
    setState(() {
      _isLoading = true;
      _selectedRoundFilter = rounds;
    });

    final scores = await ScoreManager.getScores(roundsFilter: rounds);

    setState(() {
      _playerScores = scores;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF2D0036),
              Color(0xFF5B0085),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'PLAYER RANKINGS',
                        style: GoogleFonts.audiowide(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),

              // Round filter section
              if (_availableRoundFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Rounds:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // "All" filter option
                            _buildRoundFilterChip(null, "All"),
                            ...(_availableRoundFilters.map(
                              (rounds) => _buildRoundFilterChip(
                                  rounds, rounds.toString()),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Results section
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                        ),
                      )
                    : _playerScores.isEmpty
                        ? _buildEmptyState()
                        : _buildRankingsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundFilterChip(int? rounds, String label) {
    final isSelected = _selectedRoundFilter == rounds;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _applyRoundFilter(rounds),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            "${label} Rounds",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.purple.withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            'No Rankings Yet',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Play some games to see rankings here',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => WelcomeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'START PLAYING',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _playerScores.length,
      itemBuilder: (context, index) {
        final score = _playerScores[index];
        final isTopThree = index < 3;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isTopThree
                ? Colors.purple.withOpacity(0.3)
                : Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isTopThree
                  ? Colors.purple.withOpacity(0.6)
                  : Colors.purple.withOpacity(0.2),
              width: isTopThree ? 2 : 1,
            ),
            boxShadow: isTopThree
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: _buildRankBadge(index + 1),
            title: Text(
              score.name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatChip(
                      '${score.winRate.toStringAsFixed(1)}%',
                      'Win Rate',
                      Colors.green.withOpacity(0.2),
                    ),
                    SizedBox(width: 6),
                    _buildStatChip(
                      '${score.roundsPerGame}',
                      'Rounds',
                      Colors.orange.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.rank,
                  style: TextStyle(
                    color: _getRankColor(score.rank),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${score.wins}W - ${score.losses}L',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    IconData icon;
    Color color;

    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 2:
        icon = Icons.star;
        color = Colors.grey[300]!;
        break;
      case 3:
        icon = Icons.verified;
        color = Colors.brown[300]!;
        break;
      default:
        icon = Icons.circle;
        color = Colors.purple[200]!;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: rank <= 3 ? 22 : 0,
          ),
          if (rank > 3)
            Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Master':
        return Colors.amber;
      case 'Expert':
        return Colors.cyan;
      case 'Skilled':
        return Colors.green;
      default:
        return Colors.blue[200]!;
    }
  }
}
