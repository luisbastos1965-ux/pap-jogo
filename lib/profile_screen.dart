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

  // Cores da cápsula (guardadas no Firestore: users/{uid}.capsuleTop / capsuleBottom)
  static const Color _defaultCapsuleTop = Color(0xFF9575CD);
  static const Color _defaultCapsuleBottom = Color(0xFF512DA8);
  Color _capsuleTop = _defaultCapsuleTop;
  Color _capsuleBottom = _defaultCapsuleBottom;

  static const List<Color> _capsulePalette = [
    Color(0xFF9575CD), // lilás
    Color(0xFF512DA8), // roxo escuro
    Color(0xFF42A5F5), // azul claro
    Color(0xFF1565C0), // azul
    Color(0xFF00BCD4), // ciano
    Color(0xFF0097A7), // ciano escuro
    Color(0xFF26A69A), // turquesa
    Color(0xFF00796B), // verde-água
    Color(0xFF66BB6A), // verde
    Color(0xFF388E3C), // verde escuro
    Color(0xFFFFA726), // laranja
    Color(0xFFEF6C00), // laranja escuro
    Color(0xFFEF5350), // vermelho
    Color(0xFFC62828), // vermelho escuro
    Color(0xFFEC407A), // rosa
    Color(0xFFAD1457), // magenta
    Color(0xFF8D6E63), // castanho
    Color(0xFF455A64), // cinza-azulado
  ];

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
          if (!mounted) return;
          final data = doc.data()!;
          setState(() {
            _firestoreUserName = data['name'] ?? user.displayName ?? 'Farmacêutico';
            _playerLicenseId = 'REG. Nº #$shortUid';
            _capsuleTop = _colorFromData(data['capsuleTop']) ?? _defaultCapsuleTop;
            _capsuleBottom = _colorFromData(data['capsuleBottom']) ?? _defaultCapsuleBottom;
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

  Color? _colorFromData(dynamic raw) {
    if (raw is num) return Color(raw.toInt());
    return null;
  }

  Future<void> _saveCapsuleColors(Color top, Color bottom) async {
    // Atualiza logo no ecrã e grava em segundo plano
    setState(() {
      _capsuleTop = top;
      _capsuleBottom = bottom;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'capsuleTop': top.toARGB32(),
        'capsuleBottom': bottom.toARGB32(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao guardar cores da cápsula: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível guardar as cores. Tenta de novo.')),
      );
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
                                  // AVATAR CÁPSULA (toca para personalizar as cores)
                                  GestureDetector(
                                    onTap: _isLoadingName ? null : () => _showCapsuleEditor(displayName),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildCapsuleAvatar(
                                          letter: displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F',
                                          top: _capsuleTop,
                                          bottom: _capsuleBottom,
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E1B26),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
                                            ),
                                            child: const Icon(Icons.palette_rounded, size: 16, color: Colors.cyanAccent),
                                          ),
                                        ),
                                      ],
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

  Widget _buildCapsuleAvatar({
    required String letter,
    required Color top,
    required Color bottom,
    double width = 110,
    double height = 150,
    double fontSize = 56,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 60 / 110),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            top,    // Metade superior
            bottom, // Metade inferior
          ],
          stops: const [0.5, 0.5], // Cria o corte seco bicolor da cápsula
        ),
        boxShadow: [
          BoxShadow(
            color: bottom.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), // simula o brilho do plástico
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black45, // Garante que a letra se lê por cima da linha de corte
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorRow(String label, Color selected, ValueChanged<Color> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _capsulePalette.map((c) {
            final bool isSelected = c == selected;
            return GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCapsuleEditor(String displayName) {
    final String letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F';
    Color tempTop = _capsuleTop;
    Color tempBottom = _capsuleBottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2635),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'PERSONALIZAR CÁPSULA',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _buildCapsuleAvatar(
                        letter: letter,
                        top: tempTop,
                        bottom: tempBottom,
                        width: 66,
                        height: 90,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildColorRow('PARTE SUPERIOR', tempTop, (c) => setSheetState(() => tempTop = c)),
                    const SizedBox(height: 20),
                    _buildColorRow('PARTE INFERIOR', tempBottom, (c) => setSheetState(() => tempBottom = c)),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.cyanAccent,
                              side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {
                              final rnd = math.Random();
                              Color pick() => _capsulePalette[rnd.nextInt(_capsulePalette.length)];
                              final Color newTop = pick();
                              Color newBottom = pick();
                              while (newBottom == newTop) {
                                newBottom = pick();
                              }
                              setSheetState(() {
                                tempTop = newTop;
                                tempBottom = newBottom;
                              });
                            },
                            icon: const Icon(Icons.casino_rounded, size: 18),
                            label: const Text('ALEATÓRIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF673AB7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {
                              _saveCapsuleColors(tempTop, tempBottom);
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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