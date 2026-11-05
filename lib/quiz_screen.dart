import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int _xpReward = 150;

  final AudioPlayer _sfxPlayer = AudioPlayer();

  // PALETA (alinhada com o ecrã inicial escuro)
  static const Color _bg = Color(0xFF1E1B26);
  static const Color _ok = Color(0xFF00E676);
  static const Color _ko = Color(0xFFFF5252);

  // Versão mais clara da cor do nível, para texto/ícones legíveis em fundo escuro
  Color get _accent => Color.lerp(widget.themeColor, Colors.white, 0.3)!;

  final List<String> options = [
    'Recomendar a toma de 1g a cada 8 horas, acompanhado de protetor gástrico.',
    'Não dispensar. Encaminhar para o médico, dado o risco de toxicidade hepática grave.',
    'Reduzir a dose para 500mg por dia e monitorizar o utente durante a semana.',
    'Sugerir a troca imediata para Ibuprofeno 400mg, por ser mais seguro para o fígado.',
  ];

  // Uma explicação por opção: aparece a da opção escolhida (e a correta, se errar)
  final List<String> explanations = [
    'O protetor gástrico protege o estômago, não o fígado. Numa insuficiência hepática grave, 3g por dia de paracetamol continuam a representar um risco real de hepatotoxicidade.',
    'O Paracetamol tem um metabolismo hepático intenso. Numa insuficiência hepática grave, este fármaco torna-se altamente hepatotóxico. A dispensa está contraindicada sem reavaliação médica.',
    'Reduzir a dose não elimina o risco: na insuficiência hepática grave o problema é o fármaco em si, não só a quantidade. Ajustar doses e monitorizar é decisão médica, não do balcão.',
    'Os AINEs também não são seguros neste cenário: na doença hepática grave aumentam o risco de hemorragia digestiva e de lesão renal, e o utente tem 65 anos. Trocar de fármaco por iniciativa própria não resolve.',
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // HALO DE COR DO NÍVEL NO TOPO
            Positioned(
              top: -160,
              left: -80,
              right: -80,
              child: IgnorePointer(
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

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCaseCard(),
                              const SizedBox(height: 20),

                              // OPÇÕES  →  (após responder)  →  PAINEL DE EXPLICAÇÃO
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

                        // CONFIRMAR: pílula discreta que só aparece quando há uma opção escolhida
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

  // ───────────────────────── CABEÇALHO ─────────────────────────
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
                Icon(Icons.local_pharmacy_rounded, size: 16, color: _accent),
                const SizedBox(width: 6),
                Text(
                  widget.levelName.toUpperCase(),
                  style: TextStyle(
                    color: _accent,
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
    );
  }

  // ───────────────────────── CASO CLÍNICO ─────────────────────────
  Widget _buildCaseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: widget.themeColor.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra lateral que acompanha sempre a altura do cartão
              Container(width: 6, color: _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information_rounded, size: 18, color: _accent),
                          const SizedBox(width: 8),
                          Text(
                            'CASO CLÍNICO #01',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _accent,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Um utente de 65 anos pede uma embalagem de paracetamol para dores articulares, mas refere que sofre de insuficiência hepática grave. Qual deve ser a sua recomendação?',
                        style: TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── OPÇÕES ─────────────────────────
  Widget _buildOptions({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _buildOptionTile(i),
          if (i < options.length - 1) const SizedBox(height: 12),
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
                  options[index],
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

  // ───────────────────────── CONFIRMAR (discreto) ─────────────────────────
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

  // ───────────────────────── PAINEL DE RESULTADO ─────────────────────────
  Widget _buildResultPanel({Key? key}) {
    final bool isCorrect = selectedOption == correctAnswerIndex;
    final Color c = isCorrect ? _ok : _ko;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // VEREDICTO
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

        // OPÇÃO ESCOLHIDA + EXPLICAÇÃO
        _buildAnswerBlock(index: selectedOption!, title: 'A TUA RESPOSTA', color: c),

        // Se errou, mostra também a resposta correta com a sua explicação
        if (!isCorrect) ...[
          const SizedBox(height: 12),
          _buildAnswerBlock(index: correctAnswerIndex, title: 'RESPOSTA CORRETA', color: _ok),
        ],

        const SizedBox(height: 20),
        Align(alignment: Alignment.centerRight, child: _buildNextButton()),
      ],
    );
  }

  Widget _buildAnswerBlock({
    required int index,
    required String title,
    required Color color,
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
                  options[index],
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
            explanations[index],
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE6E3F0),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PRÓXIMA CÁPSULA',
                style: TextStyle(
                  fontSize: 12.5,
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