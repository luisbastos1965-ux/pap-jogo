import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF4EFFA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CABEÇALHO
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
                        child: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700, size: 22),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'MANUAL DO ESTAGIÁRIO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),

              // 2. CONTEÚDO DAS REGRAS
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bem-vindo à\nPharma Inc.',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B26),
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Antes de iniciares o teu turno ao balcão, lê atentamente os procedimentos da farmácia.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Regra 1
                      _buildRuleItem(
                        icon: Icons.monitor_heart_rounded,
                        color: const Color(0xFF2196F3),
                        title: '1. Avaliação Clínica',
                        description: 'Em cada atendimento, irás ler o perfil do utente e os seus sintomas. Analisa bem antes de tomares uma decisão.',
                      ),
                      const SizedBox(height: 24),

                      // Regra 2
                      _buildRuleItem(
                        icon: Icons.medication_rounded,
                        color: const Color(0xFF4CAF50),
                        title: '2. Níveis e Dosagem',
                        description: 'As caixas na seleção de níveis representam diferentes dificuldades (de 100mg a 500mg). Diferentes cores representam diferentes públicos-alvo.',
                      ),
                      const SizedBox(height: 24),

                      // Regra 3
                      _buildRuleItem(
                        icon: Icons.stars_rounded,
                        color: const Color(0xFFFF9800),
                        title: '3. Progressão de Carreira',
                        description: 'Diagnósticos corretos dão-te Pontos de Experiência (XP). Acumula XP para subires de escalão no teu Perfil Clínico.',
                      ),
                      const SizedBox(height: 24),

                      // Regra 4
                      _buildRuleItem(
                        icon: Icons.assignment_late_rounded,
                        color: const Color(0xFFF44336),
                        title: '4. Feedback Pedagógico',
                        description: 'Quer acertes ou erres, receberás sempre a justificação técnica. O objetivo principal é a tua aprendizagem contínua.',
                      ),
                      const SizedBox(height: 48),

                      // Botão de fechar/entender
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                'LI E COMPREENDI AS REGRAS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildRuleItem({required IconData icon, required Color color, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B26),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}