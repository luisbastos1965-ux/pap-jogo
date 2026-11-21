import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// -------------------------------------------------------------------------
// Tema de cada nível: nome, cor e ícone (mesmos ícones do modo quiz).
// Se as cores do level_selection.dart forem outras, muda-as aqui.
// -------------------------------------------------------------------------
class _NivelTema {
  final String nome;
  final Color cor;
  final IconData icone;
  const _NivelTema(this.nome, this.cor, this.icone);
}

const Map<String, _NivelTema> _temas = {
  '1': _NivelTema('Júnior', Color(0xFFFF4081), Icons.headphones_rounded),
  '2': _NivelTema('Comunidade', Color(0xFF26A69A), Icons.family_restroom_rounded),
  '3': _NivelTema('T.A.F.', Color(0xFFFFA726), Icons.medication_rounded),
  '4': _NivelTema('Universitário', Color(0xFF448AFF), Icons.school_rounded),
  '5': _NivelTema('Farmacêutico', Color(0xFFAB47BC), Icons.science_rounded),
};

class CasoClinicoScreen extends StatefulWidget {
  final String qrData;

  const CasoClinicoScreen({super.key, required this.qrData});

  @override
  State<CasoClinicoScreen> createState() => _CasoClinicoScreenState();
}

class _CasoClinicoScreenState extends State<CasoClinicoScreen> {
  static const Color _bg = Color(0xFF1E1B26);
  static const Color _ok = Color(0xFF00E676);
  static const Color _ko = Color(0xFFFF5252);
  static const List<String> _letras = ['A', 'B', 'C', 'D', 'E'];

  int? _selectedOptionIndex;
  bool _hasAnswered = false;

  Map<String, dynamic>? _currentCase;
  bool _isLoading = true;
  String _errorMessage = '';

  String _perfilJogadorAtivo = '1'; // nível que está a ser mostrado
  String _meuNivel = '1'; // público (audience) da conta do jogador
  Set<String> _niveisDisponiveis = {}; // níveis que existem neste caso no Firestore
  String _aviso = '';
  int _loadToken = 0; // evita que um carregamento antigo sobreponha um novo

  _NivelTema get _tema => _temas[_perfilJogadorAtivo] ?? _temas['1']!;
  Color get _cor => _tema.cor;
  Color get _accent => Color.lerp(_cor, Colors.white, 0.3)!;
  int get _nivelNum => int.tryParse(_perfilJogadorAtivo) ?? 1;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  // Lê o público (audience) da conta e abre o caso logo nesse nível
  Future<void> _iniciar() async {
    final String nivel = await _lerNivelDoJogador();
    if (!mounted) return;
    setState(() {
      _meuNivel = nivel;
      _perfilJogadorAtivo = nivel;
    });
    _loadCaseFromFirebase();
  }

