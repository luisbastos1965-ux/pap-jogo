import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'audio_manager.dart';
import 'progress_manager.dart';

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
  static const int _xpReward = 150;

  final AudioPlayer _sfxPlayer = AudioPlayer();

  static const Color _bg = Color(0xFF1E1B26);
  static const Color _ok = Color(0xFF00E676);
  static const Color _ko = Color(0xFFFF5252);

  Color get _accent => Color.lerp(widget.themeColor, Colors.white, 0.3)!;

  List<Map<String, dynamic>> _perguntas = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final List<String> letters = const ['A', 'B', 'C', 'D'];

  int get correctAnswerIndex {
    if (_perguntas.isEmpty) return 0;
    final String letra =
        (_perguntas[_currentIndex]['resposta_correta'] ?? 'A').toString();
    return letters.indexOf(letra.toUpperCase());
  }

  List<String> get currentOptions {
    if (_perguntas.isEmpty) return [];
    var p = _perguntas[_currentIndex];
    return [
      p['opcao_a']?.toString() ?? '',
      p['opcao_b']?.toString() ?? '',
      p['opcao_c']?.toString() ?? '',
      p['opcao_d']?.toString() ?? ''
    ];
  }

  static const List<String> _audienceNames = [
    'Jovens',
    'Comunidade',
    'TAF',
    'Universitários',
    'Farmacêuticos',
  ];

  int get _levelNumber {
    final match = RegExp(r'\d+').firstMatch(widget.levelName);
    return match != null ? int.parse(match.group(0)!) : 1;
  }

  String get _levelLabel {
    final n = _levelNumber;
    if (n >= 1 && n <= _audienceNames.length) return _audienceNames[n - 1];
    return widget.levelName;
  }

  IconData _getIconForLevel() {
    switch (_levelNumber) {
      case 1: return Icons.headphones_rounded;
      case 2: return Icons.family_restroom_rounded;
      case 3: return Icons.medication_rounded;
      case 4: return Icons.school_rounded;
      case 5: return Icons.science_rounded;
      default: return Icons.local_pharmacy_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    AudioManager().playCrossfade('quiz_bgm.mp3');
    _carregarPerguntas();
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    AudioManager().playCrossfade('bgm.mp3');
    super.dispose();
  }

  // --- FUNÇÃO DO FIREBASE ---
  Future<void> _carregarPerguntas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questoes')
          .where('nivel', isEqualTo: _levelNumber)
          .get();

      setState(() {
        _perguntas = snapshot.docs.map((doc) => doc.data()).toList();
        _perguntas.shuffle(); // Baralha a ordem das perguntas
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar o Firestore: $e");
      setState(() => _isLoading = false);
    }
  }

  void _playSound(String fileName) {
    _sfxPlayer.play(AssetSource('sounds/$fileName'));
  }

  void _select(int index) {
    if (isAnswered) return;
    setState(() => selectedOption = index);
    HapticFeedback.selectionClick();
    _playSound('click.mp3');
  }

  void _confirm() {
    if (selectedOption == null || isAnswered) return;
    setState(() => isAnswered = true);

    if (selectedOption == correctAnswerIndex) {
      _playSound('correct.mp3');
      ProgressManager().addXP(_xpReward);
      HapticFeedback.mediumImpact();
    } else {
      _playSound('wrong.mp3');
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ecrã de loading enquanto vai ao Firebase
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    // Se o nível ainda não tiver perguntas na base de dados
    if (_perguntas.isEmpty) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Nenhuma pergunta encontrada para este nível.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Positioned(
              bottom: -60,
              right: -50,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    _getIconForLevel(),
                    size: 320,
                    color: widget.themeColor.withValues(alpha: 0.04), 
                  ),
                ),
              ),
            ),
            Positioned(
              top: -160,
              left: -80,
              right: -80,
              child: IgnorePointer(
                child: Hero(
                  tag: 'level_bg_${widget.levelName}', 
                  child: Container(
                    height: 420,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          widget.themeColor.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCaseCard(),
                              const SizedBox(height: 24),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeIn,
                                layoutBuilder: (current, previous) => Stack(
                                  fit: StackFit.passthrough,
                                  alignment: Alignment.topCenter,
                                  children: [...previous, if (current != null) current],
                                ),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: isAnswered
                                    ? _buildResultPanel(key: const ValueKey('result'))
                                    : _buildOptions(key: const ValueKey('options')),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(child: _buildConfirmPill()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(_getIconForLevel(), size: 16, color: _accent),
                const SizedBox(width: 6),
                Text(
                  '${_levelLabel.toUpperCase()} · ${_levelNumber * 100} MG',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          _buildPillProgress(),
        ],
      ),
    );
  }

  Widget _buildPillProgress() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        bool isActive = index < _levelNumber;
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  Widget _buildCaseCard() {
    return Container(
      padding: const EdgeInsets.all(1.5), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.themeColor.withValues(alpha: 0.8),
            widget.themeColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.themeColor.withValues(alpha: 0.20),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _bg, 
          borderRadius: BorderRadius.circular(22.5), 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.5),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _perguntas[_currentIndex]['pergunta'], // <- PERGUNTA DO FIREBASE
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < currentOptions.length; i++) ...[
          _buildOptionTile(i),
          if (i < currentOptions.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOptionTile(int index) {
    final bool isSelected = selectedOption == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      ),
      child: GestureDetector(
        onTap: () => _select(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(isSelected ? 1.02 : 1.0, isSelected ? 1.02 : 1.0, 1.0),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.themeColor.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _accent : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? _accent : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    letters[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isSelected ? _bg : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  currentOptions[index], // <- OPÇÃO DO FIREBASE
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.88),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPill() {
    final bool visible = selectedOption != null && !isAnswered;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        offset: visible ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _confirm,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: _bg, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'CONFIRMAR',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: _bg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel({Key? key}) {
    final bool isCorrect = selectedOption == correctAnswerIndex;
    final Color c = isCorrect ? _ok : _ko;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.18),
                border: Border.all(color: c.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                color: c,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCorrect ? 'CERTO!' : 'INCORRETO',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: c,
                ),
              ),
            ),
            if (isCorrect)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '+$_xpReward XP',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: c,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAnswerBlock(
          index: selectedOption!, 
          title: 'A TUA RESPOSTA', 
          color: c,
          showExplanation: isCorrect, // <-- Se acertou mostra, se errou esconde
        ),
        
        if (!isCorrect) ...[
          const SizedBox(height: 12),
          _buildAnswerBlock(
            index: correctAnswerIndex, 
            title: 'RESPOSTA CORRETA', 
            color: _ok,
            showExplanation: true, // <-- Na caixa da resposta certa mostra sempre
          ),
        ],
        const SizedBox(height: 20),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildAnswerBlock({
    required int index,
    required String title,
    required Color color,
    bool showExplanation = true, // <-- NOVO PARÂMETRO
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    letters[index],
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _bg),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentOptions[index],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          // Se o parâmetro showExplanation for true, mostra a linha divisória e o texto do Porquê
          if (showExplanation) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: color.withValues(alpha: 0.25)),
            ),
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  'PORQUÊ?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _perguntas[_currentIndex]['explicacao'],
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE6E3F0),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_currentIndex < _perguntas.length - 1) {
            setState(() {
              _currentIndex++;
              selectedOption = null;
              isAnswered = false;
            });
          } else {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity, // <-- Estica para ocupar a largura toda
          padding: const EdgeInsets.symmetric(vertical: 16), // Um pouco mais alto para ser fácil de clicar
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center, // <-- Centra o texto e o ícone
            children: [
              Text(
                'PRÓXIMA CÁPSULA',
                style: TextStyle(
                  fontSize: 13, // Aumentei ligeiramente (de 12.5 para 13) para compensar o botão maior
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: _bg,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: _bg, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}