import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProgressManager {
  static final ProgressManager _instance = ProgressManager._internal();
  factory ProgressManager() => _instance;
  ProgressManager._internal();

  int currentXP = 0;
  int currentLevel = 1; // 1 a 5 (Estagiário/a a Diretor/a Técnico/a)
  int nextLevelXP = 300;
  int selectedAudience = 3; // 1: Juniores, 2: Comunidade, 3: TAF, 4: Univ, 5: Farmacêuticos
  String playerName = 'Farmacêutico';

  String get careerTitle {
    switch (currentLevel) {
      case 1:
        return 'Estagiário/a';
      case 2:
        return 'Auxiliar';
      case 3:
        return 'Técnico/a Júnior';
      case 4:
        return 'Técnico/a Sénior';
      case 5:
      default:
        return 'Diretor/a Técnico/a';
    }
  }

  String get audienceName {
    switch (selectedAudience) {
      case 1:
        return 'Juniores';
      case 2:
        return 'Comunidade';
      case 3:
        return 'TAF';
      case 4:
        return 'Universitários';
      case 5:
      default:
        return 'Farmacêuticos';
    }
  }

  // Mantido por compatibilidade
  Future<void> init() async {
    await loadUserData();
  }

  // Carrega os dados do jogador diretamente da Cloud (Firestore)
  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        playerName = data['name'] ?? 'Jogador';
        currentXP = data['xp'] ?? 0;
        selectedAudience = data['audience'] ?? 3;
        _calculateLevel();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do Firestore: $e');
    }
  }

  // Adiciona XP e sincroniza imediatamente com a Cloud
  Future<void> addXP(int amount) async {
    currentXP += amount;
    if (currentXP < 0) currentXP = 0;
    _calculateLevel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'xp': currentXP,
        'level': currentLevel,
        'careerTitle': careerTitle,
      });
    }
  }

  Future<void> updateOfficialAudience(int newAudience) async {
    selectedAudience = newAudience;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'audience': selectedAudience,
      });
    }
  }

  Future<void> resetProgress() async {
    currentXP = 0;
    currentLevel = 1;
    _calculateLevel();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'xp': 0,
        'level': 1,
        'careerTitle': careerTitle,
      });
    }
  }

  void _calculateLevel() {
    if (currentXP < 300) {
      currentLevel = 1;
      nextLevelXP = 300;
    } else if (currentXP < 800) {
      currentLevel = 2;
      nextLevelXP = 800;
    } else if (currentXP < 1500) {
      currentLevel = 3;
      nextLevelXP = 1500;
    } else if (currentXP < 2500) {
      currentLevel = 4;
      nextLevelXP = 2500;
    } else {
      currentLevel = 5;
      nextLevelXP = 5000;
    }
  }
}