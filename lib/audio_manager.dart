import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart';

/// Gestor da música de fundo (BGM) com crossfade seguro.
///
/// Regras:
///  * Só existe UMA transição a mexer no player de cada vez (fila `_queue`),
///    por isso nunca há dois `stop()/play()` em simultâneo (é isso que causava
///    o atropelo, sobretudo em Flutter Web).
///  * Cada pedido novo incrementa `_transitionSeq`. Qualquer fade ou `await`
///    de uma transição anterior vê que já não é a mais recente e termina logo,
///    sem voltar a mexer no volume nem a iniciar faixas.
///  * Ordem de cada transição: fade-out -> stop -> volume 0 -> play -> fade-in.
class AudioManager with WidgetsBindingObserver {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Durações (equivalentes às que já existiam: ~0,9 s a sair, ~1,8 s a entrar)
  static const Duration _fadeOutMax = Duration(milliseconds: 900);
  static const Duration _fadeOutMin = Duration(milliseconds: 120);
  static const Duration _fadeInDuration = Duration(milliseconds: 1800);
  static const Duration _fadeTick = Duration(milliseconds: 50);

  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool isMuted = false;

  /// Última faixa PEDIDA (o destino). Serve para ignorar pedidos repetidos.
  String _currentTrack = '';

  /// Faixa que está realmente carregada no player ('' se não houver nenhuma).
  String _playingTrack = '';

  /// Nível do fade (0.0 a 1.0), independente do mute.
  double _fadeVolume = 0.0;

  /// Identificador da transição mais recente.
  int _transitionSeq = 0;

  /// Fila: cada transição só começa quando a anterior terminou.
  Future<void> _queue = Future<void>.value();

  Timer? _fadeTimer;
  Completer<bool>? _fadeCompleter;

  bool _pausedByLifecycle = false;
  bool _disposed = false;

