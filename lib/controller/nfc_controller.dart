import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../main.dart';
import 'tago_controller.dart';

class NfcController {
  // Inicia la escucha constante de NFC para el desbloqueo automático
  static void initBackgroundListener(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) return;

      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef != null && ndef.cachedMessage != null) {
          final records = ndef.cachedMessage!.records;
          if (records.isNotEmpty) {
            // Extraemos los datos del chip
            String payload = String.fromCharCodes(records.first.payload);
            // El primer byte de NDEF suele ser el código de idioma, lo saltamos
            String scannedId = payload.substring(records.first.payload[0] + 1);

            // Obtenemos el contexto actual para poder mostrar el diálogo
            final context = navigatorKey.currentContext;
            if (context != null) {
              TagoController.handleTagoUnlock(scannedId, context);
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error en el lector NFC: $e");
    }
  }

  // Método para una sesión puntual (usado por ejemplo al crear un TaGo)
  void startSession({required Function(String) onDataRead}) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onDataRead("NFC no disponible");
      return;
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef != null && ndef.cachedMessage != null) {
        final records = ndef.cachedMessage!.records;
        if (records.isNotEmpty) {
          // Forma segura de leer el texto quitando el prefijo de idioma (UTF-8)
          final payload = records.first.payload;
          final languageCodeLength = payload[0] & 0x3F;
          final text = String.fromCharCodes(payload.sublist(1 + languageCodeLength));

          // quitamos posibles espacios o saltos de línea
          String scannedId = text.trim();

          debugPrint("TaGo detectado con ID limpio: '$scannedId'");

          final context = navigatorKey.currentContext;
          if (context != null) {
            // Ejecutamos el desbloqueo
            TagoController.handleTagoUnlock(scannedId, context);
          }
        }
      }
    });
  }
}
