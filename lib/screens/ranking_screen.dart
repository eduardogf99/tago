import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final int _pageSize = 20;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = "";

  final List<Map<String, dynamic>> _usuariosData = [];
  DocumentSnapshot? _lastUsuarioSnapshot;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRanking();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchRanking();
      }
    });
  }

  Future<void> _fetchRanking() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      // USAMOS EL NUEVO CAMPO: Ordenamos por totalEscaneos de mayor a menor
      Query query = FirebaseFirestore.instance
          .collection('usuarios')
          .orderBy('totalEscaneos', descending: true);

      if (_lastUsuarioSnapshot != null) {
        query = query.startAfterDocument(_lastUsuarioSnapshot!);
      }

      final querySnapshot = await query.limit(_pageSize).get();

      if (mounted) {
        setState(() {
          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            _usuariosData.add(data);
          }
          if (querySnapshot.docs.isNotEmpty) {
            _lastUsuarioSnapshot = querySnapshot.docs.last;
          }
          _isLoading = false;
          if (querySnapshot.docs.length < _pageSize) _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ranking: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsuarios() {
    if (_searchQuery.isEmpty) return _usuariosData;
    return _usuariosData.where((u) =>
        u['usuario'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
  }

  TextStyle _headerStyle() => const TextStyle(
      color: AppColors.azulClaro,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.1
  );

  @override
  Widget build(BuildContext context) {
    final filteredUsuarios = _getFilteredUsuarios();

    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("RANKING EXPLORADORES",
            style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = v.trim().toLowerCase());
                });
              },
              style: const TextStyle(color: AppColors.blancoTexto),
              decoration: InputDecoration(
                hintText: "Buscar usuario...",
                hintStyle: const TextStyle(color: AppColors.azulStamps),
                prefixIcon: const Icon(Icons.search, color: AppColors.azulStamps),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.azulStamps),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.doradoClaro),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const SizedBox(width: 40),
                Expanded(child: Text("USUARIO", style: _headerStyle())),
                SizedBox(width: 60, child: Center(child: Text("TAGOS", style: _headerStyle()))),
                const SizedBox(width: 10),
                SizedBox(width: 60, child: Center(child: Text("PAÍSES", style: _headerStyle()))),
              ],
            ),
          ),
          const Divider(color: AppColors.azulStamps, thickness: 0.5, indent: 20, endIndent: 20),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredUsuarios.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredUsuarios.length) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: AppColors.doradoClaro),
                  ));
                }
                return _rankingTile(filteredUsuarios[index], index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingTile(Map<String, dynamic> userData, int position) {
    final String name = userData['usuario'] ?? 'Anónimo';
    final String? photoUrl = userData['photoUrl'];

    // Obtenemos los valores directamente del mapa
    final int tagosCount = userData['totalEscaneos'] ?? 0;
    final int paisesCount = (userData['paises_descubiertos'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.azulContenedor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.doradoClaro.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text("#$position",
                style: TextStyle(
                    color: position <= 3 ? AppColors.doradoClaro : AppColors.azulClaro,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.azulStamps,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(name,
              style: const TextStyle(color: AppColors.blancoTexto, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TAGOS: Lectura directa
          SizedBox(
            width: 60,
            child: _statItem(tagosCount.toString()),
          ),
          const SizedBox(width: 10),
          // PAÍSES: Lectura directa
          SizedBox(
            width: 60,
            child: _statItem(paisesCount.toString()),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(color: AppColors.blancoTexto, fontSize: 12, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}