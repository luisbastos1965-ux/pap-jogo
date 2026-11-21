import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pratica_ui_components.dart';
import 'caso_clinico_screen.dart';

class PraticaScreen extends StatefulWidget {
  const PraticaScreen({super.key});

  @override
  State<PraticaScreen> createState() => _PraticaScreenState();
}

class _PraticaScreenState extends State<PraticaScreen> with SingleTickerProviderStateMixin {
  // PALETA NIVEL 20: Adeus ciano fluorescente! Olá roxo sofisticado e lilás clínico.
  static const Color _primaryPurple = Color(0xFF512DA8);
  static const Color _accentLilac = Color(0xFFB39DDB);
  static const Color _surfaceDark = Color(0xFF1E1A2F);
  static const Duration _startTimeout = Duration(seconds: 15);

  late final AnimationController _pulseController;
  late final MobileScannerController _scannerController;

  bool _isScanning = true;
  Timer? _resumeTimer;
  Timer? _startWatchdog;
  bool _busy = false;
  String? _localError;
  String _diagnosticLog = '';

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
    
    _scannerController.addListener(_onScannerStateChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // NOVO: arranca a câmara automaticamente (pede permissão na 1.ª vez)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCamera();
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _startWatchdog?.cancel();
    _scannerController.removeListener(_onScannerStateChanged);
    _pulseController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  bool get _isSecureContext {
    if (!kIsWeb) return true;
    final base = Uri.base;
    return base.scheme == 'https' || base.host == 'localhost' || base.host == '127.0.0.1';
  }

  String _describeState(MobileScannerState s) =>
      'Init=${s.isInitialized} | Run=${s.isRunning} | Err=${s.error?.errorCode.name ?? 'None'}';

  void _onScannerStateChanged() {
    final s = _scannerController.value;
    if (s.isInitialized || s.error != null) {
      _startWatchdog?.cancel();
    }
  }

  void _armWatchdog() {
    _startWatchdog?.cancel();
    _startWatchdog = Timer(_startTimeout, () {
      if (!mounted) return;
      final s = _scannerController.value;
      if (!s.isInitialized && s.error == null) {
        setState(() {
          _localError = 'Timeout interno. O browser não emitiu o feed de vídeo.';
          _diagnosticLog += '[Falha] Watchdog detetou timeout após ${_startTimeout.inSeconds}s.\n';
        });
      }
    });
  }

  Future<void> _startCamera({bool isRetry = false}) async {
    if (_busy) return;
    
    setState(() {
      _busy = true;
      _localError = null;
      _diagnosticLog = '[Fase] Início do pedido de câmara.\n';
    });

    try {
      if (kIsWeb && !_isSecureContext) throw Exception('Contexto Inseguro. Requer HTTPS.');
      
      if (isRetry) {
        await _scannerController.stop();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      _armWatchdog();
      await _scannerController.start().timeout(_startTimeout);
      
    } on TimeoutException {
      if (mounted) setState(() => _localError = 'O pedido expirou. A câmara não respondeu a tempo.');
    } on MobileScannerException catch (_) {
      if (mounted) setState(() => _localError = 'Erro Nativo da Câmara.');
    } catch (_) {
      if (mounted) setState(() => _localError = 'Erro Desconhecido ao arrancar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pauseScanner() async {
    try {
      await _scannerController.pause();
    } catch (e) {
      debugPrint('Erro ao pausar: $e');
    }
  }

  Future<void> _resumeScanner() async {
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint('Erro ao retomar: $e');
    }
  }

  Future<void> _onQRDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;

    String? code;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        code = barcode.rawValue;
        break;
      }
    }
    if (code == null) return;

    _isScanning = false;
    await _pauseScanner();
    if (!mounted) return;

    final Uri? uri = Uri.tryParse(code);
    final bool isHttpUrl = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isHttpUrl) {
      await _openUrl(uri);
      
      _resumeTimer?.cancel();
      _resumeTimer = Timer(const Duration(seconds: 3), () async {
        if (!mounted) return;
        await _resumeScanner();
        if (mounted) _isScanning = true;
      });
      
    } else {
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CasoClinicoScreen(qrData: code!),
        ),
      );
      
      if (mounted) {
        await _resumeScanner();
        setState(() => _isScanning = true);
      }
    }
  }

  Future<void> _openUrl(Uri url) async {
    bool opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Erro: $e');
    }

    if (!opened && mounted) {
      _showSnack('Não foi possível abrir o link automaticamente.', background: Colors.red, duration: const Duration(seconds: 6));
    }
  }

  void _showSnack(String message, {required Color background, Color textColor = Colors.white, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: textColor)), backgroundColor: background, behavior: SnackBarBehavior.floating, duration: duration));
  }

  ({IconData icon, String title, String message}) _describeError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return (icon: Icons.no_photography_outlined, title: 'Acesso à câmara negado', message: 'Autoriza a câmara nas definições e tenta novamente.');
      case MobileScannerErrorCode.unsupported:
        return (icon: Icons.videocam_off_outlined, title: 'Câmara não suportada', message: 'Este dispositivo não suporta o acesso à câmara.');
      default:
        return (icon: Icons.videocam_off_outlined, title: 'Não foi possível iniciar', message: 'Verifica se a câmara não está a ser usada.');
    }
  }

  Widget _buildCenter(MobileScannerState state) {
    final error = state.error;

    if (error != null || _localError != null) {
      final info = error != null ? _describeError(error) : (icon: Icons.warning_amber_rounded, title: 'Erro ao iniciar câmara', message: _localError!);
      final footer = '$_diagnosticLog${_describeState(state)}\nAmbiente: ${kIsWeb ? 'Web' : 'Nativo'}';
      
      return ScannerErrorCard(icon: info.icon, title: info.title, message: info.message, buttonLabel: 'TENTAR NOVAMENTE', footer: footer, onRetry: () => _startCamera(isRetry: true));
    }

    if (!state.isInitialized) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: _surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accentLilac.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _accentLilac),
              const SizedBox(height: 16),
              const Text(
                'A inicializar sistema ótico...',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aguarde um momento',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return IgnorePointer(child: ScannerReticle(pulseController: _pulseController));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<MobileScannerState>(
        valueListenable: _scannerController,
        builder: (context, state, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onQRDetected,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error) => const SizedBox.shrink(),
                  placeholderBuilder: (context) => const SizedBox.shrink(),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45))),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    ScannerTopBar(onBackPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    _buildCenter(state),
                    const Spacer(),
                    const ScannerInstructionBox(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}