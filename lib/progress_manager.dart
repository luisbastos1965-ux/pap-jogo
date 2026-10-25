import 'package:shared_preferences/shared_preferences.dart';

class ProgressManager {
  static final ProgressManager _instance = ProgressManager._internal();
  factory ProgressManager() => _instance;
  ProgressManager._internal();

  int currentXP = 0;
  int currentLevel = 1;
  int nextLevelXP = 500;

  // Carrega o XP quando a app arranca
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentXP = prefs.getInt('xp') ?? 0;
    _calculateLevel();
  }

  // Adiciona XP e guarda no telemóvel
  Future<void> addXP(int amount) async {
    currentXP += amount;
    _calculateLevel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', currentXP);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', 0);
    await prefs.setInt('level', 1);
    currentXP = 0;
    currentLevel = 1;
  }

  // Define as balizas de XP para cada Nível
  void _calculateLevel() {
    if (currentXP < 500) {
      currentLevel = 1;
      nextLevelXP = 500;
    } else if (currentXP < 1500) {
      currentLevel = 2;
      nextLevelXP = 1500;
    } else if (currentXP < 3500) {
      currentLevel = 3;
      nextLevelXP = 3500;
    } else {
      currentLevel = 4;
      nextLevelXP = 6000;
    }
  }
}