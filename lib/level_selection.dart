import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
          'SELECIONAR TURNO',
          style: TextStyle(
            color: Color(0xFF1E1B26),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: 460.0, 
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.70, 
          ),
          items: [
            _buildMedicineBox(1, 'Nível 1', 'Literacia Básica', '100 mg', 'Jovens • Introdução', '10 cápsulas', const Color(0xFFFF5757), true),
            _buildMedicineBox(2, 'Nível 2', 'Geral & Polimedicação', '200 mg', 'Comunidade e Seniores', '15 cápsulas', const Color(0xFFBCBCBC), true),
            _buildMedicineBox(3, 'Nível 3', 'Conhecimento Básico', '300 mg', 'Técnicos Auxiliares', '20 cápsulas', const Color(0xFF72A7C3), true),
            _buildMedicineBox(4, 'Nível 4', 'Conhecimento Avançado', '400 mg', 'Universitários', '20 cápsulas', const Color(0xFFFFC9EB), true),
            _buildMedicineBox(5, 'Nível 5', 'Mundo Real', '500 mg', 'Farmacêuticos', '25 cápsulas', const Color(0xFF9769AA), true),
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
    final Color bottomSubTextColor = isLightColor ? const Color(0xFF1E1B26).withOpacity(0.7) : Colors.white.withOpacity(0.8);

    return GestureDetector(
      onTap: () {
        if (levelNumber == 1 || levelNumber == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                levelName: level,
                themeColor: color,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$level em desenvolvimento para a próxima fase!'),
              backgroundColor: cardColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              color: cardColor.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // METADE SUPERIOR (Branca)
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
            
            // METADE INFERIOR (Colorida)
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
                    // Categoria/Público-alvo
                    Text(
                      category,
                      style: TextStyle(
                        color: bottomTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Pastilhas 3D
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
                                  color: Colors.black.withOpacity(0.12),
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
                    
                    // Rodapé
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