import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:math' as math;
import 'progress_manager.dart';
import 'quiz_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  
  Widget _buildMolecule(Color color, double size) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 3),
          border: Border.all(color: color, width: 4),
        ),
        child: Center(
          child: Container(
            width: size / 2,
            height: size / 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF673AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: _buildMolecule(const Color(0xFF673AB7).withValues(alpha: 0.05), 220),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: _buildMolecule(const Color(0xFF673AB7).withValues(alpha: 0.03), 260),
          ),
          
          Center(
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
        ],
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
      // AQUI ESTÁ A MAGIA: Navega direto para o QuizScreen!
      onTap: () {
        if (isUnlocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                levelName: level,
                themeColor: cardColor,
              ),
            ),
          );
        }
      },
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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