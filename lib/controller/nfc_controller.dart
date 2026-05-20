import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../main.dart';
import 'tago_controller.dart';

class NfcController {

  static GlobalKey<NavigatorState>? _globalNavigatorKey;

  // Inicia la escucha constante de NFC para el desbloqueo automático
  static void initBackgroundListener(GlobalKey<NavigatorState> navigatorKey) async {
    _globalNavigatorKey = navigatorKey;
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) return;

      // Iniciamos el lector de fondo estándar
      await _startBackgroundSession();
    } catch (e) {
      debugPrint("Error en el lector NFC: $e");
    }
  }

  // arranca la sesión de escucha de fondo
  static Future<void> _startBackgroundSession() async {
    await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          var ndef = Ndef.from(tag);
          if (ndef != null && ndef.cachedMessage != null) {
            final records = ndef.cachedMessage!.records;
            if (records.isNotEmpty) {
              final payload = records.first.payload;
              final languageCodeLength = payload[0] & 0x3F;
              final text = String.fromCharCodes(payload.sublist(1 + languageCodeLength));
              String scannedId = text.trim();

              final context = _globalNavigatorKey?.currentContext;
              if (context != null) {
                TagoController.handleTagoUnlock(scannedId, context);
              }
            }
          }
        },
        onError: (error) async {
          debugPrint("Error en sesión de fondo NFC: $error");
        }
    );
  }

  // Apaga la escucha global temporalmente para que la pantalla de creación use el NFC
  static Future<void> pauseBackgroundListener() async {
    try {
      await NfcManager.instance.stopSession();
      debugPrint("Lector NFC de fondo PAUSADO para permitir la escritura.");
    } catch (_) {}
  }

  // Reactiva la escucha global cuando salgamos de la pantalla de creación
  static Future<void> resumeBackgroundListener() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) return;
      await _startBackgroundSession();
      debugPrint("Lector NFC de fondo REACTIVADO con éxito.");
    } catch (e) {
      debugPrint("Error al reactivar el lector NFC de fondo: $e");
    }
  }
}