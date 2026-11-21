import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // true só quando o público é conhecido de facto (vem do Firestore ou foi
  // escolhido pelo utilizador). O valor 3 acima é apenas um valor por defeito.
  bool hasAudience = false;

  // true quando sabemos que users/{uid} já existe na cloud. Se for false, a
  // primeira gravação inclui também nome e público (cria o perfil em falta).
  bool _remoteProfileExists = false;

  /// Última falha ao gravar no Firestore (para mostrar ao jogador / diagnóstico).
  String? lastSyncError;

  /// Converte o valor guardado em `audience` (int, double ou String) num
  /// público válido (1 a 5). Devolve null se estiver em falta ou for inválido.
  static int? parseAudience(dynamic raw) {
    int? id;
    if (raw is int) {
      id = raw;
    } else if (raw is num) {
      id = raw.toInt();
    } else if (raw != null) {
      id = int.tryParse(raw.toString().trim());
    }
    return (id != null && id >= 1 && id <= 5) ? id : null;
  }

  /// Guarda em memória o perfil escolhido no registo, para o caso de o
  /// Firestore ainda não o ter (ex.: documento por criar ou escrita falhada).
  void applyLocalProfile({required String name, required int audience}) {
    playerName = name;
    selectedAudience = audience;
    hasAudience = true;
  }

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
    if (!hasAudience) return 'Sem público';
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

  /// Repõe o estado local. Chamar ao terminar sessão, para que a conta
  /// seguinte não herde o XP, o nível nem o público da anterior.
  void reset() {
    currentXP = 0;
    currentLevel = 1;
    nextLevelXP = 300;
    selectedAudience = 3;
    playerName = 'Farmacêutico';
    hasAudience = false;
    _remoteProfileExists = false;
    lastSyncError = null;
  }

  // Mantido por compatibilidade
  Future<void> init() async {
    await loadUserData();
  }

  // Carrega os dados do jogador diretamente da Cloud (Firestore)
  Future<void> loadUserData() async {
    final user = await _waitForUser();
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        playerName = data['name']?.toString() ?? 'Jogador';
        currentXP = (data['xp'] as num?)?.toInt() ?? 0;
        final int? audience = parseAudience(data['audience']);
        selectedAudience = audience ?? 3;
        hasAudience = audience != null;
        _remoteProfileExists = true;
        _calculateLevel();
      } else {
        _remoteProfileExists = false;
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do Firestore: $e');
    }
  }

  /// Soma XP e grava no Firestore. Devolve false se NÃO ficou gravado na cloud
  /// (o XP local já foi somado); o motivo fica em [lastSyncError].
  Future<bool> addXP(int amount) async {
    currentXP += amount;
    if (currentXP < 0) currentXP = 0;
    _calculateLevel();
    return _syncProgress();
  }

  Future<void> updateOfficialAudience(int newAudience) async {
    selectedAudience = newAudience;
    hasAudience = true;
    await _syncProgress(extra: {'audience': newAudience});
  }

  Future<void> resetProgress() async {
    currentXP = 0;
    currentLevel = 1;
    _calculateLevel();
    await _syncProgress();
  }

  // ------------------------------------------------------------------
  // Sincronização com o Firestore
  // ------------------------------------------------------------------

  /// Na PWA, `currentUser` pode ser null durante um instante após recarregar
  /// a página; espera até 3 s pela sessão restaurada.
  Future<User?> _waitForUser() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser;
    try {
      return await auth
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _progressPayload([Map<String, dynamic>? extra]) {
    return {
      'xp': currentXP,
      'level': currentLevel,
      'careerTitle': careerTitle,
      // Se o perfil ainda não existe na cloud, cria-o completo.
      if (!_remoteProfileExists) 'name': playerName,
      if (!_remoteProfileExists && hasAudience) 'audience': selectedAudience,
      ...?extra,
    };
  }

  /// Usa set(merge) em vez de update(): cria o documento se faltar e atualiza
  /// se existir. Em caso de permission-denied, renova o token e tenta 1 vez.
  Future<bool> _syncProgress({Map<String, dynamic>? extra}) async {
    final user = await _waitForUser();
    if (user == null) {
      lastSyncError = 'sem sessão iniciada';
      return false;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    for (int tentativa = 0; tentativa < 2; tentativa++) {
      try {
        await ref.set(_progressPayload(extra), SetOptions(merge: true));
        _remoteProfileExists = true;
        lastSyncError = null;
        return true;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && tentativa == 0) {
          try {
            await user.getIdToken(true); // token possivelmente desatualizado
          } catch (_) {}
          continue;
        }
        lastSyncError = '[${e.code}] ${e.message ?? ''}'.trim();
        debugPrint('Erro ao sincronizar progresso (uid ${user.uid}, '
            'anónimo: ${user.isAnonymous}): $e');
        return false;
      } catch (e) {
        lastSyncError = e.toString();
        debugPrint('Erro ao sincronizar progresso: $e');
        return false;
      }
    }
    return false;
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