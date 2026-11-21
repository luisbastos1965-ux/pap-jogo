import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class DicaBalcaoCard extends StatefulWidget {
  const DicaBalcaoCard({super.key});

  @override
  State<DicaBalcaoCard> createState() => _DicaBalcaoCardState();
}

class _DicaBalcaoCardState extends State<DicaBalcaoCard> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShake = DateTime.now();

  final List<String> _dicas = [
    'O paracetamol tem um limite diário seguro de 4g para adultos.',
    'O ibuprofeno deve ser tomado de estômago cheio para evitar irritação gástrica.',
    'Os antibióticos perdem eficácia se a toma não for concluída, mesmo sem sintomas.',
    'A vitamina C melhora significativamente a absorção de ferro quando tomados juntos.',
    'Descongestionantes nasais não devem ser usados mais de 5 a 7 dias seguidos.',
    'O ácido fólico é crucial no 1º trimestre de gravidez para proteger o tubo neural.',
    'Probióticos devem ser tomados com 2 horas de intervalo da toma do antibiótico.',
    'Antiácidos podem inibir a absorção de outros medicamentos de toma regular.',
    'Xaropes para tosse seca não devem ser aconselhados para tosse com expetoração.',
    'A melatonina ajuda a induzir o sono, mas não atua como um sedativo forte.',
  ];
  late String _dicaAtual;

  @override
  void initState() {
    super.initState();
    _dicaAtual = _dicas[0];

    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (AccelerometerEvent event) {
            final magnitude = math.sqrt(
              event.x * event.x + event.y * event.y + event.z * event.z,
            );
            // ~9.8 em repouso; remove a gravidade
            final forca = (magnitude - 9.8).abs();

            if (forca > 6 &&
                DateTime.now().difference(_lastShake).inSeconds >= 1) {
              _lastShake = DateTime.now();
              _trocarDica();
            }
          },
          onError: (e) => debugPrint('Erro no acelerómetro: $e'),
          cancelOnError: false,
        );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _trocarDica() {
    if (!mounted) return;
    setState(() {
      String novaDica;
      do {
        novaDica = _dicas[math.Random().nextInt(_dicas.length)];
      } while (novaDica == _dicaAtual);
      _dicaAtual = novaDica;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    return GestureDetector(
      onTap: _trocarDica,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: accentCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _dicaAtual,
                      key: ValueKey<String>(_dicaAtual),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.screen_rotation_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Agita ou toca para trocar',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
