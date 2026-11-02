import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'progress_manager.dart';
import 'quiz_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF673AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ESCOLHER PÚBLICO & MODO',
          style: TextStyle(
            color: Color(0xFF1E1B26),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: 460.0,
            initialPage: ProgressManager().selectedAudience - 1,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.72,
          ),
          items: [
            _buildMedicineBox(1, 'Nível 1', 'Reconhecer & Mitos', '100 mg', 'Juniores • Introdução', 'Modo Guiado', const Color(0xFFFF5757), true),
            _buildMedicineBox(2, 'Nível 2', 'Dia a Dia & Rótulos', '200 mg', 'Comunidade e Seniores', 'Sem Tempo', const Color(0xFFBCBCBC), true),
            _buildMedicineBox(3, 'Nível 3', 'Procedimento & Rigor', '300 mg', 'Técnicos Auxiliares (TAF)', 'Balcão & Receitas', const Color(0xFF72A7C3), true),
            _buildMedicineBox(4, 'Nível 4', 'Analisar & Justificar', '400 mg', 'Universitários', 'Mecanismos', const Color(0xFFFFC9EB), true),
            _buildMedicineBox(5, 'Nível 5', 'Decidir na Incerteza', '500 mg', 'Farmacêuticos', 'Risco-Benefício', const Color(0xFF9769AA), true),
          ],
        ),
      ),
    );
  }

  void _showModeSelector(int levelNumber, String level, String category, Color color) {
    final bool isOfficialAudience = ProgressManager().selectedAudience == levelNumber;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$level • $category',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B26),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOfficialAudience ? 'O Teu Público' : 'Desafio Extra',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color.computeLuminance() > 0.6 ? const Color(0xFF1E1B26) : color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Escolhe a vertente em que queres jogar:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // OPÇÃO 1: MODO TEORIA (QUIZ)
              _buildModeOption(
                icon: Icons.style_rounded,
                title: 'Modo Teoria (Quiz)',
                subtitle: 'Perguntas de escolha múltipla e verdadeira/falso deste baralho.',
                color: const Color(0xFF673AB7),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        levelName: level,
                        themeColor: color,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // OPÇÃO 2: MODO PRÁTICA (CASOS QR)
              _buildModeOption(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Modo Prática (Casos QR)',
                subtitle: 'Lê as cartas físicas QR e resolve casos clínicos adaptados a este nível.',
                color: const Color(0xFF2E7D32),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Leitor de Casos QR ($level) será ligado no próximo passo!'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B26),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineBox(int levelNumber, String level, String theme, String dosage, String category, String pillCount, Color color, bool isUnlocked) {
    final Color cardColor = isUnlocked ? color : Colors.grey.shade400;
    final Color topTextColor = isUnlocked ? const Color(0xFF1E1B26) : Colors.grey.shade500;

    final bool isLightColor = cardColor.computeLuminance() > 0.6;
    final Color bottomTextColor = isLightColor ? const Color(0xFF1E1B26) : Colors.white;
    final Color bottomSubTextColor = isLightColor
        ? const Color(0xFF1E1B26).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: () => _showModeSelector(levelNumber, level, category, cardColor),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: topTextColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          dosage,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      theme,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: bottomTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: List.generate(levelNumber, (index) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(-2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 2,
                                height: 22,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          pillCount,
                          style: TextStyle(
                            color: bottomTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pharma Inc.',
                          style: TextStyle(
                            color: bottomSubTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}