import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/image_helper.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  bool _isUsuariosTab = true;
  final DatabaseService _dbService = DatabaseService();
  final int _pageSize = 20;

  // Buscador
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = "";

  // Variables para Usuarios
  final List<Map<String, dynamic>> _usuariosData = [];
  DocumentSnapshot? _lastUsuarioSnapshot;
  bool _isLoadingUsuarios = false;
  bool _hasMoreUsuarios = true;
  final ScrollController _usuariosScrollController = ScrollController();

  // Variables para Tagos
  final List<Map<String, dynamic>> _tagosData = [];
  DocumentSnapshot? _lastTagoSnapshot;
  bool _isLoadingTagos = false;
  bool _hasMoreTagos = true;
  final ScrollController _tagosScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _fetchTagos();

    _usuariosScrollController.addListener(() {
      if (_usuariosScrollController.position.pixels >= _usuariosScrollController.position.maxScrollExtent - 200) {
        _fetchUsuarios();
      }
    });

    _tagosScrollController.addListener(() {
      if (_tagosScrollController.position.pixels >= _tagosScrollController.position.maxScrollExtent - 200) {
        _fetchTagos();
      }
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
        
        if (_searchQuery.isNotEmpty) {
          if (_isUsuariosTab) {
            if (_hasMoreUsuarios && _getFilteredUsuarios().length < 5) _fetchUsuarios();
          } else {
            if (_hasMoreTagos && _getFilteredTagos().length < 5) _fetchTagos();
          }
        }
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredUsuarios() {
    return _usuariosData.where((u) => 
      u['usuario'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
  }

  List<Map<String, dynamic>> _getFilteredTagos() {
    return _tagosData.where((t) => 
      t['titulo'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
  }

  Future<void> _fetchUsuarios() async {
    if (_isLoadingUsuarios || !_hasMoreUsuarios) return;

    setState(() => _isLoadingUsuarios = true);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      Query query = FirebaseFirestore.instance.collection('usuarios').orderBy('usuario');

      if (_lastUsuarioSnapshot != null) {
        query = query.startAfterDocument(_lastUsuarioSnapshot!);
      }

      final querySnapshot = await query.limit(_pageSize).get();
      
      if (mounted) {
        bool matchInThisBatch = false;
        setState(() {
          final nuevosDocs = querySnapshot.docs.where((doc) => doc.id != currentUid).toList();
          
          for (var doc in nuevosDocs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            _usuariosData.add(data);
            if (data['usuario'].toString().toLowerCase().contains(_searchQuery)) matchInThisBatch = true;
          }

          if (querySnapshot.docs.isNotEmpty) {
            _lastUsuarioSnapshot = querySnapshot.docs.last;
          }

          _isLoadingUsuarios = false;
          if (querySnapshot.docs.length < _pageSize) {
            _hasMoreUsuarios = false;
          }
        });

        if (_searchQuery.isNotEmpty && !matchInThisBatch && _hasMoreUsuarios) {
          _fetchUsuarios();
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => _isLoadingUsuarios = false);
    }
  }

  Future<void> _fetchTagos() async {
    if (_isLoadingTagos || !_hasMoreTagos) return;

    setState(() => _isLoadingTagos = true);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // AHORA filtramos por creadorId (el UID del usuario logueado)
      Query query = FirebaseFirestore.instance
          .collection('marcadores')
          .where('creadorId', isEqualTo: currentUid);

      if (_lastTagoSnapshot != null) {
        query = query.startAfterDocument(_lastTagoSnapshot!);
      }

      final querySnapshot = await query.limit(_pageSize).get();
      
      if (mounted) {
        bool matchInThisBatch = false;
        setState(() {
          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            _tagosData.add(data);
            if (data['titulo'].toString().toLowerCase().contains(_searchQuery)) matchInThisBatch = true;
          }

          if (querySnapshot.docs.isNotEmpty) {
            _lastTagoSnapshot = querySnapshot.docs.last;
          }

          _isLoadingTagos = false;
          if (querySnapshot.docs.length < _pageSize) {
            _hasMoreTagos = false;
          }
        });

        if (_searchQuery.isNotEmpty && !matchInThisBatch && _hasMoreTagos) {
          _fetchTagos();
        }
      }
    } catch (e) {
      debugPrint("Error fetching tagos: $e");
      if (mounted) setState(() => _isLoadingTagos = false);
    }
  }

  @override
  void dispose() {
    _usuariosScrollController.dispose();
    _tagosScrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsuarios = _getFilteredUsuarios();
    final filteredTagos = _getFilteredTagos();

    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        title: const Text("ADMINISTRACIÓN", style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: AppColors.azulOscuro,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton("Usuarios", _isUsuariosTab, () => setState(() => _isUsuariosTab = true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tabButton("Mis Tagos", !_isUsuariosTab, () => setState(() => _isUsuariosTab = false)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.blancoTexto),
              cursorColor: AppColors.doradoClaro,
              decoration: InputDecoration(
                hintStyle: const TextStyle(color: AppColors.azulStamps),
                hintText: _isUsuariosTab ? "Buscar por usuario..." : "Buscar por título...",
                prefixIcon: const Icon(Icons.search, color: AppColors.azulStamps),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.azulStamps),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged("");
                    }
                )
                    : null,
                // Borde cuando NO está seleccionado
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                ),
                // Borde cuando haces clic
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2.0),
                ),

                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isUsuariosTab 
              ? _buildList(filteredUsuarios, _usuariosScrollController, _isLoadingUsuarios, _hasMoreUsuarios, true) 
              : _buildList(filteredTagos, _tagosScrollController, _isLoadingTagos, _hasMoreTagos, false),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, bool isSelected, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.doradoClaro : AppColors.azulContenedor,
        foregroundColor: isSelected ? AppColors.azulOscuro : AppColors.doradoClaro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data, ScrollController controller, bool isLoading, bool hasMore, bool isUserList) {
    if (data.isEmpty && isLoading) return const Center(child: CircularProgressIndicator());
    if (data.isEmpty) return Center(child: Text(isUserList ? "No se encontraron usuarios" : "No se encontraron TaGos"));

    return ListView.builder(
      controller: controller,
      itemCount: data.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == data.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        return isUserList ? _userTile(data[index]) : _tagoTile(data[index]);
      },
    );
  }

  Widget _userTile(Map<String, dynamic> userData) {
    final String uid = userData['id'];
    final String name = userData['usuario'] ?? 'Sin nombre';
    final String? photoUrl = userData['photoUrl'];
    bool isAdmin = userData['isAdmin'] ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(name, style: TextStyle(color: AppColors.blancoTexto),),
      trailing: Switch(
        value: isAdmin,
        inactiveThumbColor: AppColors.azulContenedor,
        inactiveTrackColor: AppColors.azulStamps,
        activeColor: AppColors.doradoClaro,
        onChanged: (value) async {
          setState(() {
            final realIndex = _usuariosData.indexWhere((u) => u['id'] == uid);
            if (realIndex != -1) _usuariosData[realIndex]['isAdmin'] = value;
          });
          try {
            await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({'isAdmin': value});
          } catch (e) {
            setState(() {
              final realIndex = _usuariosData.indexWhere((u) => u['id'] == uid);
              if (realIndex != -1) _usuariosData[realIndex]['isAdmin'] = !value;
            });
          }
        },
      ),
    );
  }

  Widget _tagoTile(Map<String, dynamic> tagoData) {
    final String id = tagoData['id'];
    final String titulo = tagoData['titulo'] ?? 'Sin título';
    final String? imagenUrl = tagoData['imagenUrl'];
    final int reportes = tagoData['reportes'] ?? 0;
    final bool isCritical = reportes >= 5;

    return ListTile(
      tileColor: isCritical ? Colors.red.withOpacity(0.2) : null,
      leading: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: imagenUrl != null ? DecorationImage(image: NetworkImage(imagenUrl), fit: BoxFit.cover) : null,
        ),
        child: imagenUrl == null ? const Icon(Icons.image) : null,
      ),
      title: Text(titulo, style: TextStyle(color: AppColors.blancoTexto), maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: isCritical ? Text("Reportes: $reportes", style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCritical)
            IconButton(
              icon: const Icon(Icons.build, color: AppColors.doradoClaro),
              tooltip: "Marcar como arreglado",
              onPressed: () => _resetReportes(id),
            ),
          IconButton(icon: const Icon(Icons.edit, color: AppColors.azulClaro), onPressed: () => _editTagoDialog(id, tagoData)),
          IconButton(icon: Icon(Icons.delete, color: AppColors.rojoSuave), onPressed: () => _deleteTagoDialog(id)),
        ],
      ),
    );
  }

  Future<void> _resetReportes(String id) async {
    try {
      await FirebaseFirestore.instance.collection('marcadores').doc(id).update({'reportes': 0});
      setState(() {
        final realIndex = _tagosData.indexWhere((t) => t['id'] == id);
        if (realIndex != -1) {
          _tagosData[realIndex]['reportes'] = 0;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("TaGo arreglado"))
        );
      }
    } catch (e) {
      debugPrint("Error resetting reports: $e");
    }
  }

  void _editTagoDialog(String id, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['titulo']);
    final descController = TextEditingController(text: data['descripcion']);
    final hintController = TextEditingController(text: data['pista']);
    File? newImage;
    String? currentImageUrl = data['imagenUrl'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.azulContenedor,
          title: const Text(
            "Editar TaGo",
            style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Contenedor de Imagen con estilo de la app
                GestureDetector(
                  onTap: () async {
                    final file = await ImageHelper.mostrarSelector(context);
                    if (file != null) setDialogState(() => newImage = file);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.doradoClaro, width: 2),
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.azulOscuro,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: newImage != null
                          ? Image.file(newImage!, fit: BoxFit.cover)
                          : (currentImageUrl != null
                          ? Image.network(currentImageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, color: AppColors.doradoClaro)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Inputs con estilo personalizado
                _buildEditField(titleController, "Título"),
                _buildEditField(descController, "Descripción", maxLines: 3),
                _buildEditField(hintController, "Pista", maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: AppColors.blancoTexto)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doradoClaro,
                foregroundColor: AppColors.azulOscuro,
              ),
              onPressed: () async {
                String? finalImageUrl = currentImageUrl;
                if (newImage != null) {
                  finalImageUrl = await _dbService.subirImagenMarcador(id, newImage!);
                }
                await FirebaseFirestore.instance.collection('marcadores').doc(id).update({
                  'titulo': titleController.text,
                  'descripcion': descController.text,
                  'pista': hintController.text,
                  'imagenUrl': finalImageUrl,
                });
                setState(() {
                  final realIndex = _tagosData.indexWhere((t) => t['id'] == id);
                  if (realIndex != -1) {
                    _tagosData[realIndex]['titulo'] = titleController.text;
                    _tagosData[realIndex]['descripcion'] = descController.text;
                    _tagosData[realIndex]['pista'] = hintController.text;
                    _tagosData[realIndex]['imagenUrl'] = finalImageUrl;
                  }
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

// Widget auxiliar para no repetir código de estilo en los campos
  Widget _buildEditField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.blancoTexto),
        cursorColor: AppColors.doradoClaro,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.doradoClaro),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.doradoClaro),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.doradoClaro, width: 2),
          ),
        ),
      ),
    );
  }

  void _deleteTagoDialog(String id) {
    // Obtenemos los datos del tago para saber quién es el creador antes de borrarlo
    final tagoData = _tagosData.firstWhere((t) => t['id'] == id);
    final String creadorId = tagoData['creadorId'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.azulContenedor,
        title: const Text("Confirmar borrado total",
            style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold)),
        content: const Text(
          style: TextStyle(color: AppColors.blancoTexto),
            "Se borrará el TaGo, esta acción no se puede deshacer. ¿Seguro que quieres proceder?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: AppColors.blancoTexto))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojoSuave),
            onPressed: () async {
              // Mostrar un indicador de carga ya que esto puede tardar unos segundos
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // Llamamos a la lógica pesada en el servicio
                await _dbService.eliminarTagoCompleto(id, creadorId);

                setState(() {
                  _tagosData.removeWhere((t) => t['id'] == id);
                });

                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("TaGo y escaneos eliminados correctamente")),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                debugPrint("Error al eliminar: $e");
              }
            },
            child: const Text( style: TextStyle(color: AppColors.blancoTexto), "Borrar"),
          ),
        ],
      ),
    );
  }
}
