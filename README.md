//TaGo//

//Descripción//

El objetivo de esta aplicación es la localización unas pegatinas NFC que están escondidas por el mundo. 

La aplicación tiene un mapa de donde esta cada marcador.

Cuando una persona encuentre una pegatina NFC, esta la podrá escanear con el NFC de su móvil y si no tiene la aplicación le llevará a la play store o a la forma de conseguir descargar la app.

Cuando tenga la app, esta persona desbloqueara esa zona como descubierta, desbloqueando toda la info del sitio, datos curiosos del mismo, además de poder añadirlo a su biblioteca de NFC. Esta contendrá todos los marcadores desbloqueados.

También se implementaa un sistema de medallas que representarán los países que han descubierto.

Existe un ranking global con todos los usuarios registrados en la aplicación.

//Arquitectura del sistema//

--Arquitectura del Backend (API REST)

El backend de la aplicación se implementa mediante una función serverless basada en Node.js y Express, desplegada sobre el entorno de Firebase Functions.

-backend/functions/index.js

Este archivo constituye el núcleo del sistema servidor. En él se define la API REST que expone los diferentes endpoints utilizados por la aplicación móvil. Su función principal es actuar como intermediario seguro entre el cliente y Firestore, gestionando operaciones CRUD relacionadas con:

- Usuarios
	- Marcadores (TaGos)
	- Escaneos de NFC

La lógica implementada en este archivo garantiza que todas las operaciones sobre la base de datos se realicen de forma controlada, aplicando validaciones y evitando accesos directos desde el cliente. De este modo, se refuerza la seguridad del sistema y se centraliza la gestión de datos en un único punto.

Arquitectura de la Aplicación (Flutter)
La aplicación cliente desarrollada en Flutter sigue una arquitectura modular organizada en capas, separando claramente la configuración, los modelos de datos, la lógica de negocio, la interfaz de usuario y los componentes reutilizables.



--Raíz y Configuración
-main.dart

Es el punto de entrada de la aplicación. En este archivo se inicializan los servicios principales, incluyendo Firebase, la configuración del sistema de navegación global y el lector NFC persistente. Este último componente permite la detección continua de etiquetas NFC incluso cuando el usuario navega entre pantallas, lo cual es esencial para la dinámica de geocaching de TaGo.

-firebase_options.dart

Archivo generado automáticamente por Firebase CLI que contiene la configuración necesaria (API keys, project ID, etc.) para establecer la conexión con el proyecto de Firebase.

--Capa de Datos (Models)
Esta capa define la estructura de los datos utilizados dentro de la aplicación, garantizando consistencia en la comunicación con la API REST.

-lib/models/marker_model.dart

Define la entidad TaGo, que representa un marcador dentro del sistema. Incluye atributos como identificador, título, coordenadas geográficas e imagen. Además, implementa el método fromMap, encargado de transformar la respuesta JSON proveniente de la API en un objeto utilizable por Flutter.

-lib/models/user_model.dart

Define la estructura de los usuarios del sistema, incluyendo campos como correo electrónico, nombre, rol de administrador y foto de perfil.

--Capa de Lógica y Conectividad (Services)
Esta capa es fundamental en la arquitectura híbrida del sistema, ya que gestiona la comunicación con el backend y define el comportamiento de acceso a datos.

-lib/services/database_service.dart

Este archivo representa el componente más crítico del sistema de conectividad. Implementa la lógica de comunicación con la API REST desarrollada en Node.js, centralizando todas las operaciones de lectura y escritura.
Su característica más relevante es la implementación de un modelo híbrido de persistencia, que funciona de la siguiente manera:

En condiciones normales, la aplicación realiza peticiones a la API REST.

Si la API no responde o se produce un timeout, el sistema activa automáticamente un mecanismo de respaldo.

Este fallback consiste en el acceso directo a Firestore desde el cliente.

Este enfoque garantiza la tolerancia a fallos, mejorando la disponibilidad del sistema y evitando interrupciones en la experiencia del usuario. No obstante, la arquitectura prioriza siempre la API REST como fuente principal de verdad.

-lib/services/auth_service.dart

Gestiona los procesos de autenticación de usuarios, incluyendo inicio de sesión y registro mediante Email/Password y Google Sign-In. Este servicio delega la creación y actualización de perfiles al database_service, asegurando la coherencia con la arquitectura basada en API REST.
20.2.4. Capa de Interfaz (Screens)
La capa de presentación está compuesta por múltiples pantallas que estructuran la experiencia del usuario dentro de la aplicación.

-lib/screens/main_screen.dart

Actúa como contenedor principal de la aplicación. Gestiona la navegación entre las diferentes secciones mediante una barra de pestañas (Mapa, Libro y Perfil).

-lib/screens/map_screen.dart y map_admin_screen.dart

Implementan la visualización del mapa interactivo basado en OpenStreetMap. La versión administrativa permite seleccionar coordenadas directamente sobre el mapa para la creación de nuevos TaGos.

-lib/screens/library_screen.dart

Representa el “Libro de Colección”, donde se muestran los TaGos desbloqueados por el usuario en forma de cuadrícula visual.

-lib/screens/tago_screen.dart

Pantalla de detalle de un TaGo. Muestra información completa del marcador, incluyendo imagen, descripción, ubicación y autor. También gestiona la compatibilidad entre distintos formatos de fecha utilizados en versiones anteriores y actuales del sistema.

-lib/screens/create_nfc_screen.dart

Pantalla destinada a la creación de nuevos TaGos. Incluye la funcionalidad de escritura de identificadores en etiquetas NFC físicas, así como un modo de simulación para pruebas en entornos sin hardware NFC.

-lib/screens/login_screen.dart, signin_screen.dart y reset_password_screen.dart

Conforman el flujo completo de autenticación y recuperación de credenciales.

-lib/screens/profile_screen.dart

Permite la gestión del perfil del usuario, incluyendo la modificación del nombre y la imagen de perfil.

-lib/screens/manage_admins_screen.dart

Herramienta de administración que permite gestionar los permisos de otros usuarios dentro del sistema.

-lib/screens/ranking_screen.dart

Permite visualizar el ranking de todos los usuarios.
--Componentes Reutilizables (Widgets)
Esta capa contiene elementos de interfaz reutilizables que permiten mantener consistencia visual y reducir la duplicación de código.

-lib/widgets/tago_card.dart

Componente visual que representa cada TaGo dentro del libro de colección.

-widgets/osm_map_widget.dart

Widget encargado de renderizar el mapa basado en OpenStreetMap, utilizado en las pantallas de visualización y administración de ubicaciones.

-widgets/app_navigation_bar.dart

Implementa la barra de navegación inferior personalizada utilizada en toda la aplicación.

-widgets/image_helper.dart

Utilidad auxiliar que gestiona la selección de imágenes desde cámara o galería, incluyendo funcionalidades de recorte y preprocesamiento.

//Servicios//
Para la aplicación se ha utilizado el servicio Firebase, tanto para el almacén de bases de datos como para la autenticación de usuarios. Además, se ha implementado un servicio API Rest de backend que sirve de intermediario para las solicitudes con el Firestore, que se corresponde con la base de datos de Firebase

//Flujo de datos//

<img width="1536" height="1024" alt="ChatGPT Image 4 may 2026, 16_51_23" src="https://github.com/user-attachments/assets/599f3b32-e409-47aa-a99d-a7affc50f865" />

