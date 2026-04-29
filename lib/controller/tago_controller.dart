import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/tago_dialogs.dart';

class TagoController {
  static Future<void> handleTagoUnlock(String scannedId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Verificar si el Tago existe en la base de datos global
      final tagoDocRef = FirebaseFirestore.instance.collection('marcadores').doc(scannedId);
      final tagoDoc = await tagoDocRef.get();
      
      if (!tagoDoc.exists) {
        debugPrint("TaGo con ID $scannedId no encontrado en Firestore");
        return;
      }

      final data = tagoDoc.data() as Map<String, dynamic>;
      final String titulo = data['titulo'] ?? 'Sin título';
      final String codigoPais = data['codigo_pais'] ?? '';

      // Al escanearlo, reseteamos los reportes a 0 y actualizamos último escaneo global
      // Usamos set con merge para asegurar que el campo se cree si no existe y se resetee siempre
      await tagoDocRef.set({
        'reportes': 0,
        'ultimoEscaneo': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Verificar si el usuario ya lo ha escaneado antes
      final userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      final scanDocRef = userDocRef.collection('escaneos').doc(scannedId);
      final scanDoc = await scanDocRef.get();

      // Siempre actualizamos la fecha de escaneo personal (o la creamos si es nuevo)
      await scanDocRef.set({
        'fechaEscaneo': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      if (!scanDoc.exists) {
        // ES NUEVO: Lógica de país
        bool esPrimerTagoDelPais = false;
        if (codigoPais.isNotEmpty) {
          final userSnapshot = await userDocRef.get();
          final userData = userSnapshot.data() as Map<String, dynamic>?;
          List<dynamic> paisesDescubiertos = userData?['paises_descubiertos'] ?? [];
          
          if (!paisesDescubiertos.contains(codigoPais)) {
            esPrimerTagoDelPais = true;
            await userDocRef.update({
              'paises_descubiertos': FieldValue.arrayUnion([codigoPais])
            });
          }
        }

        // Mostrar el AlertDialog de "Nuevo TaGo desbloqueado" desde el widget especializado
        if (context.mounted) {
          TagoDialogs.mostrarNuevoDesbloqueo(
            context: context,
            titulo: titulo,
            scannedId: scannedId,
            esPrimerTagoDelPais: esPrimerTagoDelPais,
            codigoPais: codigoPais,
          );
        }
      } else {
        // YA ESTABA DESBLOQUEADO: Mostrar aviso desde el widget especializado
        if (context.mounted) {
          TagoDialogs.mostrarYaDesbloqueado(
            context: context,
            titulo: titulo,
            scannedId: scannedId,
          );
        }
      }
    } catch (e) {
      debugPrint("Error al procesar escaneo: $e");
    }
  }
}
