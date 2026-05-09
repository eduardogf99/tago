import 'package:flutter/material.dart';
import '../screens/tago_screen.dart';
import '../theme/app_colors.dart';

/// Este widget representa la tarjeta visual de un TaGo en el libro de colección.
/// Se encarga de mostrar la imagen, el título y gestionar la navegación al detalle.
class TagoCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const TagoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagoScreen(tagoId: item['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.doradoClaro,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Imagen con bordes redondeados
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: item['imagenUrl'] != null && item['imagenUrl'].toString().isNotEmpty
                    ? Image.network(
                        item['imagenUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            color: AppColors.azulContenedor,
                            child: const Icon(Icons.broken_image, color: AppColors.azulStamps)
                          ),
                      )
                    : Container(
                        color: AppColors.azulStamps,
                        child: const Icon(Icons.image, color: AppColors.azulStamps, size: 40),
                      ),
              ),
            ),
            // Título del TaGo
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                item['titulo'] ?? 'TaGo sin nombre',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.azulOscuro,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