  // ------------------------------------------------------------------
  // Ciclo de vida da app
  // ------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedByLifecycle = true;
      if (_playingTrack.isNotEmpty) {
        unawaited(_bgmPlayer.pause().catchError((Object e) {
          debugPrint('[Audio] pause falhou: $e');
        }));
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_pausedByLifecycle) return;
      _pausedByLifecycle = false;
      // Retoma sempre que houver faixa carregada. Se estiver em mute o volume
      // do player já é 0, por isso fica em silêncio mas pronta a ser ouvida
      // quando o mute for desligado.
      if (_playingTrack.isNotEmpty) {
        unawaited(_bgmPlayer.resume().catchError((Object e) {
          debugPrint('[Audio] resume falhou: $e');
        }));
      }
    }
  }

  void dispose() {
    _disposed = true;
    _transitionSeq++;
    _cancelFade();
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
  }

  // ------------------------------------------------------------------
  // Mute
  // ------------------------------------------------------------------
  void toggleMute() {
    isMuted = !isMuted;
    _setPlayerVolume(isMuted ? 0.0 : _fadeVolume);
  }

  // ------------------------------------------------------------------
  // API pública
  // ------------------------------------------------------------------

  /// Muda para [trackName] com fade-out -> stop -> fade-in.
  /// Pode ser chamada várias vezes seguidas: só a última prevalece e nunca
  /// há duas faixas a tocar ao mesmo tempo.
  Future<void> playCrossfade(String trackName) {
    if (_disposed) return Future<void>.value();
    if (trackName == _currentTrack) return _queue;

    _currentTrack = trackName;
    final int seq = ++_transitionSeq;
    _cancelFade(); // acaba já com o fade da transição anterior

    final Future<void> run = _queue.then((_) => _runTransition(trackName, seq));
    _queue = run.catchError((Object _) {});
    return run;
  }

  // ------------------------------------------------------------------
  // Transição (corre sempre uma de cada vez)
  // ------------------------------------------------------------------
  Future<void> _runTransition(String trackName, int seq) async {
    bool stale() => _disposed || seq != _transitionSeq;
    if (stale()) return;

    try {
      // A faixa pedida ainda está carregada (ex.: A -> B -> A depressa):
      // basta voltar a subir o volume.
      if (_playingTrack == trackName) {
        await _fade(seq, 1.0, _fadeInDuration);
        return;
      }

      // 1) FADE-OUT (proporcional ao volume atual, para não esperar 0,9 s
      //    quando a faixa anterior ainda mal se ouvia)
      if (_playingTrack.isNotEmpty &&
          !isMuted &&
          !_pausedByLifecycle &&
          _fadeVolume > 0.01) {
        final int ms = (_fadeOutMax.inMilliseconds * _fadeVolume)
            .clamp(_fadeOutMin.inMilliseconds, _fadeOutMax.inMilliseconds)
            .round();
        final bool done = await _fade(seq, 0.0, Duration(milliseconds: ms));
        if (!done || stale()) return;
      }
      if (stale()) return;

      // 2) STOP
      await _bgmPlayer.stop();
      _playingTrack = '';
      if (stale()) return;

      // 3) Volume a 0 antes de carregar a nova faixa
      _fadeVolume = 0.0;
      await _bgmPlayer.setVolume(0.0);
      if (stale()) return;

      // 4) Loop + PLAY
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      if (stale()) return;
      await _bgmPlayer.play(AssetSource('sounds/$trackName'));
      // A faixa já está a tocar (a volume 0), mesmo que o pedido entretanto
      // tenha ficado obsoleto: a transição seguinte trata dela.
      _playingTrack = trackName;
      if (_pausedByLifecycle) await _bgmPlayer.pause();
      if (stale()) return;

      // 5) FADE-IN
      await _fade(seq, 1.0, _fadeInDuration);
    } catch (e) {
      debugPrint('[Audio] Não foi possível iniciar "$trackName": $e');
      _playingTrack = '';
      _fadeVolume = 0.0;
      // Só limpa o destino se ninguém pediu outra faixa entretanto,
      // para que um novo pedido da mesma faixa volte a tentar.
      if (seq == _transitionSeq) _currentTrack = '';
      try {
        await _bgmPlayer.stop();
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------------
  // Fades
  // ------------------------------------------------------------------

  /// Faz o fade até [to]. Devolve true se chegou ao fim e false se foi
  /// cancelado (nova transição, dispose).
  Future<bool> _fade(int seq, double to, Duration duration) {
    _cancelFade();
    if (_disposed || seq != _transitionSeq) return Future<bool>.value(false);

    final double from = _fadeVolume;
    if (isMuted || duration == Duration.zero || (to - from).abs() < 0.01) {
      _applyVolume(to);
      return Future<bool>.value(true);
    }

    final Completer<bool> completer = Completer<bool>();
    _fadeCompleter = completer;
    final Stopwatch sw = Stopwatch()..start();

    _fadeTimer = Timer.periodic(_fadeTick, (_) {
      if (_disposed || seq != _transitionSeq) {
        _finishFade(false);
        return;
      }
      final double t =
          (sw.elapsedMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0).toDouble();
      _applyVolume(from + (to - from) * t);
      if (t >= 1.0) _finishFade(true);
    });

    return completer.future;
  }

  void _finishFade(bool completed) {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    final Completer<bool>? c = _fadeCompleter;
    _fadeCompleter = null;
    if (c != null && !c.isCompleted) c.complete(completed);
  }

  void _cancelFade() => _finishFade(false);

  void _applyVolume(double v) {
    _fadeVolume = v.clamp(0.0, 1.0).toDouble();
    if (!isMuted) _setPlayerVolume(_fadeVolume);
  }

  void _setPlayerVolume(double v) {
    unawaited(_bgmPlayer.setVolume(v).catchError((Object e) {
      debugPrint('[Audio] setVolume falhou: $e');
    }));
  }
}
