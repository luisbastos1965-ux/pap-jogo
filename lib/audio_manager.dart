import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/widgets.dart'; // Necessário para o ciclo de vida da app

class AudioManager with WidgetsBindingObserver {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  
  AudioManager._internal() {
    // 1. Regista este manager para ouvir quando a app é minimizada ou reaberta
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _bgmPlayer = AudioPlayer();
  String _currentTrack = '';
  Timer? _fadeTimer;
  bool isMuted = false;

  // 2. OUVINTE DO SISTEMA OPERATIVO
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // App foi minimizada ou o ecrã desligou-se
      _bgmPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Jogador voltou à app
      if (!isMuted) {
        _bgmPlayer.resume();
      }
    }
  }

  // (Opcional) Limpeza caso algum dia precises de destruir o manager
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void toggleMute() {
    isMuted = !isMuted;
    _bgmPlayer.setVolume(isMuted ? 0.0 : 1.0);
  }

  Future<void> playCrossfade(String trackName) async {
    if (_currentTrack == trackName) return;
    _currentTrack = trackName;
    _fadeTimer?.cancel();

    if (_bgmPlayer.state == PlayerState.playing) {
      double vol = 1.0;
      _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        vol -= 0.1;
        if (vol <= 0.0) {
          timer.cancel();
          _startNewTrack(trackName);
        } else {
          if (!isMuted) _bgmPlayer.setVolume(vol);
        }
      });
    } else {
      _startNewTrack(trackName);
    }
  }

  Future<void> _startNewTrack(String trackName) async {
    await _bgmPlayer.stop();
    await _bgmPlayer.setVolume(0.0);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('sounds/$trackName'));

    double vol = 0.0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      vol += 0.05;
      if (vol >= 1.0) {
        vol = 1.0;
        timer.cancel();
      }
      if (!isMuted) _bgmPlayer.setVolume(vol);
    });
  }
}