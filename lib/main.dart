import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'level_selection.dart';
import 'audio_manager.dart';
import 'progress_manager.dart';
import 'rules_screen.dart';
import 'profile_screen.dart';
import 'gabinete_screen.dart';
import 'escala_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // 2. Garante a inicialização dos pacotes nativos
  WidgetsFlutterBinding.ensureInitialized();
  // 3. Carrega o XP gravado
  await ProgressManager().init();

  runApp(const PharmaIncApp());
}

class PharmaIncApp extends StatelessWidget {
  const PharmaIncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharma Inc.',
      theme: ThemeData(
        useMaterial3: true,
        textTheme:
            GoogleFonts.poppinsTextTheme(), // Aplica a fonte Poppins globalmente
        scaffoldBackgroundColor: const Color(0xFFF4EFFA),
        primaryColor: const Color(0xFF673AB7),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.8;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
    });

    Timer(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 2),
          opacity: _opacity,
          curve: Curves.easeIn,
          child: AnimatedScale(
            duration: const Duration(seconds: 2),
            scale: _scale,
            curve: Curves.easeOutCubic,
            child: Image.asset('assets/images/logo_splash.png', width: 300),
          ),
        ),
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isBgmStarted = false; // <-- Adiciona exatamente aqui

  @override
  void initState() {
    super.initState();

    // Inicia a música usando o nosso Gestor Global com crossfade automático
    AudioManager().playCrossfade('bgm.mp3');

    // Configuração da animação flutuante
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (_) {
          if (!_isBgmStarted) {
            AudioManager().playCrossfade('bgm.mp3');
            _isBgmStarted = true;
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF4EFFA)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // CABEÇALHO (Status + Mute)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(
                              0xFF673AB7,
                            ).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF673AB7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nível ${ProgressManager().currentLevel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1B26),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${ProgressManager().currentXP} XP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          AudioManager().isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          setState(() {
                            AudioManager().toggleMute();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // CORPO CENTRAL
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16), // Respiro inicial
                        // 1. CARTÃO DICA DE BALCÃO
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF673AB7,
                                ).withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7E57C2),
                                      Color(0xFF512DA8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF512DA8,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lightbulb_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DICA DE BALCÃO',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF512DA8),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'O paracetamol tem um limite diário seguro de 4g para adultos.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A4453),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 72,
                        ), // Espaço equilibrado acima do logótipo
                        // 2. LOGÓTIPO ANIMADO
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _animation.value),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF673AB7,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_splash.png',
                              height: 280,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 72,
                        ), // Espaço simétrico abaixo do logótipo
                        // 3. BOTÃO PRINCIPAL (Entrar ao Balcão)
                        Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF512DA8,
                                ).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LevelSelectionScreen(),
                                ),
                              );
                              setState(() {});
                            },
                            child: const Text(
                              'ENTRAR AO BALCÃO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
      ),

      // NOVA DOCK FLUTUANTE INJETADA AQUI
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF673AB7).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDockIcon(
                  icon: Icons.menu_book_rounded,
                  label: 'Bula',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RulesScreen(),
                      ),
                    );
                  },
                ),
                _buildDockIcon(
                  icon: Icons.badge_rounded,
                  label: 'Cédula',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
                _buildDockIcon(
                  icon: Icons.leaderboard_rounded,
                  label: 'Escala',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EscalaScreen(),
                      ),
                    );
                  },
                ),
                _buildDockIcon(
                  icon: Icons.settings_rounded,
                  label: 'Gabinete',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GabineteScreen(),
                      ),
                    );
                    setState(
                      () {},
                    ); // Atualiza o ecrã inicial caso tenhas feito reset ao XP
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pharma Inc. © 2027',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1B26).withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CONSTRUTOR DOS ÍCONES DA DOCK
  Widget _buildDockIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF673AB7), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF673AB7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
