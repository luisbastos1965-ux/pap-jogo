import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'main.dart';
import 'progress_manager.dart';

class _AudienceOption {
  final int level;
  final String title;
  const _AudienceOption(this.level, this.title);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isQuickMode = true;
  bool _isLogin = true;
  bool _isLoading = false;
  int? _selectedAudience; 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final _audiences = const [
    _AudienceOption(1, 'Juniores'),
    _AudienceOption(2, 'Comunidade'),
    _AudienceOption(3, 'TAF'),
    _AudienceOption(4, 'Universitários'),
    _AudienceOption(5, 'Farmacêuticos'),
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutQuart),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveUserToFirestore(User user, String defaultName) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    // Só cria o documento se ele não existir
    if (!doc.exists) {
      await docRef.set({
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : defaultName,
        // Usa o nível selecionado, ou assume 5 por segurança se criar conta via ecrã de Login acidentalmente
        'audience': _selectedAudience ?? 5, 
        'xp': 0,
        'level': 1,
        'careerTitle': 'Estagiário/a',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await ProgressManager().loadUserData();
  }

  void _navigateToMenu() {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuScreen()));
  }

  Future<void> _signInQuick() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Escreve o teu nome para o Acesso Rápido.');
      return;
    }
    if (_selectedAudience == null) {
      _showError('Por favor, seleciona o teu nível na escala.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      if (cred.user != null) {
        await _saveUserToFirestore(cred.user!, _nameController.text.trim());
        _navigateToMenu();
      }
    } catch (e) {
      _showError('Erro no Acesso Rápido: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    // SÓ EXIGE O NÍVEL SE ESTIVER NO MODO DE REGISTO (!isLogin)
    if (!_isLogin && _selectedAudience == null) {
      _showError('Seleciona o teu nível antes de continuar com Google.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } catch (popupError) {
        debugPrint('Popup bloqueado ou não suportado, a usar redirect: $popupError');
        await FirebaseAuth.instance.signInWithRedirect(googleProvider);
        return; 
      }

      if (cred.user != null) {
        // Se a conta já existir, o _saveUserToFirestore apenas ignora e avança
        await _saveUserToFirestore(cred.user!, cred.user!.displayName ?? 'Farmacêutico');
        _navigateToMenu();
      }
    } catch (e) {
      _showError('Erro ao entrar com Google: ${e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Preenche o email e a palavra-passe.');
      return;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showError('Preenche o teu nome para criar a conta.');
      return;
    }
    if (!_isLogin && _selectedAudience == null) {
      _showError('Por favor, seleciona o teu nível na escala.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        await ProgressManager().loadUserData();
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          await _saveUserToFirestore(cred.user!, _nameController.text.trim());
        }
      }
      _navigateToMenu();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Erro de autenticação.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final Color? bgColor = Color.lerp(const Color(0xFFF4EFFA), const Color(0xFF512DA8), _flipAnimation.value);
          // A cor do copyright adapta-se ao fundo
          final Color? footerColor = Color.lerp(const Color(0xFF1E1B26).withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.6), _flipAnimation.value);

          final angle = _flipAnimation.value * pi;
          final isFront = angle < pi / 2;
          final scale = 1.0 - (0.1 * sin(angle));

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: bgColor,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          child: Image.asset('assets/images/logo_splash.png', height: 90),
                        ),
                        const SizedBox(height: 36),
                        
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..scale(scale, scale)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: isFront
                              ? _buildFrontCard() 
                              : Transform(
                                  transform: Matrix4.identity()..rotateY(pi), 
                                  alignment: Alignment.center,
                                  child: _buildBackCard(), 
                                ),
                        ),
                        const SizedBox(height: 32),
                        
                        // O toque final: Copyright
                        Text(
                          'Pharma Inc. ©',
                          style: TextStyle(
                            color: footerColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF2E7D32), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: const Center(
              child: Text('CRACHÁ DE VISITANTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNameField(false),
                const SizedBox(height: 24),
                
                _buildEvolutionSelector(isPurple: false),
                
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.medication, size: 22),
                  onPressed: _isLoading ? null : _signInQuick,
                  label: const Text('ENTRAR AGORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(20, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: index % 3 == 0 ? 3 : 1.5, height: 24, color: Colors.grey.shade300)),
                ),
                const Divider(height: 32, color: Color(0xFFEEEEEE)),
                
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isQuickMode = false;
                      _isLogin = true;
                    });
                    _flipController.forward();
                  },
                  icon: const Icon(Icons.sync, size: 18, color: Color(0xFF2E7D32)),
                  label: const Text(
                    'Virar para Cédula Permanente',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: const BoxDecoration(color: Color(0xFF673AB7), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CÉDULA PROFISSIONAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                Icon(Icons.memory, color: Colors.amber, size: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isLogin) ...[
                  _buildNameField(true),
                  const SizedBox(height: 24),
                  
                  _buildEvolutionSelector(isPurple: true),
                  
                  const Divider(height: 32),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Oficial',
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF673AB7)),
                    filled: true,
                    fillColor: const Color(0xFFF4EFFA).withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Palavra-passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF673AB7)),
                    filled: true,
                    fillColor: const Color(0xFFF4EFFA).withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                      shadowColor: const Color(0xFF673AB7).withValues(alpha: 0.4),
                    ),
                    icon: Icon(_isLogin ? Icons.verified_user : Icons.badge, size: 20),
                    onPressed: _submitEmailAuth,
                    label: Text(_isLogin ? 'VALIDAR CREDENCIAIS' : 'EMITIR CÉDULA', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF673AB7), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Color(0xFF673AB7)),
                    label: const Text('Associar Google', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF673AB7))),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Sem registo? Emitir agora' : 'Já tem cédula? Validar', style: const TextStyle(color: Color(0xFF512DA8), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
                const Divider(height: 32, color: Color(0xFFEEEEEE)),
                
                TextButton.icon(
                  onPressed: () {
                    setState(() => _isQuickMode = true);
                    _flipController.reverse();
                  },
                  icon: const Icon(Icons.sync, size: 18, color: Color(0xFF673AB7)),
                  label: const Text(
                    'Usar Crachá de Visitante',
                    style: TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isPurple) {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nome do Jogador',
        prefixIcon: Icon(Icons.person_outline, color: isPurple ? const Color(0xFF673AB7) : const Color(0xFF2E7D32)),
        filled: true,
        fillColor: const Color(0xFFF4EFFA).withValues(alpha: 0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEvolutionSelector({required bool isPurple}) {
    final activeColor = isPurple ? const Color(0xFF673AB7) : const Color(0xFF2E7D32);
    final inactiveColor = const Color(0xFFE0E0E0);

    String displayTitle = '...';
    if (_selectedAudience != null) {
      displayTitle = _audiences.firstWhere((a) => a.level == _selectedAudience).title;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'ESCOLHE O TEU NÍVEL:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: activeColor, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double nodeSize = 36.0; 
            final double trackWidth = width - nodeSize; 
            
            double fillWidth = 0;
            if (_selectedAudience != null) {
              fillWidth = (trackWidth / 4) * (_selectedAudience! - 1);
            }

            return Column(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: nodeSize / 2,
                      right: nodeSize / 2,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(color: inactiveColor, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Positioned(
                      left: nodeSize / 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _audiences.map((aud) {
                        final bool isReached = _selectedAudience != null && aud.level <= _selectedAudience!;
                        final bool isCurrent = _selectedAudience == aud.level;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedAudience = aud.level),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: isCurrent ? 36 : 28,
                            height: isCurrent ? 36 : 28,
                            decoration: BoxDecoration(
                              color: isReached ? activeColor : Colors.grey.shade300,
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: isCurrent 
                                ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] 
                                : [],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 1.5,
                                  width: isCurrent ? 24 : 18, 
                                  color: Colors.white.withValues(alpha: isReached ? 0.3 : 0.7),
                                ),
                                if (isReached)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    color: activeColor, 
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${aud.level}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: isCurrent ? 14 : 12,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    displayTitle,
                    key: ValueKey<String>(displayTitle),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _selectedAudience != null ? activeColor : Colors.grey.shade400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}