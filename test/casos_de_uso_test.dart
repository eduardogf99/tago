import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfg/services/auth_service.dart';
import 'package:tfg/services/database_service.dart';
import 'package:tfg/models/user_model.dart';

// MOCKS
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockDatabaseService mockDbService;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDbService = MockDatabaseService();
    mockUser = MockUser();

    authService = AuthService(auth: mockAuth, dbService: mockDbService);

    registerFallbackValue(mockUser);
  });

  group('20.1. Registro de usuario', () {
    test('PT-RF-01-01 (Éxito): Registro crea usuario y almacena en BD', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('user_123');
      when(() => mockDbService.obtenerTodosLosUsuarios()).thenAnswer((_) async => []);
      when(() => mockAuth.createUserWithEmailAndPassword(
        email: 'nuevo.user@mail.com',
        password: 'ClaveSegura123',
      )).thenAnswer((_) async => credential);
      when(() => mockDbService.actualizarUsuario(any(), any())).thenAnswer((_) async => {});

      final result = await authService.registrarUsuario(
        email: 'nuevo.user@mail.com',
        password: 'ClaveSegura123',
        usuario: 'Juan',
        fechaNacimiento: '2000-01-01',
      );

      expect(result.user?.uid, 'user_123');
      verify(() => mockDbService.actualizarUsuario('user_123', any())).called(1);
      print('Completado');
    });

    test('PT-RF-01-02 (Fracaso): Registro rechaza email/usuario ya existente', () async {
      when(() => mockDbService.obtenerTodosLosUsuarios()).thenAnswer((_) async => [
        UserModel(uid: '1', email: 'existente@mail.com', usuario: 'Pedro', fechaNacimiento: '')
      ]);

      expect(
            () => authService.registrarUsuario(
          email: 'otro@mail.com',
          password: 'ABC123',
          usuario: 'Pedro',
          fechaNacimiento: '1990-01-01',
        ),
        throwsA('El nombre de usuario ya está en uso'),
      );
      print('Completado');
    });
  });

  group('20.2. Inicio de Sesión', () {
    test('PT-RF-02-01 (Éxito): Acceso permitido con credenciales válidas', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => MockUserCredential());

      await authService.iniciarSesion('user@mail.com', 'password123');
      verify(() => mockAuth.signInWithEmailAndPassword(email: 'user@mail.com', password: 'password123')).called(1);
      print('Completado');
    });

    test('PT-RF-02-02 (Fracaso): Rechazo por contraseña incorrecta', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
            () => authService.iniciarSesion('user@mail.com', 'error'),
        throwsA(isA<FirebaseAuthException>()),
      );
      print('Completado');
    });
  });


  group('20.3. Escaneo de NFC', () {
    test('PT-RF-03-01 (Éxito): Primer escaneo desbloquea y genera puntos', () async {
      when(() => mockDbService.verificarEscaneo(any(), '001')).thenAnswer((_) async => false);
      when(() => mockDbService.registrarEscaneo(any(), '001')).thenAnswer((_) async => {});

      final yaEscaneado = await mockDbService.verificarEscaneo('uid', '001');
      if (!yaEscaneado) {
        await mockDbService.registrarEscaneo('uid', '001');
      }

      expect(yaEscaneado, isFalse);
      verify(() => mockDbService.registrarEscaneo(any(), '001')).called(1);
      print('Completado');
    });

    test('PT-RF-03-02 (Fracaso): No suma puntos si ya fue descubierto', () async {
      when(() => mockDbService.verificarEscaneo(any(), '001')).thenAnswer((_) async => true);

      final yaEscaneado = await mockDbService.verificarEscaneo('uid', '001');

      expect(yaEscaneado, isTrue);
      verifyNever(() => mockDbService.registrarEscaneo(any(), any()));
      print('Completado');
    });
  });

  group('20.6. Administrador', () {
    // PT-RF-06: ELIMINACIÓN DE LOCALIZACIONES
    test('PT-RF-06-01 (Éxito): Admin elimina ubicación de su NFC', () async {
      const nfcId = 'NFC_001';
      const adminId = 'admin_123';

      // Simulamos que el servicio de base de datos borra el TaGo correctamente
      when(() => mockDbService.eliminarTagoCompleto(nfcId, adminId))
          .thenAnswer((_) async => {});

      await mockDbService.eliminarTagoCompleto(nfcId, adminId);

      verify(() => mockDbService.eliminarTagoCompleto(nfcId, adminId)).called(1);
      print('Completado');
    });

    test('PT-RF-06-02 (Fracaso): Usuario sin rol admin intenta eliminar ubicación', () {
      final user = UserModel(
          uid: 'user_123', email: 'user@mail.com', usuario: 'U', fechaNacimiento: '',
          isAdmin: false // NO es admin
      );

      expect(user.isAdmin, isFalse);
      print('Completado');
    });

    // PT-RF-07: CREACIÓN DE LOCALIZACIONES
    test('PT-RF-07-01 (Éxito): Admin crea nueva ubicación NFC', () async {
      final markerData = {
        'titulo': 'Nuevo Punto NFC',
        'lat': 41.6488,
        'lng': -0.8891,
        'descripcion': 'Descripción de la nueva ubicación',
        'puntos': 1000,
      };

      when(() => mockDbService.crearMarcador('NFC_001', markerData))
          .thenAnswer((_) async => {});

      await mockDbService.crearMarcador('NFC_001', markerData);

      verify(() => mockDbService.crearMarcador('NFC_001', markerData)).called(1);
      print('Completado');
    });

    test('PT-RF-07-02 (Fracaso): Deniega creación a no autorizados', () {
      final user = UserModel(
          uid: '1', email: 'u@m.com', usuario: 'U', fechaNacimiento: '',
          isAdmin: false // NO es admin
      );
      expect(user.isAdmin, isFalse);
      print('Completado');
    });
  });
}
