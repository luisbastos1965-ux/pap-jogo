import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'level_selection.dart';
import 'audio_manager.dart';
import 'progress_manager.dart';
import 'rules_screen.dart';
import 'profile_screen.dart';
import 'gabinete_screen.dart';
import 'escala_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dica_balcao_card.dart'; // NOVO IMPORT DA NOSSA CARTA
import 'pratica_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseInitializer());
}

class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF1E1B26),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Erro de configuração Firebase:\n${snapshot.error}', 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.done) {
          return const PharmaIncApp();
        }
        
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFF1E1B26),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          ),
        );
      },
    );
  }
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
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF1E1B26),
        primaryColor: const Color(0xFF673AB7),
        
        // ADICIONA AS TRANSIÇÕES GLOBAIS AQUI
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
    });

    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;

    User? user;
    try {
      final redirectCred = await FirebaseAuth.instance.getRedirectResult();
      if (redirectCred != null) {
        user = redirectCred.user;
      } else {
        user = FirebaseAuth.instance.currentUser;
      }

      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'name': user.displayName ?? 'Farmacêutico',
            'audience': 5, 
            'xp': 0,
            'level': 1,
            'careerTitle': 'Estagiário/a',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await ProgressManager().loadUserData();
      }
    } catch (e) {
      debugPrint('Erro ao verificar sessão no SplashScreen: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              user != null ? const MenuScreen() : const AuthScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26),
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 2),
          opacity: _opacity,
          curve: Curves.easeIn,
          child: AnimatedScale(
            duration: const Duration(seconds: 2),
            scale: _scale,
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Image.asset('assets/images/logo_splash.png', width: 300),
            ),
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

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isBgmStarted = false;

  @override
  void initState() {
    super.initState();
    AudioManager().playCrossfade('bgm.mp3');
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26),
      body: Listener(
        onPointerDown: (_) {
          if (!_isBgmStarted) {
            AudioManager().playCrossfade('bgm.mp3');
            _isBgmStarted = true;
          }
        },
        child: Stack(
          children: [
            Positioned(top: -40, right: -60, child: _buildMolecule(primary.withValues(alpha: 0.12), 220)),
            Positioned(bottom: 100, left: -70, child: _buildMolecule(accentCyan.withValues(alpha: 0.08), 260)),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF00E5FF), Color(0xFF673AB7)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3), 
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true 
                                        ? FirebaseAuth.instance.currentUser!.displayName![0].toUpperCase() 
                                        : 'F',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900, 
                                      fontSize: 18, 
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${FirebaseAuth.instance.currentUser?.displayName?.split(' ')[0] ?? 'Farmacêutico'} • ',
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                                        ),
                                        TextSpan(
                                          text: ProgressManager().audienceName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00E5FF), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ProgressManager().careerTitle} • Nível ${ProgressManager().currentLevel} (${ProgressManager().currentXP} XP)',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: IconButton(
                              icon: Icon(
                                AudioManager().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  AudioManager().toggleMute();
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // COMPONENTE EXTRAÍDO (A Dica e os Sensores vivem agora no seu próprio ficheiro)
                      const DicaBalcaoCard(),

                      const SizedBox(height: 48), 

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
                              BoxShadow(color: primary.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
                            ],
                          ),
                          child: Image.asset('assets/images/logo_splash.png', height: 210),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // CÁPSULA DE SELEÇÃO DE MODO (TEORIA VS PRÁTICA)
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                          ]
                        ),
                        child: Row(
                          children: [
                            // METADE ESQUERDA: TEORIA (Roxo)
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LevelSelectionScreen()),
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(50)),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end, // Texto alinhado à direita (junto ao centro)
                                        children: [
                                          const Text('TEORIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                                          Text('Simulador', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.style_rounded, color: Colors.white.withValues(alpha: 0.9), size: 26),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // VINCO DA CÁPSULA (Fenda central do comprimido)
                            Container(width: 2, color: const Color(0xFF1E1B26)),

                            // METADE DIREITA: PRÁTICA (Cyan Néon)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // JÁ CHAMA O NOVO ECRÃ!
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PraticaScreen()),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(50)),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white.withValues(alpha: 0.9), size: 26),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start, // Texto alinhado à esquerda (junto ao centro)
                                        children: [
                                          const Text('PRÁTICA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                                          Text('Casos QR', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDockIcon(
                  icon: Icons.menu_book_rounded,
                  label: 'Bula',
                  color: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RulesScreen()),
                    );
                  },
                ),
                _buildDockIcon(
                  icon: Icons.badge_rounded,
                  label: 'Cédula',
                  color: Colors.white,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                    setState(() {});
                  },
                ),
                _buildDockIcon(
                  icon: Icons.leaderboard_rounded,
                  label: 'Escala',
                  color: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EscalaScreen()),
                    );
                  },
                ),
                _buildDockIcon(
                  icon: Icons.settings_rounded,
                  label: 'Gabinete',
                  color: Colors.white,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GabineteScreen()),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pharma Inc. © 2027',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}