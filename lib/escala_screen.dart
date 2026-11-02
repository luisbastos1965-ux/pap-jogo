import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'progress_manager.dart';

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Global';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    'Global',
    'Farmacêuticos',
    'Estudantes Universitários de Farmácia',
    'Técnicos Auxiliares de Farmácia',
    'Seniores',
    'Juniores',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getUserRole(int level) {
    switch (level) {
      case 1:
        return 'Juniores';
      case 2:
        return 'Seniores';
      case 3:
        return 'Técnicos Auxiliares de Farmácia';
      case 4:
        return 'Estudantes Universitários de Farmácia';
      case 5:
      default:
        return 'Farmacêuticos';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final int userXP = ProgressManager().currentXP;
    final int userLevel = ProgressManager().currentLevel;
    final String userRole = _getUserRole(userLevel);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B26),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _buildMolecule(primary.withValues(alpha: 0.12), 220),
          ),
          Positioned(
            bottom: 50,
            left: -70,
            child: _buildMolecule(accentCyan.withValues(alpha: 0.08), 260),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Top Farmacêuticos',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consulta o desempenho clínico em tempo real.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accentCyan.withValues(alpha: 0.5)
                                  : Colors.white12,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: accentCyan),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar escala: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      List<Map<String, dynamic>> list = [];

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          Map<String, dynamic> data = {};
                          try {
                            data = doc.data() as Map<String, dynamic>;
                          } catch (_) {}

                          String docId = doc.id;
                          String name =
                              data['name']?.toString() ?? 'Farmacêutico';

                          int xp = 0;
                          var rawXp = data['xp'];
                          if (rawXp is int) {
                            xp = rawXp;
                          } else if (rawXp != null) {
                            xp =
                                int.tryParse(rawXp.toString()) ??
                                (docId == currentUserId ? userXP : 0);
                          } else if (docId == currentUserId) {
                            xp = userXP;
                          }

                          int level = 1;
                          var rawLevel = data['level'];
                          if (rawLevel is int) {
                            level = rawLevel;
                          } else if (rawLevel != null) {
                            level = int.tryParse(rawLevel.toString()) ?? (docId == currentUserId ? userLevel : 1);
                          } else if (docId == currentUserId) {
                            level = userLevel;
                          }

                          // LÊ O PÚBLICO DIRETAMENTE AQUI:
                          String role = data['audience']?.toString() ?? data['role']?.toString() ?? _getUserRole(level);

                          list.add({
                            'uid': docId,
                            'name': docId == currentUserId ? '$name (Tu)' : name,
                            'xp': xp,
                            'role': role,
                            'isUser': docId == currentUserId,
                          });
                        }
                      }

                      bool hasUser = false;
                      for (int i = 0; i < list.length; i++) {
                        if (list[i]['isUser'] == true) {
                          hasUser = true;
                          break;
                        }
                      }

                      if (!hasUser) {
                        list.add({
                          'uid': currentUserId ?? 'local_user',
                          'name': 'Estagiário (Tu)',
                          'xp': userXP,
                          'role': userRole,
                          'isUser': true,
                        });
                      }

                      // Ordenação manual segura por bolha/comparação direta
                      list.sort((
                        Map<String, dynamic> a,
                        Map<String, dynamic> b,
                      ) {
                        int valA = a['xp'] as int;
                        int valB = b['xp'] as int;
                        return valB.compareTo(valA);
                      });

                      List<Map<String, dynamic>> filtered = [];
                      if (_selectedCategory == 'Global') {
                        filtered = list;
                      } else {
                        for (int i = 0; i < list.length; i++) {
                          if (list[i]['role'] == _selectedCategory) {
                            filtered.add(list[i]);
                          }
                        }
                      }

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum registo encontrado nesta categoria.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            var player = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildRankCard(
                                rank: index + 1,
                                name: player['name'].toString(),
                                xp: player['xp'] as int,
                                role: player['role'].toString(),
                                isUser: player['isUser'] as bool,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    border: const Border(
                      top: BorderSide(color: Colors.white12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A TUA POSIÇÃO NA ESCALA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: accentCyan,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int userRank = 99;
                          if (snapshot.hasData) {
                            List<Map<String, dynamic>> checkList = [];
                            for (var doc in snapshot.data!.docs) {
                              Map<String, dynamic> data = {};
                              try {
                                data = doc.data() as Map<String, dynamic>;
                              } catch (_) {}

                              int xp = 0;
                              var rawXp = data['xp'];
                              if (rawXp is int) {
                                xp = rawXp;
                              } else if (rawXp != null) {
                                xp = int.tryParse(rawXp.toString()) ?? 0;
                              }

                              checkList.add({
                                'uid': doc.id,
                                'xp': xp,
                                'isUser': doc.id == currentUserId,
                              });
                            }

                            checkList.sort((
                              Map<String, dynamic> a,
                              Map<String, dynamic> b,
                            ) {
                              int valA = a['xp'] as int;
                              int valB = b['xp'] as int;
                              return valB.compareTo(valA);
                            });

                            for (int i = 0; i < checkList.length; i++) {
                              if (checkList[i]['isUser'] == true) {
                                userRank = i + 1;
                                break;
                              }
                            }
                          }

                          return StreamBuilder<DocumentSnapshot>(
                        stream: currentUserId != null 
                            ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots() 
                            : null,
                        builder: (context, userDocSnapshot) {
                          String dynamicName = 'Estagiário';
                          String dynamicRole = userRole; // fallback base

                          if (userDocSnapshot.hasData && userDocSnapshot.data != null && userDocSnapshot.data!.exists) {
                            final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
                            if (userData != null) {
                              if (userData['name'] != null) {
                                dynamicName = userData['name'].toString();
                              }
                              // LÊ O PÚBLICO PARA O RODAPÉ:
                              if (userData['audience'] != null) {
                                dynamicRole = userData['audience'].toString();
                              } else if (userData['role'] != null) {
                                dynamicRole = userData['role'].toString();
                              }
                            }
                          }

                          return _buildRankCard(
                            rank: userRank,
                            name: '$dynamicName (Tu)',
                            xp: userXP,
                            role: dynamicRole,
                            isUser: true,
                          );
                        },
                      ); // <--- Aqui leva ponto e vírgula!
                    },
                  ),
                    ],
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
            width: size / 2,
            height: size / 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard({
    required int rank,
    required String name,
    required int xp,
    required String role,
    bool isUser = false,
  }) {
    Color getRankColor(int r) {
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      if (r == 3) return const Color(0xFFCD7F32);
      return const Color(0xFF00E5FF);
    }

    final Color rankColor = getRankColor(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFF673AB7).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUser
              ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isUser ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? const Color(0xFF00E5FF).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isUser ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$xp XP',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: rankColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
