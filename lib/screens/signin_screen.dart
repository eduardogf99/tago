import 'package:flutter/material.dart';
import 'package:tfg/screens/login_screen.dart';
import 'package:tfg/screens/main_screen.dart';

import 'map_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  bool _acceptTerms = false;
  
  //Aquí se crean los controladores
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  
  //Con esta función es con la que se registran los usuarios en firebase
  Future<void>registrarUsuario() async{
    String email = emailController.text.trim();
    String usuario = userController.text.trim();
    String password = passwordController.text.trim();
    String repeatPassword = repeatPasswordController.text.trim();
    
    if(password != repeatPassword){
      print("Las contraseñas no coinciden");
      return;
    }
    
    try{
      print("antes de firebase");
      await FirebaseFirestore.instance.collection('usuarios').add({
        'email': email,
        'usuario': usuario,
        'password': password,
      });
      print("d3espues de firebase");
      print("Usuario guardado");
    }catch(e){
      print("Error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.login),
                      label: const Text('con google'),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController, //se añaden aquí los controladores
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: repeatPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Repetir Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('Acepto los términos y condiciones'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                              (route) => false,
                        );
                      },
                      child: const Text('Registrarse'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async{
                        print("boton pulsado");

                        await registrarUsuario(); //aquí se registra el usuario
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      },
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