  Future<String> _lerNivelDoJogador() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return '1';
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final dynamic a = doc.data()?['audience'];
      final int? n = a is num ? a.toInt() : int.tryParse(a?.toString() ?? '');
      if (n != null && n >= 1 && n <= _temas.length) return '$n';
    } catch (_) {}
    return '1';
  }

  // Nível disponível mais perto do pedido (em caso de empate, o mais baixo)
  String _maisProximo(String pedido, Set<String> disponiveis) {
    final int p = int.tryParse(pedido) ?? 1;
    final List<int> lista = disponiveis.map((e) => int.parse(e)).toList()
      ..sort((a, b) {
        final int da = (a - p).abs();
        final int db = (b - p).abs();
        return da != db ? da.compareTo(db) : a.compareTo(b);
      });
    return '${lista.first}';
  }

  // ------------------------------------------------------------------ DADOS
  Future<void> _loadCaseFromFirebase() async {
    final int token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _aviso = '';
      _selectedOptionIndex = null;
      _hasAnswered = false;
    });

    try {
      // Pequeno delay intencional para a animação de loading ter tempo de brilhar
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted || token != _loadToken) return;

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('casos_praticos')
          .doc(widget.qrData.trim())
          .get();
      if (!mounted || token != _loadToken) return;

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Caso Clínico (${widget.qrData}) não encontrado na base de dados.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final dynamic niveis = data['niveis'];
      final Map<String, dynamic> mapaNiveis =
          niveis is Map ? Map<String, dynamic>.from(niveis) : <String, dynamic>{};
      final Set<String> disponiveis =
          mapaNiveis.keys.where((k) => _temas.containsKey(k) && mapaNiveis[k] != null).toSet();

      if (disponiveis.isEmpty) {
        setState(() {
          _niveisDisponiveis = {};
          _errorMessage = 'Este caso ainda não tem nenhum nível configurado.';
          _isLoading = false;
        });
        return;
      }

      // Se o nível pedido não existir neste caso, mostra o mais próximo em vez de falhar
      String nivelAUsar = _perfilJogadorAtivo;
      String aviso = '';
      if (!disponiveis.contains(nivelAUsar)) {
        final String pedido = nivelAUsar;
        nivelAUsar = _maisProximo(pedido, disponiveis);
        aviso = 'Este caso ainda não tem versão para ${_temas[pedido]!.nome}. '
            'A mostrar a versão ${_temas[nivelAUsar]!.nome}.';
      }

      final Map<String, dynamic> levelData = Map<String, dynamic>.from(mapaNiveis[nivelAUsar] as Map);

      final List<dynamic> rawOpcoes = levelData['opcoes'] ?? [];
      final String respostaCorreta = (levelData['resposta_correta'] ?? '').toString();
      final List<Map<String, dynamic>> opcoesMapeadas = [];

      for (int i = 0; i < rawOpcoes.length; i++) {
        final String opcaoTexto = rawOpcoes[i].toString();
        final bool correta = respostaCorreta.isNotEmpty &&
            opcaoTexto.trim().toUpperCase().startsWith(respostaCorreta.trim().toUpperCase());
        opcoesMapeadas.add({'texto': opcaoTexto, 'correta': correta});
      }

      final String idLimpo = (data['id'] ?? widget.qrData).toString().replaceAll('_', ' ');

      setState(() {
        _niveisDisponiveis = disponiveis;
        _perfilJogadorAtivo = nivelAUsar;
        _aviso = aviso;
        _currentCase = {
          'id_bonito': idLimpo,
          'paciente': data['titulo'] ?? 'Desconhecido',
          'sintomas': data['historia_base'] ?? '',
          'cenario': '${levelData['historia_extra'] ?? ''}\n\n${levelData['pergunta'] ?? ''}'.trim(),
          'opcoes': opcoesMapeadas,
          'explicacao': levelData['explicacao'] ?? '',
          'xp': (int.tryParse(nivelAUsar) ?? 1) * 50,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _errorMessage = 'Erro de ligação: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _opcoes =>
      (_currentCase?['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // Tira o "A)" do início do texto, porque a letra já aparece no emblema
  String _semLetra(String t) => t.replaceFirst(RegExp(r'^\s*[A-Ea-e]\s*[\)\.\-:]\s*'), '');

  void _select(int index) {
    if (_hasAnswered) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedOptionIndex = index);
  }

  void _confirmAnswer() {
    if (_selectedOptionIndex == null || _hasAnswered) return;
    HapticFeedback.mediumImpact();
    setState(() => _hasAnswered = true);
    final bool isCorrect = _opcoes[_selectedOptionIndex!]['correta'] == true;
    _showResultBottomSheet(isCorrect);
  }

  // ------------------------------------------------------------ BOTTOM SHEETS
  void _mostrarSeletorNivel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: _cor.withValues(alpha: 0.4), width: 1.5),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SIMULAR PERFIL',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Testa o caso com a dificuldade de outros níveis profissionais.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (final nivel in ['1', '2', '3']) _botaoNivel(sheetContext, nivel)],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final nivel in ['4', '5'])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _botaoNivel(sheetContext, nivel),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _botaoNivel(BuildContext sheetContext, String nivel) {
    final _NivelTema t = _temas[nivel]!;
    final bool sel = _perfilJogadorAtivo == nivel;
    final bool disponivel = _niveisDisponiveis.isEmpty || _niveisDisponiveis.contains(nivel);
    final Color acc = Color.lerp(t.cor, Colors.white, 0.3)!;
    final String legenda = !disponivel ? 'Sem caso' : (nivel == _meuNivel ? 'O teu nível' : 'Nível $nivel');

    return GestureDetector(
      onTap: () {
        Navigator.pop(sheetContext);
        if (!disponivel) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Este caso ainda não tem versão para ${t.nome}.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          return;
        }
        if (!sel) {
          setState(() => _perfilJogadorAtivo = nivel);
          _loadCaseFromFirebase();
        }
      },
      child: Opacity(
        opacity: disponivel ? 1.0 : 0.35,
        child: SizedBox(
        width: 100,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? t.cor : t.cor.withValues(alpha: 0.12),
                border: Border.all(color: sel ? acc : t.cor.withValues(alpha: 0.4), width: 2),
                boxShadow: sel
                    ? [BoxShadow(color: t.cor.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6))]
                    : [],
              ),
              child: Icon(t.icone, color: sel ? Colors.white : acc, size: 26),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t.nome,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                  color: sel ? acc : Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              legenda,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: nivel == _meuNivel && disponivel ? FontWeight.w800 : FontWeight.w400,
                color: nivel == _meuNivel && disponivel ? acc : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showResultBottomSheet(bool isCorrect) {
    final Color c = isCorrect ? _ok : _ko;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: c.withValues(alpha: 0.45), width: 1.5),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.withValues(alpha: 0.18),
                    border: Border.all(color: c.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 24)],
                  ),
                  child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: c, size: 38),
                ),
                const SizedBox(height: 16),
                Text(
                  isCorrect ? 'DECISÃO SEGURA!' : 'ALERTA CLÍNICO!',
                  style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentCase!['explicacao'].toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.55),
                ),
                if (isCorrect) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tema.icone, size: 16, color: _accent),
                        const SizedBox(width: 8),
                        Text(
                          '+ ${_currentCase!['xp']} MG ADQUIRIDOS',
                          style: TextStyle(color: _accent, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect ? _accent : Colors.white.withValues(alpha: 0.12),
                      foregroundColor: isCorrect ? _bg : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isCorrect ? 'CONCLUIR CASO' : 'VOLTAR AO BALCÃO',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ BUILD
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: TweenAnimationBuilder<Color?>(
          // O fundo muda de cor suavemente quando troca de nível
          tween: ColorTween(end: _cor),
          duration: const Duration(milliseconds: 600),
          builder: (context, animated, _) {
            final Color c = animated ?? _cor;
            return Stack(
              children: [
                Positioned(
                  bottom: -60,
                  right: -50,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(_tema.icone, size: 320, color: c.withValues(alpha: 0.04)),
                    ),
                  ),
                ),
                Positioned(
                  top: -160,
                  left: -80,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      height: 420,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [c.withValues(alpha: 0.45), Colors.transparent]),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(c),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _buildBody(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return PharmaLoadingWidget(
        key: ValueKey('loading_$_perfilJogadorAtivo'),
        codigo: widget.qrData.trim().replaceAll('_', ' '),
        nivel: _perfilJogadorAtivo,
        cor: _cor,
        icone: _tema.icone,
      );
    }
    if (_errorMessage.isNotEmpty || _currentCase == null) {
      return KeyedSubtree(key: const ValueKey('erro'), child: _buildError());
    }
    return KeyedSubtree(
      key: ValueKey('caso_$_perfilJogadorAtivo'),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_aviso.isNotEmpty) ...[
                  _buildAviso(),
                  const SizedBox(height: 14),
                ],
                _buildCaseCard(),
                const SizedBox(height: 28),
                Text(
                  'QUAL A TUA INTERVENÇÃO?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < _opcoes.length; i++) ...[
                  _buildOptionTile(i),
                  if (i < _opcoes.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Positioned(bottom: 20, left: 0, right: 0, child: Center(child: _buildConfirmPill())),
        ],
      ),
    );
  }

  Widget _circleButton(Widget child, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      ),
    );
  }

  Widget _iconeFechar() => Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22);

  // Pessoa com um pequeno emblema de setas circulares = trocar de perfil
  Widget _iconeTrocaPerfil() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22),
          ),
          Positioned(
            right: -7,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _cor,
                shape: BoxShape.circle,
                border: Border.all(color: _bg, width: 1.5),
              ),
              child: const Icon(Icons.sync_rounded, color: Colors.white, size: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color c) {
    final bool podeTrocar = !_isLoading && !_hasAnswered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(_iconeFechar(), () => Navigator.pop(context)),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.lerp(c, Colors.white, 0.3)!.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tema.icone, size: 16, color: _accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_tema.nome.toUpperCase()} · NÍVEL $_perfilJogadorAtivo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          podeTrocar
              ? _circleButton(_iconeTrocaPerfil(), _mostrarSeletorNivel)
              : const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final bool isActive = index < _nivelNum;
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _accent : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  Widget _buildAviso() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _aviso,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard() {
    final String sintomas = _currentCase!['sintomas'].toString();

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cor.withValues(alpha: 0.8), _cor.withValues(alpha: 0.1), Colors.transparent],
        ),
        boxShadow: [BoxShadow(color: _cor.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 16))],
      ),
      child: Container(
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(22.5)),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _cor.withValues(alpha: 0.2)),
                  child: Icon(Icons.person_rounded, color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCase!['id_bonito'].toString().toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentCase!['paciente'].toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDots(),
              ],
            ),
            if (sintomas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information_outlined, color: Colors.white.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sintomas,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14, height: 1.45),
                    ),
                  ),
                ],
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            ),
            Text(
              _currentCase!['cenario'].toString(),
              style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final bool isSelected = _selectedOptionIndex == index;
    final String texto = _semLetra(_opcoes[index]['texto'].toString());
    final String letra = index < _letras.length ? _letras[index] : '${index + 1}';

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
            color: isSelected ? _cor.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _accent : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _cor.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))]
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
                    letra,
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
                  texto,
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

  Widget _pillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = true,
    bool glow = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: filled ? _accent : _cor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: filled ? null : Border.all(color: _accent.withValues(alpha: 0.5)),
            boxShadow: glow
                ? [BoxShadow(color: _cor.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: filled ? _bg : _accent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: filled ? _bg : _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPill() {
    final bool visible = _selectedOptionIndex != null && !_hasAnswered;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        offset: visible ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: _pillButton(label: 'CONFIRMAR DECISÃO', icon: Icons.check_rounded, onTap: _confirmAnswer, glow: true),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ko.withValues(alpha: 0.12),
                border: Border.all(color: _ko.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.error_outline_rounded, color: _ko, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15.5, height: 1.5),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _pillButton(label: 'TENTAR DE NOVO', icon: Icons.refresh_rounded, onTap: _loadCaseFromFirebase),
                _pillButton(
                  label: 'MUDAR DE NÍVEL',
                  icon: Icons.sync_alt_rounded,
                  onTap: _mostrarSeletorNivel,
                  filled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Loading temático: ondas a expandir à volta de um ícone a pulsar, na cor e
// com o ícone do nível, mais o código da carta e mensagens que vão mudando.
// -------------------------------------------------------------------------
class PharmaLoadingWidget extends StatefulWidget {
  final String codigo;
  final String nivel;
  final Color cor;
  final IconData icone;

  const PharmaLoadingWidget({
    super.key,
    required this.codigo,
    required this.nivel,
    required this.cor,
    required this.icone,
  });

  @override
  State<PharmaLoadingWidget> createState() => _PharmaLoadingWidgetState();
}

class _PharmaLoadingWidgetState extends State<PharmaLoadingWidget> with SingleTickerProviderStateMixin {
  static const List<String> _mensagens = [
    'A LER A CARTA...',
    'A CONSULTAR O PROCESSO CLÍNICO...',
    'A PREPARAR O BALCÃO...',
  ];

  late final AnimationController _controller;
  Timer? _timer;
  int _msgIndex = 0;

  Color get _accent => Color.lerp(widget.cor, Colors.white, 0.3)!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() => _msgIndex = (_msgIndex + 1) % _mensagens.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _onda(double t) {
    final double size = 84 + 100 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.cor.withValues(alpha: (1 - t) * 0.45), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Batimento duplo por ciclo
                final double pulso = 1 + 0.07 * math.sin(_controller.value * math.pi * 4);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 3; i++) _onda((_controller.value + i / 3) % 1.0),
                    Transform.scale(
                      scale: pulso,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_accent, widget.cor],
                          ),
                          boxShadow: [
                            BoxShadow(color: widget.cor.withValues(alpha: 0.5), blurRadius: 28, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Icon(widget.icone, size: 40, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.cor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${widget.codigo.toUpperCase()}  ·  NÍVEL ${widget.nivel}',
              style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _mensagens[_msgIndex],
                key: ValueKey<int>(_msgIndex),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                color: _accent,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}