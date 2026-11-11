import 'package:flutter/material.dart';

// Paleta oficial Pharma Inc. (Roxos, Lilases e Escuros sofisticados)
const Color _primaryPurple = Color(0xFF512DA8);
const Color _accentLilac = Color(0xFFB39DDB);
const Color _surfaceDark = Color(0xFF1E1B26);

// 1. BARRA SUPERIOR
class ScannerTopBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  const ScannerTopBar({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: _accentLilac.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _accentLilac, size: 18),
              onPressed: onBackPressed,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentLilac.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: _accentLilac, size: 16),
                SizedBox(width: 8),
                Text(
                  'MODO PRÁTICA',
                  style: TextStyle(color: _accentLilac, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. MIRA ANIMADA (Viewfinder Clínico)
class ScannerReticle extends StatelessWidget {
  final AnimationController pulseController;
  const ScannerReticle({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(
              color: _accentLilac.withValues(alpha: 0.4 + (pulseController.value * 0.5)),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryPurple.withValues(alpha: 0.2 * pulseController.value),
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 250 * pulseController.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: _accentLilac,
                    boxShadow: [BoxShadow(color: _accentLilac, blurRadius: 12, spreadRadius: 3)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 3. CARTÃO DE ERRO E DIAGNÓSTICO
class ScannerErrorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final String? footer;
  final VoidCallback onRetry;

  const ScannerErrorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onRetry,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentLilac.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 25, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accentLilac, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
              child: Text(
                footer!,
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 4. CAIXA DE INSTRUÇÕES (Física)
class ScannerInstructionBox extends StatelessWidget {
  const ScannerInstructionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.style_rounded, color: _accentLilac, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'Escolhe a tua Carta',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Tira uma carta do baralho correspondente ao teu nível atual e faz o scan para iniciar o desafio clínico.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}