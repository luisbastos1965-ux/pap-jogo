import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioManager {
  // Cria uma instância única (Singleton) para toda a app
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  String _currentTrack = '';
  Timer? _fadeTimer;

  // Função mágica que faz o fade out da música antiga e fade in da nova
  Future<void> playCrossfade(String trackName) async {
    if (_currentTrack == trackName) return; // Ignora se já for a mesma música

    _currentTrack = trackName;
    _fadeTimer?.cancel(); // Pára qualquer fade que estivesse a acontecer

    if (_bgmPlayer.state == PlayerState.playing) {
      // Faz o Fade Out suave
      double vol = 1.0;
      _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        vol -= 0.1;
        if (vol <= 0.0) {
          timer.cancel();
          _startNewTrack(trackName); // Arranca a nova quando a antiga silencia
        } else {
          _bgmPlayer.setVolume(vol);
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

    // Faz o Fade In da nova música
    double vol = 0.0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      vol += 0.05;
      if (vol >= 1.0) {
        vol = 1.0;
        timer.cancel();
      }
      _bgmPlayer.setVolume(vol);
    });
  }
}