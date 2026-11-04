import 'package:flutter/material.dart';
import 'dart:math' as math;

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCirc));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26), // Fundo escuro coeso com a Cédula
      body: Stack(
        children: [
          // Elementos moleculares de fundo subtis
          Positioned(top: -60, left: -60, child: _buildMolecule(primary.withValues(alpha: 0.12), 220)),
          Positioned(bottom: 50, right: -70, child: _buildMolecule(accentCyan.withValues(alpha: 0.08), 260)),

          SafeArea(
            child: Column(
              children: [
                // 1. CABEÇALHO DO MANUAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                        ),
                      ),
                      const SizedBox(width: 42), // Espaçador para centrar o título
                    ],
                  ),
                ),

                // 2. CONTEÚDO DAS REGRAS
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bem-vindo à\nPharma Inc.',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.8,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Antes de iniciares o teu turno ao balcão, lê atentamente os procedimentos da farmácia.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white60,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // Regra 1
                                  _buildProtocolCard(
                                    index: '01',
                                    title: '1. Avaliação Clínica',
                                    description: 'Em cada atendimento, irás ler o perfil do utente e os seus sintomas. Analisa bem antes de tomares uma decisão.',
                                    icon: Icons.monitor_heart_rounded,
                                    accentColor: accentCyan,
                                  ),
                                  const SizedBox(height: 20),

                                  // Regra 2
                                  _buildProtocolCard(
                                    index: '02',
                                    title: '2. Níveis e Dosagem',
                                    description: 'As caixas na seleção de níveis representam diferentes dificuldades (de 100mg a 500mg). Diferentes cores representam diferentes públicos-alvo.',
                                    icon: Icons.medication_rounded,
                                    accentColor: Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 20),

                                  // Regra 3
                                  _buildProtocolCard(
                                    index: '03',
                                    title: '3. Progressão de Carreira',
                                    description: 'Diagnósticos corretos dão-te Miligramas de Princípio Ativo (mg). Acumula mg para subires de escalão no teu Perfil Clínico.',
                                    icon: Icons.science_rounded, // Ícone atualizado para tema científico
                                    accentColor: Colors.amberAccent,
                                  ),
                                  const SizedBox(height: 20),

                                  // Regra 4
                                  _buildProtocolCard(
                                    index: '04',
                                    title: '4. Feedback Pedagógico',
                                    description: 'Quer acertes ou erres, receberás sempre a justificação técnica. O objetivo principal é a tua aprendizagem contínua.',
                                    icon: Icons.assignment_late_rounded,
                                    accentColor: Colors.purpleAccent,
                                  ),
                                  const SizedBox(height: 48),

                                  // Botão de fechar/entender (Estilo Néon)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        elevation: 10,
                                        shadowColor: primary.withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'LI E COMPREENDI AS REGRAS',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            width: size / 2, height: size / 2,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 4)),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolCard({
    required String index,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}