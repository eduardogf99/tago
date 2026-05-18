import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

Future<String> _loadTermsText() async {
  return await rootBundle.loadString('assets/texts/terms.txt');
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.doradoClaro),
        title: const Text(
          'TÉRMINOS Y CONDICIONES',
          style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.azulContenedor,
                borderRadius: BorderRadius.circular(20),
              ),
              // Usamos FutureBuilder para esperar a que el texto se lea
              child: FutureBuilder<String>(
                future: _loadTermsText(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.doradoClaro),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Error al cargar los términos y condiciones.',
                      style: TextStyle(color: AppColors.error),
                    );
                  }

                  // Si todo va bien, mostramos el texto del archivo
                  return Text(
                    snapshot.data ?? 'No se encontró contenido.',
                    style: const TextStyle(
                      color: AppColors.blancoTexto,
                      fontSize: 14, // Un pelín más pequeño para que sea más legible si es largo
                      height: 1.4,  // Interlineado cómodo para leer
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}