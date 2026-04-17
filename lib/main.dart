import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/video_provider.dart';
import 'navigation/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'services/connectivity_service.dart';
import 'services/presence_service.dart';

class _AppBootstrapState {
  final bool firebaseReady;
  final String? firebaseError;

  const _AppBootstrapState({
    required this.firebaseReady,
    this.firebaseError,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe timeago
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  // Status bar şeffaf
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Dikey yön kilidi
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase bağlandı');
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('Firebase hatası: $e');
  }

  // Self-healing: bağlantı izlemeyi başlat
  ConnectivityService().startMonitoring();

  runApp(
    VibeoApp(
      bootstrapState: _AppBootstrapState(
        firebaseReady: firebaseError == null,
        firebaseError: firebaseError,
      ),
    ),
  );
}

class VibeoApp extends StatelessWidget {
  final _AppBootstrapState bootstrapState;

  const VibeoApp({super.key, required this.bootstrapState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vibeo',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF03070D),
          primaryColor: Colors.cyanAccent,
          canvasColor: const Color(0xFF03070D),
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            secondary: Colors.cyanAccent,
            surface: Color(0xFF0B141D),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF03070D),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0B141D),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF0B141D),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.cyanAccent, width: 1.2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
          ),
          dividerColor: Colors.white.withValues(alpha: 0.08),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.cyanAccent,
          ),
        ),
        home: OfflineWrapper(
          child: _AuthGate(bootstrapState: bootstrapState),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final _AppBootstrapState bootstrapState;

  const _AuthGate({required this.bootstrapState});

  @override
  Widget build(BuildContext context) {
    if (!bootstrapState.firebaseReady) {
      PresenceService.stop();
      return _StartupErrorScreen(
        message: bootstrapState.firebaseError ??
            'Firebase başlatılamadı. Lütfen sayfayı yenileyin.',
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          PresenceService.stop();
          return _StartupErrorScreen(
            message: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF03070D),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SplashLogo(),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Colors.cyanAccent),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // Kullanıcı giriş yapmış — profili yükle + presence başlat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserProvider>().fetchCurrentUser();
          });
          PresenceService.start();
          return const MainNavigation();
        }

        // Çıkış yapıldıysa presence'i durdur
        PresenceService.stop();

        return const LoginScreen();
      },
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final String message;

  const _StartupErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SplashLogo(),
              const SizedBox(height: 24),
              const Icon(
                Icons.error_outline,
                color: Colors.orangeAccent,
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulama başlatılamadı',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Safari kullanıyorsan sayfayı tamamen yenileyip tekrar dene.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Colors.cyanAccent, Color(0xFF003333)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  blurRadius: 30),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.black, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'vibeo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 16)],
          ),
        ),
      ],
    );
  }
}
