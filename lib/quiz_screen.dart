import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'audio_manager.dart';
import 'progress_manager.dart'; // Import necessário para o XP

class QuizScreen extends StatefulWidget {
  final String levelName;
  final Color themeColor;

  const QuizScreen({
    super.key,
    required this.levelName,
    required this.themeColor,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? selectedOption;
  bool isAnswered = false;
  
  final int correctAnswerIndex = 1; 
  
  final AudioPlayer _sfxPlayer = AudioPlayer();

  final List<String> options = [
    'Recomendar a toma de 1g a cada 8 horas, acompanhado de protetor gástrico.',
    'Não dispensar. Encaminhar para o médico, dado o risco de toxicidade hepática grave.',
    'Reduzir a dose para 500mg por dia e monitorizar o utente durante a semana.',
    'Sugerir a troca imediata para Ibuprofeno 400mg, por ser mais seguro para o fígado.',
  ];

  final List<String> letters = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    AudioManager().playCrossfade('quiz_bgm.mp3');
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    AudioManager().playCrossfade('bgm.mp3');
    super.dispose();
  }

  void _playSound(String fileName) {
    _sfxPlayer.play(AssetSource('sounds/$fileName'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CABEÇALHO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05), 
                              blurRadius: 10, 
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.close_rounded, color: Colors.grey.shade700, size: 22),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_pharmacy_rounded, size: 16, color: widget.themeColor),
                          const SizedBox(width: 6),
                          Text(
                            widget.levelName.toUpperCase(),
                            style: TextStyle(
                              color: widget.themeColor, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 13, 
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),

              // BARRA DE PROGRESSO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CÁPSULA 1 DE 10', 
                          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1.0),
                        ),
                        Icon(Icons.monitor_heart_outlined, size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.1, 
                        backgroundColor: Colors.grey.shade300, 
                        color: widget.themeColor, 
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              
              // CARTÃO CLÍNICO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.12), 
                        blurRadius: 24, 
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, 
                        height: 180,
                        decoration: BoxDecoration(
                          color: widget.themeColor, 
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16), 
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medical_information_rounded, size: 18, color: Colors.grey.shade500),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CASO CLÍNICO #01', 
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0), 
                                child: Divider(height: 1),
                              ),
                              const Text(
                                'Um utente de 65 anos pede uma embalagem de paracetamol para dores articulares, mas refere que sofre de insuficiência hepática grave. Qual deve ser a sua recomendação?',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w700, 
                                  color: Color(0xFF1F2937), 
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // OPÇÕES DE RESPOSTA
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: isAnswered ? options.length + 1 : options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    
                    if (isAnswered && index == options.length) {
                      return _buildFeedbackPanel(selectedOption == correctAnswerIndex);
                    }

                    final bool isSelected = selectedOption == index;
                    final bool isCorrectOption = index == correctAnswerIndex;
                    
                    Color borderColor = Colors.grey.shade300;
                    Color bgColor = Colors.white;
                    Color markerBg = Colors.grey.shade100;
                    Color markerText = Colors.grey.shade600;
                    Color textColor = const Color(0xFF1F2937);
                    
                    if (isAnswered) {
                      if (isCorrectOption) {
                        borderColor = const Color(0xFF4CAF50); 
                        bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.08); 
                        markerBg = const Color(0xFF4CAF50); 
                        markerText = Colors.white; 
                        textColor = const Color(0xFF2E7D32);
                      } else if (isSelected) {
                        borderColor = const Color(0xFFE53935); 
                        bgColor = const Color(0xFFE53935).withValues(alpha: 0.08); 
                        markerBg = const Color(0xFFE53935); 
                        markerText = Colors.white; 
                        textColor = const Color(0xFFC62828);
                      } else {
                        bgColor = Colors.white.withValues(alpha: 0.5); 
                        textColor = Colors.grey.shade400;
                      }
                    } else if (isSelected) {
                      borderColor = widget.themeColor; 
                      bgColor = widget.themeColor.withValues(alpha: 0.08); 
                      markerBg = widget.themeColor; 
                      markerText = Colors.white;
                    }

                    return GestureDetector(
                      onTap: isAnswered ? null : () {
                        setState(() {
                          selectedOption = index;
                        });
                        _playSound('click.mp3'); 
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor, 
                            width: isSelected || (isAnswered && isCorrectOption) ? 2.5 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36, 
                              height: 36,
                              decoration: BoxDecoration(
                                color: markerBg, 
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: isAnswered && isCorrectOption 
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : isAnswered && isSelected && !isCorrectOption
                                    ? const Icon(Icons.close_rounded, color: Colors.white, size: 20)
                                    : Text(
                                        letters[index], 
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: markerText),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                options[index], 
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // BOTÃO DE AÇÃO
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity, 
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: selectedOption != null ? widget.themeColor : Colors.grey.shade200,
                    boxShadow: selectedOption != null ? [
                      BoxShadow(color: widget.themeColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 6))
                    ] : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: selectedOption == null ? null : () {
                        if (isAnswered) {
                          Navigator.pop(context); 
                        } else {
                          setState(() {
                            isAnswered = true;
                          });
                          
                          // Lógica de recompensa XP implementada
                          if (selectedOption == correctAnswerIndex) {
                            _playSound('correct.mp3');
                            ProgressManager().addXP(150); 
                          } else {
                            _playSound('wrong.mp3');
                          }
                        }
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAnswered ? 'PRÓXIMA CÁPSULA' : 'CONFIRMAR DIAGNÓSTICO',
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 1.5, 
                                color: selectedOption != null ? Colors.white : Colors.grey.shade400,
                              ),
                            ),
                            if (selectedOption != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPanel(bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF4CAF50).withValues(alpha: 0.1) : const Color(0xFFE53935).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? const Color(0xFF4CAF50).withValues(alpha: 0.3) : const Color(0xFFE53935).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.auto_awesome_rounded : Icons.info_outline_rounded, 
                color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'CERTO! PORQUÊ?' : 'INCORRETO! PORQUÊ?', 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w900, 
                  color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O Paracetamol tem um metabolismo hepático intenso. Numa insuficiência hepática grave, este fármaco torna-se altamente hepatotóxico. A dispensa está contraindicada sem reavaliação médica.',
            style: TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w600, 
              color: isCorrect ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C), 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}