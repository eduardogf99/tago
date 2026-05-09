import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/tago_dialogs.dart';

class TagoController {
  static final DatabaseService _dbService = DatabaseService();

  static Future<void> handleTagoUnlock(String scannedId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String cleanId = scannedId.trim();

    try {
      final tagoData = await _dbService.obtenerMarcadorPorId(cleanId);
      if (tagoData == null) return;

      final String titulo = tagoData['titulo'] ?? 'Sin título';
      final String codigoPais = tagoData['codigo_pais'] ?? '';
      final String? imagenUrl = tagoData['imagenUrl']; // Extraemos la imagen

      final userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      final scanDocRef = userDocRef.collection('escaneos').doc(cleanId);
      
      final scanDoc = await scanDocRef.get();

      if (!scanDoc.exists) {
        // NUEVO DESCUBRIMIENTO
        await _dbService.registrarEscaneo(user.uid, cleanId);

        bool esPrimerTagoDelPais = false;
        if (codigoPais.isNotEmpty) {
          final userData = await _dbService.obtenerUsuario(user.uid);
          List<dynamic> paises = userData?.paisesDescubiertos ?? [];
          if (!paises.contains(codigoPais)) {
            esPrimerTagoDelPais = true;
            await _dbService.actualizarUsuario(user.uid, {
              'paises_descubiertos': FieldValue.arrayUnion([codigoPais])
            });
          }
        }

        if (context.mounted) {
          TagoDialogs.mostrarNuevoDesbloqueo(
            context: context,
            titulo: titulo,
            scannedId: cleanId,
            esPrimerTagoDelPais: esPrimerTagoDelPais,
            codigoPais: codigoPais,
            imagenUrl: imagenUrl, // Pasamos la imagen
          );
        }
      } else {
        // YA ESTABA ESCANEADO
        await scanDocRef.set({
          'tagoId': cleanId,
          'fechaEscaneo': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          TagoDialogs.mostrarYaDesbloqueado(
            context: context,
            titulo: titulo,
            scannedId: cleanId,
            imagenUrl: imagenUrl, // Pasamos la imagen
          );
        }
      }
    } catch (e) {
      debugPrint("Error en handleTagoUnlock: $e");
    }
  }
}
