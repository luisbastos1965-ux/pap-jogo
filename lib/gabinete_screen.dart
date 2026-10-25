import 'package:flutter/material.dart';
import 'progress_manager.dart';

class GabineteScreen extends StatelessWidget {
  const GabineteScreen({super.key});

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Limpar Memória?'),
            ],
          ),
          content: const Text('Todo o XP e níveis acumulados serão apagados. O sistema voltará ao estado inicial. Continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Chama a função de reset (vamos criá-la no ProgressManager a seguir)
                ProgressManager().resetProgress();
                Navigator.pop(context); // Fecha o dialog
                Navigator.pop(context); // Volta ao menu inicial para atualizar a UI
              },
              child: const Text('LIMPAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EFFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1B26)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'O GABINETE',
          style: TextStyle(color: Color(0xFF1E1B26), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CRÉDITOS DA PAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF673AB7), letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildCreditCard('Desenvolvimento & Conteúdo', 'Alunas do Curso Técnico de Farmácia\nEscola Profissional Profitecla do Porto', Icons.science_rounded),
            const SizedBox(height: 12),
            _buildCreditCard('Orientação Tecnológica', 'Professor Luís Bastos', Icons.code_rounded),
            
            const Spacer(),
            
            const Text('SISTEMA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('LIMPAR PROGRESSO DO ESTAGIÁRIO', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showResetDialog(context),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF673AB7).withValues(alpha: 0.1), child: Icon(icon, color: const Color(0xFF673AB7))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}