import 'package:flutter/material.dart';
import 'dart:math' as math;

class GabineteScreen extends StatelessWidget {
  const GabineteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);
    const accentGreen = Color(0xFF00E676);
    const accentPink = Color(0xFFFF4081);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26),
      body: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _buildMolecule(primary.withValues(alpha: 0.12), 220)),
          Positioned(bottom: 50, left: -70, child: _buildMolecule(accentCyan.withValues(alpha: 0.08), 260)),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gabinete',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        
                        _buildCreditCard(
                          'Autoras do Projeto', 
                          'Ana Rodrigues, Catarina Almeida, Mafalda Cruz e Duda Fernandes',
                          'Alunas do Curso Técnico de Farmácia', 
                          Icons.science_rounded, 
                          primary
                        ),
                        const SizedBox(height: 12),
                        
                        _buildCreditCard(
                          'Orientação e Desenvolvimento', 
                          'Luís Bastos',
                          'Professor Orientador e Arquiteto Digital', 
                          Icons.developer_mode_rounded, 
                          accentCyan
                        ),
                        const SizedBox(height: 12),
                        
                        _buildCreditCard(
                          'Revisão Científica e Pedagógica', 
                          'Bruno Ponte e Patrícia Franco',
                          'Apoio teórico e validação de conteúdos', 
                          Icons.fact_check_rounded, 
                          accentGreen
                        ),
                        const SizedBox(height: 12),
                        
                        _buildCreditCard(
                          'Agradecimentos Institucionais', 
                          'Escola Profissional Profitecla do Porto',
                          'A todas as entidades de aplicação prática e profissionais entrevistados pelo tempo cedido.', 
                          Icons.account_balance_rounded, 
                          accentPink
                        ),
                        
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildCreditCard(String title, String names, String role, IconData icon, Color highlightColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha o ícone ao topo se o texto for longo
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 4), // Pequeno ajuste para alinhar com o título
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: highlightColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: highlightColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(names, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.3)),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}