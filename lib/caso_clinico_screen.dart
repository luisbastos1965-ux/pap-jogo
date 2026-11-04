import 'package:flutter/material.dart';

class CasoClinicoScreen extends StatefulWidget {
  final String qrData; // Ex: A câmara vai ler sempre "carta:14"

  const CasoClinicoScreen({super.key, required this.qrData});

  @override
  State<CasoClinicoScreen> createState() => _CasoClinicoScreenState();
}

class _CasoClinicoScreenState extends State<CasoClinicoScreen> {
  static const Color _accentCyan = Color(0xFF00E5FF);
  
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  late Map<String, dynamic> _currentCase;

  // SIMULA A BASE DE DADOS: O que define a história não é o QR Code, 
  // mas sim o perfil de quem está a jogar a app neste momento!
  String _perfilJogadorAtivo = 'infantil'; 

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  void _loadCase() {
    // Reset às respostas quando muda de perfil
    _selectedOptionIndex = null;
    _hasAnswered = false;

    // A APP CRUZA A CARTA LIDA COM O PERFIL DO JOGADOR
    if (_perfilJogadorAtivo == 'infantil') {
      _currentCase = {
        'titulo': 'PEDIATRIA - Febre Noturna',
        'paciente': 'Mãe do Leo (4 anos)',
        'sintomas': 'Febre de 38.5ºC há 24h, choro persistente.',
        'cenario': 'A mãe entra aflita porque o paracetamol em xarope acabou e o Leo recusa-se a engolir qualquer líquido, cuspindo tudo. O que recomendas?',
        'opcoes': [
          {'texto': 'Vender paracetamol em comprimidos e mandar esmagar na comida.', 'correta': false},
          {'texto': 'Recomendar paracetamol em supositórios (via retal).', 'correta': true},
          {'texto': 'Dar ibuprofeno em xarope com sabor a morango.', 'correta': false},
        ],
        'explicacao': 'Em crianças que vomitam ou recusam medicação oral, a via retal (supositórios) é a alternativa mais rápida, segura e eficaz para baixar a febre.',
        'xp': 100,
      };
    } else if (_perfilJogadorAtivo == 'adulto') {
      _currentCase = {
        'titulo': 'ADULTOS - Dor Muscular',
        'paciente': 'Rui, 32 anos',
        'sintomas': 'Dor lombar intensa, início súbito após ginásio.',
        'cenario': 'O Rui chega ao balcão a coxear após um treino de pernas pesado. Pede-te a pomada "mais forte que tiveres" e diz que quer voltar a treinar amanhã.',
        'opcoes': [
          {'texto': 'Vender diclofenac gel e recomendar repouso de 48h com aplicação de gelo.', 'correta': true},
          {'texto': 'Dar uma pomada de calor intenso para usar imediatamente após o treino.', 'correta': false},
          {'texto': 'Recomendar alongamentos e continuar a treinar por cima da dor.', 'correta': false},
        ],
        'explicacao': 'Em lesões musculares agudas, aplica-se frio (crioterapia) para reduzir a inflamação, seguido de anti-inflamatório tópico e repouso. O calor agravaria o edema.',
        'xp': 150,
      };
    } else {
      _currentCase = {
        'titulo': 'GERIATRIA - O Desespero da Tosse',
        'paciente': 'Sr. Joaquim, 65 anos',
        'sintomas': 'Tosse seca persistente, hipertensão controlada',
        'cenario': 'O Sr. Joaquim queixa-se que não dorme há 3 dias com tosse. Notas no sistema que ele aviou recentemente Enalapril. O que decides fazer?',
        'opcoes': [
          {'texto': 'Vender um xarope antitússico forte.', 'correta': false},
          {'texto': 'Explicar que a tosse pode ser efeito do Enalapril e encaminhar ao médico.', 'correta': true},
          {'texto': 'Recomendar rebuçados de mel e chás quentes.', 'correta': false},
        ],
        'explicacao': 'Inibidores da ECA (como o Enalapril) causam frequentemente tosse seca. O utente deve ser referenciado ao médico para possível troca de medicação.',
        'xp': 200,
      };
    }
  }

  void _confirmAnswer() {
    if (_selectedOptionIndex == null) return;
    setState(() => _hasAnswered = true);
    final bool isCorrect = _currentCase['opcoes'][_selectedOptionIndex]['correta'];
    _showResultBottomSheet(isCorrect);
  }

  void _showResultBottomSheet(bool isCorrect) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF1E1B26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined, color: isCorrect ? Colors.greenAccent : Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'RESPOSTA BRILHANTE!' : 'ALERTA CLÍNICO!',
                style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Text(_currentCase['explicacao'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              if (isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentCyan.withValues(alpha: 0.5))),
                  child: Text('+ ${_currentCase['xp']} mg ADQUIRIDOS', style: const TextStyle(color: _accentCyan, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
                    backgroundColor: isCorrect ? _accentCyan : Colors.white24,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isCorrect ? 'CONCLUIR CASO' : 'VOLTAR AO BALCÃO', style: TextStyle(fontWeight: FontWeight.w900, color: isCorrect ? Colors.black : Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accentCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CARTA DETETADA: ${widget.qrData}'.toUpperCase(),
          style: const TextStyle(color: _accentCyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SIMULADOR DO PERFIL DO JOGADOR (Para poderes testar a mudança na hora)
            Container(
              color: const Color(0xFF1E1B26),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Text('O JOGADOR É: ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'infantil', label: Text('Infantil')),
                      ButtonSegment(value: 'adulto', label: Text('Adulto')),
                      ButtonSegment(value: 'idoso', label: Text('Idoso')),
                    ],
                    selected: {_perfilJogadorAtivo},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _perfilJogadorAtivo = newSelection.first;
                        _loadCase(); // Recarrega a história consoante o jogador
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) return _accentCyan;
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) return Colors.black;
                        return Colors.white70;
                      }),
                      side: const WidgetStatePropertyAll(BorderSide(color: _accentCyan, width: 1)),
                      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E1B26), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: Colors.white54, size: 20),
                            const SizedBox(width: 8),
                            Text(_currentCase['paciente'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.medical_information_outlined, color: Colors.white54, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_currentCase['sintomas'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4))),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12, height: 1)),
                        Text(_currentCase['cenario'], style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('QUAL A TUA INTERVENÇÃO?', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  ...List.generate(_currentCase['opcoes'].length, (index) {
                    final isSelected = _selectedOptionIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _hasAnswered ? null : () => setState(() => _selectedOptionIndex = index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? _accentCyan.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? _accentCyan : Colors.white12, width: isSelected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? _accentCyan : Colors.white54),
                              const SizedBox(width: 16),
                              Expanded(child: Text(_currentCase['opcoes'][index]['texto'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.black, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, -10))]),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedOptionIndex == null || _hasAnswered ? null : _confirmAnswer,
                  style: ElevatedButton.styleFrom(backgroundColor: _accentCyan, disabledBackgroundColor: Colors.white10, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('CONFIRMAR DECISÃO', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}