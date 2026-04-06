import 'package:nfc_manager/nfc_manager.dart';

class NfcController {
  // Función para empezar a leer
  void startSession({required Function(String) onDataRead}) async {
    // Comprobar si el dispositivo tiene NFC activo
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      onDataRead("NFC no disponible en este dispositivo");
      return;
    }

    // Iniciar sesión de lectura
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        // Aquí extraemos los datos del tag.
        // Dependiendo de lo que haya escrito, la estructura cambia.
        var ndef = Ndef.from(tag);
        if (ndef == null || ndef.cachedMessage == null) return;

        // Suponiendo que hay un registro de texto
        String recordContent = String.fromCharCodes(ndef.cachedMessage!.records.first.payload);

        onDataRead(recordContent);

        NfcManager.instance.stopSession(); // Paramos tras leer con éxito
      } catch (e) {
        onDataRead("Error al leer: $e");
        NfcManager.instance.stopSession(errorMessage: e.toString());
      }
    });
  }

  void stopSession() {
    NfcManager.instance.stopSession();
  }
}