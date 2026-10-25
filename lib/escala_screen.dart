import 'package:flutter/material.dart';
import 'progress_manager.dart';

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  String _selectedCategory = 'Global';
  
  // 1. As tuas novas categorias (com 'Global' para ver todos)
  final List<String> _categories = [
    'Global', 
    'Farmacêuticos', 
    'Estudantes Universitários de Farmácia', 
    'Técnicos Auxiliares de Farmácia', 
    'Seniores', 
    'Juniores'
  ];

  // 2. Base de dados atualizada com os novos cargos
  final List<Map<String, dynamic>> _allPlayers = [
    {'name': 'Dra. Sofia Martins', 'xp': 12450, 'role': 'Farmacêuticos'},
    {'name': 'Dr. João Pereira', 'xp': 9200, 'role': 'Farmacêuticos'},
    {'name': 'Dra. Ana Costa', 'xp': 7150, 'role': 'Seniores'},
    {'name': 'Carlos Mendes', 'xp': 6800, 'role': 'Seniores'},
    {'name': 'Marta Gomes', 'xp': 5100, 'role': 'Técnicos Auxiliares de Farmácia'},
    {'name': 'Rui Silva', 'xp': 4800, 'role': 'Técnicos Auxiliares de Farmácia'},
    {'name': 'Inês Ribeiro', 'xp': 3200, 'role': 'Estudantes Universitários de Farmácia'},
    {'name': 'Tiago Faria', 'xp': 2950, 'role': 'Estudantes Universitários de Farmácia'},
    {'name': 'Hugo Santos', 'xp': 1500, 'role': 'Juniores'},
    {'name': 'Beatriz Lima', 'xp': 800, 'role': 'Juniores'},
  ];

  // A categoria agora é definida pelo Nível atual (Público-alvo)
  String _getUserRole(int level) {
    switch (level) {
      case 1: return 'Juniores';
      case 2: return 'Seniores';
      case 3: return 'Técnicos Auxiliares de Farmácia';
      case 4: return 'Estudantes Universitários de Farmácia';
      case 5:
      default: return 'Farmacêuticos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int userXP = ProgressManager().currentXP;
    final int userLevel = ProgressManager().currentLevel; // Lemos o nível real
    final String userRole = _getUserRole(userLevel); // Atribuímos a categoria
    
    // Injetar o utilizador real na lista...
    
    // Injetar o utilizador real na lista para o cálculo do ranking
    final List<Map<String, dynamic>> playersWithUser = List.from(_allPlayers)
      ..add({'name': 'Estagiário (Tu)', 'xp': userXP, 'role': userRole, 'isUser': true});
      
    // Ordenar por XP decrescente
    playersWithUser.sort((a, b) => b['xp'].compareTo(a['xp']));

    // Filtrar pela categoria selecionada
    final List<Map<String, dynamic>> filteredPlayers = _selectedCategory == 'Global'
        ? playersWithUser
        : playersWithUser.where((p) => p['role'] == _selectedCategory).toList();

    // Encontrar a posição real do utilizador na lista filtrada
    final int userRank = filteredPlayers.indexWhere((p) => p['isUser'] == true) + 1;

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
          'ESCALA DE SERVIÇO',
          style: TextStyle(color: Color(0xFF1E1B26), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Top Farmacêuticos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E1B26)),
                ),
                const Text(
                  'Filtra o ranking por nível de conhecimento.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6576)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Seletor de Categorias Animado
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
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF673AB7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]
                          : [BoxShadow(color: const Color(0xFF1E1B26).withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF6B6576),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lista de Jogadores Animada
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: ListView.builder(
                key: ValueKey<String>(_selectedCategory),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: filteredPlayers.length,
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildRankCard(
                      rank: index + 1,
                      name: player['name'],
                      xp: player['xp'],
                      role: player['role'],
                      isUser: player['isUser'] ?? false,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Posição fixa do utilizador no rodapé
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A Tua Posição', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF673AB7), letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _buildRankCard(
                  rank: userRank > 0 ? userRank : 99, 
                  name: 'Estagiário (Tu)', 
                  xp: userXP, 
                  role: userRole,
                  isUser: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard({required int rank, required String name, required int xp, required String role, bool isUser = false}) {
    Color getRankColor(int r) {
      if (_selectedCategory != 'Global') return const Color(0xFF673AB7); // Cor padrão em categorias
      if (r == 1) return const Color(0xFFFFD700);
      if (r == 2) return const Color(0xFFC0C0C0);
      if (r == 3) return const Color(0xFFCD7F32);
      return const Color(0xFF673AB7);
    }

    final Color rankColor = getRankColor(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF673AB7).withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUser ? Border.all(color: const Color(0xFF673AB7).withValues(alpha: 0.3), width: 2) : null,
        boxShadow: isUser ? [] : [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rankColor.withValues(alpha: 0.2),
            radius: 18,
            child: Text('#$rank', style: TextStyle(color: rankColor == const Color(0xFFC0C0C0) ? Colors.black87 : rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: isUser ? FontWeight.w900 : FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B26)),
                ),
                if (_selectedCategory == 'Global') ...[
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
                  ),
                ]
              ],
            ),
          ),
          Text(
            '$xp XP',
            style: TextStyle(fontWeight: FontWeight.w900, color: rankColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}