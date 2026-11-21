import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'progress_manager.dart';

/// Mapa central dos públicos (o número é o que fica guardado na base de dados).
const Map<int, String> kAudienceNames = {
  1: 'Juniores',
  2: 'Seniores (Comunidade)',
  3: 'Técnicos Auxiliares de Farmácia',
  4: 'Estudantes Universitários de Farmácia',
  5: 'Farmacêuticos',
};

/// Converte o valor de `audience` (int ou String) no nome do público.
String audienceLabel(dynamic raw) {
  final id = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  return kAudienceNames[id] ?? 'Sem público';
}

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

  final List<String> _categories = ['Global', ...kAudienceNames.values];

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

  final GlobalKey _filterButtonKey = GlobalKey();

  IconData _iconForCategory(String cat) {
    if (cat == 'Global') return Icons.public_rounded;
    if (cat == 'Juniores') return Icons.sports_esports_rounded;
    if (cat == 'Seniores (Comunidade)') return Icons.elderly_rounded;
    if (cat == 'Técnicos Auxiliares de Farmácia') return Icons.medical_information_rounded;
    if (cat == 'Estudantes Universitários de Farmácia') return Icons.school_rounded;
    if (cat == 'Farmacêuticos') return Icons.local_pharmacy_rounded;
    return Icons.group_rounded;
  }

  Widget _buildFilterButton() {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentCyan.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: accentCyan.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_rounded, color: accentCyan, size: 16),
          const SizedBox(width: 6),
          Text(
            _selectedCategory == 'Global' ? 'FILTRAR' : 'FILTRADO',
            style: const TextStyle(
              color: accentCyan,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Cascata de filtros: os ícones (em círculos) descem por baixo do botão,
  /// alinhados à direita com o fim do botão, e o nome da categoria aparece à esquerda.
  void _showFilterCascade(BuildContext context) {
    final RenderBox? box = _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);
    const Color surface = Color(0xFF2A2635);
    const double circleSize = 48;

    final Offset origin = box.localToGlobal(Offset.zero);
    final Size buttonSize = box.size;
    final Size screen = MediaQuery.of(context).size;
    final double rightInset = screen.width - (origin.dx + buttonSize.width);
    final double listTop = origin.dy + buttonSize.height + 14;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar filtro',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              Widget buildItem(int i) {
                final String category = _categories[i];
                final bool isSelected = _selectedCategory == category;

                // Cada item arranca um pouco depois do anterior (efeito cascata)
                final double start = i * 0.08;
                final double t = Interval(start, start + 0.5, curve: Curves.easeOutBack)
                    .transform(animation.value);

                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * -24),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * t,
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(dialogContext);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primary.withValues(alpha: 0.35) : surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? accentCyan : Colors.white12,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? primary : surface,
                                  border: Border.all(
                                    color: isSelected ? accentCyan : Colors.white24,
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? accentCyan.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _iconForCategory(category),
                                  size: 22,
                                  color: isSelected ? accentCyan : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // Réplica do botão por cima do fundo escurecido (toca para fechar)
                  Positioned(
                    left: origin.dx,
                    top: origin.dy,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: _buildFilterButton(),
                    ),
                  ),
                  Positioned(
                    right: rightInset,
                    top: listTop,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screen.height - listTop - 16,
                        maxWidth: screen.width - rightInset - 16,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (int i = 0; i < _categories.length; i++) buildItem(i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF673AB7);
    const accentCyan = Color(0xFF00E5FF);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final int userXP = ProgressManager().currentXP;
    const String userRole = 'Sem público';

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Farmacêuticos',
                        style: TextStyle(
                          fontSize: 24, // Ligeiramente mais pequeno para encaixar o botão
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // BOTÃO DE FILTRO (abre a cascata)
                      GestureDetector(
                        key: _filterButtonKey,
                        onTap: () => _showFilterCascade(context),
                        child: _buildFilterButton(),
                      ),
                    ],
                  ),
                ),

                // Etiqueta visual para quando há um filtro ativo
                if (_selectedCategory != 'Global')
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 12.0, bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.white54, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategory.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
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

                          String role = data['audience'] != null
                              ? audienceLabel(data['audience'])
                              : (data['role']?.toString() ?? 'Sem público');

                          list.add({
                            'uid': docId,
                            'name': docId == currentUserId ? '$name (Tu)' : name,
                            'xp': xp,
                            'role': role,
                            'isUser': docId == currentUserId,
                            'capsuleTop': data['capsuleTop'],
                            'capsuleBottom': data['capsuleBottom'],
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

                      list.sort((a, b) {
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
                                capsuleTop: player['capsuleTop'] as int?,
                                capsuleBottom: player['capsuleBottom'] as int?,
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

                            checkList.sort((a, b) {
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
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .snapshots()
                                : null,
                            builder: (context, userDocSnapshot) {
                              String dynamicName = 'Estagiário';
                              String dynamicRole = userRole;
                              Map<String, dynamic>? userData; // A VARIÁVEL É DECLARADA AQUI FORA!

                              if (userDocSnapshot.hasData &&
                                  userDocSnapshot.data != null &&
                                  userDocSnapshot.data!.exists) {
                                userData = userDocSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                                if (userData != null) {
                                  if (userData['name'] != null) {
                                    dynamicName = userData['name'].toString();
                                  }
                                  
                                  if (userData['audience'] != null) {
                                    dynamicRole = audienceLabel(userData['audience']);
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
                                capsuleTop: userData?['capsuleTop'] as int?,
                                capsuleBottom: userData?['capsuleBottom'] as int?,
                              );
                            },
                          );
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
    int? capsuleTop,
    int? capsuleBottom,
  }) {
    Color getRankColor(int r) {
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      if (r == 3) return const Color(0xFFCD7F32);
      return const Color(0xFF00E5FF);
    }

    final Color rankColor = getRankColor(rank);
    
    // Cores da cápsula (Usa a cor personalizada ou o roxo padrão se o jogador não tiver escolhido)
    final Color topColor = capsuleTop != null ? Color(capsuleTop) : const Color(0xFF9575CD);
    final Color bottomColor = capsuleBottom != null ? Color(capsuleBottom) : const Color(0xFF512DA8);

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
          // DESIGN DA CÁPSULA COM O NÚMERO DO RANK
          Container(
            width: 42,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21), // Arredonda para formato pílula
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
                stops: const [0.5, 0.5], // Corte seco ao meio
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), // Brilho do plástico
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: bottomColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
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
            '$xp mg',
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
} // CHAVETA DE FECHO AGORA PRESENTE!