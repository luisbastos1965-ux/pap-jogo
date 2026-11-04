import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'progress_manager.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  String _firestoreUserName = '';
  String _playerLicenseId = 'PI-0000';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCirc));
    _animController.forward();

    _fetchUserDataFromFirestore();
  }

  Future<void> _fetchUserDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Gera um número de cédula único e consistente baseado nos primeiros caracteres do UID
        final shortUid = user.uid.length >= 6 ? user.uid.substring(0, 6).toUpperCase() : '8492PI';
        
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _firestoreUserName = doc.data()!['name'] ?? user.displayName ?? 'Farmacêutico';
            _playerLicenseId = 'REG. Nº #$shortUid';
            _isLoadingName = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do Firestore: $e');
    }
    
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _firestoreUserName = user?.displayName ?? 'Farmacêutico';
        _playerLicenseId = 'REG. Nº #PI-2027';
        _isLoadingName = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Fim de Turno', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E1B26), fontSize: 18)),
          ],
        ),
        content: const Text('Vais desvincular a tua Cédula Profissional. Confirmas?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MANTER NO BALCÃO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _signOut(context);
            },
            child: const Text('SAIR DO SISTEMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const secondary = Color(0xFF512DA8);

    final String displayName = _isLoadingName ? 'A carregar...' : _firestoreUserName;
    final String careerTitle = ProgressManager().careerTitle;
    final String audienceName = ProgressManager().audienceName;

    final int xp = ProgressManager().currentXP;
    final int lvl = ProgressManager().currentLevel;
    final int nextXp = ProgressManager().nextLevelXP;
    final double progress = nextXp > 0 ? (xp / nextXp) : 0.0;
    final int missingXp = nextXp > xp ? (nextXp - xp) : 0;

    final String totalCuras = "0"; 
    final String taxaPrecisao = "0%";
    final String diasSeguidos = "0";

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26), 
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildMolecule(primary.withValues(alpha: 0.15), 200)),
          Positioned(bottom: 100, left: -80, child: _buildMolecule(const Color(0xFF2196F3).withValues(alpha: 0.1), 250)),
          
          SafeArea(
            child: Column(
              children: [
                // CABEÇALHO
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // <--- Isto empurra os elementos para as pontas opostas
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
      IconButton(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 24),
      ),
    ],
  ),
),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: Column(
                                children: [
                                  // AVATAR CÁPSULA
                                  Container(
                                    width: 110,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFF9575CD), // Metade superior
                                          secondary,               // Metade inferior
                                        ],
                                        stops: const [0.5, 0.5], // Cria o corte seco bicolor da cápsula
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.5), 
                                          blurRadius: 30, 
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3), // Aumentado ligeiramente para simular brilho do plástico
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F',
                                        style: const TextStyle(
                                          fontSize: 56, 
                                          fontWeight: FontWeight.w900, 
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45, // Garante que a letra se lê perfeitamente por cima da linha de corte
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // NOME / NICKNAME
                                  Text(
                                    displayName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // NÚMERO DE CÉDULA OFICIAL
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: Colors.cyanAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        _playerLicenseId,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.cyanAccent.withValues(alpha: 0.9),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // TAG CARREIRA E PÚBLICO
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: primary.withValues(alpha: 0.4)),
                                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 10)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.military_tech_rounded, size: 16, color: Colors.amber.shade400),
                                        const SizedBox(width: 6),
                                        Text(
                                          careerTitle.toUpperCase(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                          width: 4, height: 4,
                                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                                        ),
                                        Icon(Icons.group_rounded, size: 16, color: Colors.cyanAccent.shade400),
                                        const SizedBox(width: 6),
                                        Text(
                                          audienceName.toUpperCase(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // BARRA DE XP
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.medication_liquid_rounded, color: Colors.amberAccent, size: 20), // Ícone farmacêutico!
                                                const SizedBox(width: 8),
                                                Text('NÍVEL $lvl', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                              ],
                                            ),
                                            Text('$xp / $nextXp mg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        Container(
                                          height: 22,
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white24, width: 1.5),
                                          ),
                                          child: Stack(
                                            children: [
                                              FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: progress.clamp(0.0, 1.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF651FFF)]),
                                                    boxShadow: [
                                                      BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), blurRadius: 10),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Faltam $missingXp mg de Princípio Ativo para a próxima evolução.', 
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildCapsuleStat(icon: Icons.science_rounded, value: totalCuras, label: 'Curas', color: Colors.cyanAccent),
                                      _buildCapsuleStat(icon: Icons.radar_rounded, value: taxaPrecisao, label: 'Precisão', color: Colors.amberAccent),
                                      _buildCapsuleStat(icon: Icons.local_fire_department_rounded, value: diasSeguidos, label: 'Dias', color: Colors.deepOrangeAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 40),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('MOLÉCULAS DESBLOQUEADAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.white54)),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(28),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.biotech_rounded, color: Colors.white24, size: 36),
                                        SizedBox(height: 12),
                                        Text(
                                          'Ainda não sintetizaste nenhuma molécula rara.',
                                          style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 60),
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

  Widget _buildCapsuleStat({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(50), 
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}