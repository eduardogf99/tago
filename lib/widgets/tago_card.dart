import 'package:flutter/material.dart';
import '../screens/tago_screen.dart';

/// Este widget representa la tarjeta visual de un TaGo en el libro de colección.
/// Se encarga de mostrar la imagen, el título y gestionar la navegación al detalle.
class TagoCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const TagoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Al tocar la tarjeta, enviamos al usuario a la pantalla de detalle del TaGo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagoScreen(tagoId: item['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            // PARTE SUPERIOR: Imagen con bordes redondeados arriba
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: item['imagenUrl'] != null && item['imagenUrl'].toString().isNotEmpty
                    ? Image.network(
                        item['imagenUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            color: Colors.grey[200], 
                            child: const Icon(Icons.broken_image, color: Colors.grey)
                          ),
                      )
                    : Container(
                        color: Colors.deepPurple.shade50,
                        child: const Icon(Icons.image, color: Colors.deepPurple, size: 40),
                      ),
              ),
            ),
            // PARTE INFERIOR: Título del TaGo
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                item['titulo'] ?? 'TaGo sin nombre',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
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
