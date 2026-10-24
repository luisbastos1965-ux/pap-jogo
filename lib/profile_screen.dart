import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              // 1. CABEÇALHO (Botão de Voltar e Título)
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
                        'PERFIL CLÍNICO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42), // Espaçador para centrar o título
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // 2. AVATAR E INFO PRINCIPAL
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: Color(0xFFF4EFFA),
                              child: Icon(Icons.person_rounded, size: 48, color: primaryColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aluno Profitecla',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B26),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Técnico de Farmácia em Formação',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. BARRA DE PROGRESSO E NÍVEL (XP)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars_rounded, color: Colors.amber.shade600, size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'NÍVEL 3',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '1,250 / 2,000 XP',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.625, // 1250 / 2000
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                color: primaryColor,
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Faltam 750 XP para desbloquear "Farmacêutico Sénior"',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. ESTATÍSTICAS RÁPIDAS
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.cases_rounded,
                            iconColor: const Color(0xFF2196F3),
                            value: '42',
                            label: 'Casos\nResolvidos',
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            icon: Icons.track_changes_rounded,
                            iconColor: const Color(0xFF4CAF50),
                            value: '85%',
                            label: 'Taxa de\nPrecisão',
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFFF9800),
                            value: '7',
                            label: 'Dias\nSeguidos',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 5. CONQUISTAS / BADGES
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CONQUISTAS RECENTES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildBadgeItem(
                            icon: Icons.health_and_safety_rounded,
                            title: 'Protetor Gástrico',
                            subtitle: 'Receitou medicação de suporte com sucesso.',
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(height: 12),
                          _buildBadgeItem(
                            icon: Icons.warning_rounded,
                            title: 'Olho Clínico',
                            subtitle: 'Evitou uma interação medicamentosa grave.',
                            color: const Color(0xFFF44336),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
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

  // Widget construtor para os quadrados de Estatísticas
  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget construtor para as Conquistas
  Widget _buildBadgeItem({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.3,
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