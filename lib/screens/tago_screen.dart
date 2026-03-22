import 'package:flutter/material.dart';
import '../widgets/app_navigation_bar.dart';

class TagoScreen extends StatefulWidget {
  const TagoScreen({super.key});

  @override
  State<TagoScreen> createState() => _TagoScreenState();
}

class _TagoScreenState extends State<TagoScreen> {

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    const String loremIpsum = 
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
        'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaGo'),
      ),
      //drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'El Pilar',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Imagen circular (30% del ancho)
            Center(
              child: Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Fila con 4 iconos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_up_alt_outlined)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_down_alt_outlined)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.star_border)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ],
            ),
            const SizedBox(height: 20),
            // Texto descriptivo (Lorem Ipsum)
            const Text(
              loremIpsum,
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // Información adicional
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ultima vez escaneado: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lo han escaneado 100 usuarios',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
