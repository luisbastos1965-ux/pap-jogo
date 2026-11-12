import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CasoClinicoScreen extends StatefulWidget {
  final String qrData;

  const CasoClinicoScreen({super.key, required this.qrData});

  @override
  State<CasoClinicoScreen> createState() => _CasoClinicoScreenState();
}

class _CasoClinicoScreenState extends State<CasoClinicoScreen> {
  static const Color _primaryPurple = Color(0xFF5E35B1);

  int? _selectedOptionIndex;
  bool _hasAnswered = false;

  Map<String, dynamic>? _currentCase;
  bool _isLoading = true;
  String _errorMessage = '';

  String _perfilJogadorAtivo = '1';

  @override
  void initState() {
    super.initState();
    _loadCaseFromFirebase();
  }

  Future<void> _loadCaseFromFirebase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedOptionIndex = null;
      _hasAnswered = false;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('casos_praticos')
          .doc(widget.qrData.trim())
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['niveis'] != null && data['niveis'][_perfilJogadorAtivo] != null) {
          final levelData = data['niveis'][_perfilJogadorAtivo];

          final List<Map<String, dynamic>> opcoesMapeadas = [];
          List<dynamic> rawOpcoes = levelData['opcoes'] ?? [];
          String respostaCorreta = levelData['resposta_correta'] ?? '';

          for (int i = 0; i < rawOpcoes.length; i++) {
            String opcaoTexto = rawOpcoes[i].toString();
            final bool correta = respostaCorreta.isNotEmpty &&
                opcaoTexto.trim().toUpperCase().startsWith(
                  respostaCorreta.trim().toUpperCase(),
                );
            opcoesMapeadas.add({'texto': opcaoTexto, 'correta': correta});
          }

          // A limpar a formatação do ID para ficar bonito (ex: "CASO_001" -> "CASO 001")
          String idLimpo = (data['id'] ?? widget.qrData).toString().replaceAll('_', ' ');

          setState(() {
            _currentCase = {
              'id_bonito': idLimpo, // Novo campo para o AppBar
              'titulo': 'NÍVEL $_perfilJogadorAtivo',
              'paciente': data['titulo'] ?? 'Desconhecido',
              'sintomas': data['historia_base'] ?? '',
              'cenario': '${levelData['historia_extra'] ?? ''}\n\n${levelData['pergunta'] ?? ''}',
              'opcoes': opcoesMapeadas,
              'explicacao': levelData['explicacao'] ?? '',
              'xp': int.parse(_perfilJogadorAtivo) * 50,
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Nível $_perfilJogadorAtivo não configurado para este caso.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Caso Clínico (${widget.qrData}) não encontrado na base de dados.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de ligação: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmAnswer() {
    if (_selectedOptionIndex == null) return;
    setState(() => _hasAnswered = true);
    final bool isCorrect = _currentCase!['opcoes'][_selectedOptionIndex!]['correta'];
    _showResultBottomSheet(isCorrect);
  }

  // Função para abrir o menu elegante de troca de níveis
  void _mostrarSeletorNivelElegante() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SIMULAR PERFIL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Testa o caso com a dificuldade de outros níveis profissionais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,
                children: [
                  _botaoNivelCircular('1', 'Júnior'),
                  _botaoNivelCircular('2', 'Comunidade'),
                  _botaoNivelCircular('3', 'T.A.F.'),
                  _botaoNivelCircular('4', 'Universitário'),
                  _botaoNivelCircular('5', 'Farmacêutico'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _botaoNivelCircular(String nivel, String label) {
    bool isSelected = _perfilJogadorAtivo == nivel;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Fecha a bottom sheet
        if (!isSelected) {
          setState(() {
            _perfilJogadorAtivo = nivel;
            _loadCaseFromFirebase();
          });
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _primaryPurple : Colors.grey[100],
              border: Border.all(
                color: isSelected ? _primaryPurple : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _primaryPurple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Center(
              child: Text(
                nivel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _primaryPurple : Colors.black54,
            ),
          )
        ],
      ),
    );
  }

  void _showResultBottomSheet(bool isCorrect) {
    // (O teu código da bottom sheet de resposta mantém-se igualzinho. Não lhe toquei!)
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.warning_rounded,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  isCorrect ? 'DECISÃO SEGURA!' : 'ALERTA CLÍNICO!',
                  style: TextStyle(
                    color: isCorrect ? Colors.green[800] : Colors.red[800],
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentCase!['explicacao'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (isCorrect)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '+ ${_currentCase!['xp']} mg ADQUIRIDOS',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCorrect ? 'CONCLUIR CASO' : 'VOLTAR AO BALCÃO',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        // CABEÇALHO DINÂMICO!
        title: Text(
          _isLoading || _currentCase == null 
              ? 'A CARREGAR CARTA...' 
              : '${_currentCase!['id_bonito']}: ${_currentCase!['paciente']}'.toUpperCase(),
          style: const TextStyle(
            fontSize: 13, // Ligeiramente mais pequeno para caber melhor
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        // Ícone discreto na AppBar para mudar de nível (alternativa ao botão flutuante)
        actions: [
          if (!_isLoading && _errorMessage.isEmpty)
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded, size: 28),
              tooltip: 'Mudar Perfil',
              onPressed: _mostrarSeletorNivelElegante,
            )
        ],
      ),
      
      // O BOTÃO FLUTUANTE DISRUPTIVO (podes remover se preferires só o ícone da AppBar acima)
      floatingActionButton: (!_isLoading && _errorMessage.isEmpty && !_hasAnswered) 
        ? FloatingActionButton.extended(
            onPressed: _mostrarSeletorNivelElegante,
            backgroundColor: _primaryPurple,
            icon: const Icon(Icons.psychology_alt, color: Colors.white),
            label: Text('Simular Nível $_perfilJogadorAtivo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,

      body: SafeArea(
        child: Column(
          children: [
            // A BARRA HORIZONTAL "O JOGADOR É" FOI REMOVIDA DAQUI!

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryPurple),
                    )
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      // ... O teu ListView (Card do paciente e Opções) mantém-se igual! ...
                      // (Colei aqui o resto do teu código para não faltar nada)
                      children: [
                        Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: _primaryPurple,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded( // Usa Expanded caso o nome do paciente seja gigante
                                      child: Text(
                                        _currentCase!['paciente'],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primaryPurple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _currentCase!['titulo'],
                                        style: const TextStyle(
                                          color: _primaryPurple,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _currentCase!['sintomas'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    color: Colors.black12,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  _currentCase!['cenario'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'QUAL A TUA INTERVENÇÃO?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ...List.generate(_currentCase!['opcoes'].length, (index) {
                          final isSelected = _selectedOptionIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: _hasAnswered
                                  ? null
                                  : () => setState(() => _selectedOptionIndex = index),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryPurple : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _primaryPurple : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isSelected ? Colors.white : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _currentCase!['opcoes'][index]['texto'],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 80), // Espaço extra para o Floating Action Button não tapar as opções
                      ],
                    ),
            ),

            if (!_isLoading && _errorMessage.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedOptionIndex == null || _hasAnswered
                        ? null
                        : _confirmAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR DECISÃO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}