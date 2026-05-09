import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/tago_screen.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

class TagoDialogs {
  static final DatabaseService _databaseService = DatabaseService();

  static String _formatDate(dynamic date) {
    if (date == null) return 'Nunca';
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
    }
    if (date is String) {
      DateTime? dt = DateTime.tryParse(date);
      if (dt != null) return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    return 'Fecha no válida';
  }

  static void _reportar(BuildContext context, String id) async {
    try {
      await _databaseService.reportarMarcador(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gracias por tu reporte. Lo revisaremos pronto."),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al enviar el reporte."),
          ),
        );
      }
    }
  }

  static Widget _buildReportMenu(BuildContext context, String id) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.doradoClaro),
      color: AppColors.azulContenedor,
      onSelected: (value) {
        if (value == 'reportar') {
          _reportar(context, id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'reportar',
          child: Row(
            children: [
              Icon(Icons.report, color: AppColors.error),
              const SizedBox(width: 8),
              const Text(
                'Reportar',
                style: TextStyle(color: AppColors.blancoTexto),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void mostrarInfoMarcador({
    required BuildContext context,
    required String docId,
    required bool hasScanned,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        bool mostrarPistaLocal = false;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('marcadores')
              .doc(docId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const AlertDialog(
                backgroundColor: AppColors.azulContenedor,
                content: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.doradoClaro,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            String titulo = data['titulo'] ?? 'Sin título';
            String? imagenUrl = data['imagenUrl'];
            String pista = data['pista'] ?? 'No hay pistas disponibles.';

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: AppColors.azulContenedor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.doradoClaro,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildReportMenu(context, docId),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.doradoClaro,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: hasScanned
                              ? (imagenUrl != null && imagenUrl.isNotEmpty
                              ? Image.network(
                            imagenUrl,
                            fit: BoxFit.cover,
                          )
                              : const Icon(
                            Icons.image,
                            size: 50,
                            color: AppColors.azulClaro,
                          ))
                              : const Center(
                            child: Text(
                              "???",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulClaro,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (hasScanned)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.doradoClaro,
                            foregroundColor: AppColors.azulOscuro,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TagoScreen(tagoId: docId),
                              ),
                            );
                          },
                          child: const Text("Ver"),
                        )
                      else
                        Column(
                          children: [
                            const Text(
                              "Escanea este TaGo para ver su contenido",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.azulClaro,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Divider(color: AppColors.azulClaro),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Pista",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.doradoClaro,
                                  ),
                                ),
                                Switch(
                                  activeColor: AppColors.doradoClaro,
                                  value: mostrarPistaLocal,
                                  onChanged: (value) {
                                    setState(() {
                                      mostrarPistaLocal = value;
                                    });
                                  },
                                ),
                              ],
                            ),

                            if (mostrarPistaLocal)
                              Padding(
                                padding:
                                const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  pista,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.blancoTexto,
                                  ),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.azulClaro),

                      Text(
                        "Último escaneo: ${_formatDate(data['ultimoEscaneo'])}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.azulClaro,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static void mostrarNuevoDesbloqueo({
    required BuildContext context,
    required String titulo,
    required String scannedId,
    required bool esPrimerTagoDelPais,
    required String? codigoPais,
    String? imagenUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.azulContenedor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: AppColors.doradoClaro),
                SizedBox(width: 10),
                Text(
                  "¡Nuevo TaGo!",
                  style: TextStyle(color: AppColors.doradoClaro),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _buildReportMenu(context, scannedId),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Has desbloqueado un nuevo sitio:",
              style: TextStyle(color: AppColors.blancoTexto),
            ),
            const SizedBox(height: 15),

            // Mostrar imagen del TaGo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.doradoClaro,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: (imagenUrl != null && imagenUrl.isNotEmpty)
                    ? Image.network(
                  imagenUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image,
                    size: 50,
                    color: AppColors.azulClaro,
                  ),
                )
                    : const Icon(
                  Icons.image,
                  size: 50,
                  color: AppColors.azulClaro,
                ),
              ),
            ),

            const SizedBox(height: 15),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.doradoClaro,
              ),
              textAlign: TextAlign.center,
            ),
            if (esPrimerTagoDelPais && codigoPais != null) ...[
              const SizedBox(height: 20),
              const Text(
                "¡Primer TaGo de este país!",
                style: TextStyle(
                  color: AppColors.doradoClaro,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SvgPicture.network(
                  'https://flagcdn.com/${codigoPais.toLowerCase()}.svg',
                  width: 100,
                  placeholderBuilder: (context) =>
                  const CircularProgressIndicator(
                    color: AppColors.doradoClaro,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(color: AppColors.azulClaro),
            Text(
              "Último escaneo: ${_formatDate(DateTime.now())}",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.azulClaro,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(color: AppColors.blancoTexto),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.doradoClaro,
              foregroundColor: AppColors.azulOscuro,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TagoScreen(tagoId: scannedId),
                ),
              );
            },
            child: const Text("Ver"),
          ),
        ],
      ),
    );
  }

  static void mostrarYaDesbloqueado({
    required BuildContext context,
    required String titulo,
    required String scannedId,
    String? imagenUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.azulContenedor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.azulIntermedio),
                SizedBox(width: 10),
                Text(
                  "Ya desbloqueado",
                  style: TextStyle(color: AppColors.doradoClaro),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _buildReportMenu(context, scannedId),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Este TaGo ya está en tu colección:",
              style: TextStyle(color: AppColors.blancoTexto),
            ),
            const SizedBox(height: 15),

            // Mostrar imagen del TaGo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.doradoClaro,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: (imagenUrl != null && imagenUrl.isNotEmpty)
                    ? Image.network(
                  imagenUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image,
                    size: 50,
                    color: AppColors.azulClaro,
                  ),
                )
                    : const Icon(
                  Icons.image,
                  size: 50,
                  color: AppColors.azulClaro,
                ),
              ),
            ),

            const SizedBox(height: 15),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.doradoClaro,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.azulClaro),
            Text(
              "Último escaneo: ${_formatDate(DateTime.now())}",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.azulClaro,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(color: AppColors.blancoTexto),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.doradoClaro,
              foregroundColor: AppColors.azulOscuro,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TagoScreen(tagoId: scannedId),
                ),
              );
            },
            child: const Text("Ver"),
          ),
        ],
      ),
    );
  }
}
