import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/video_provider.dart';
import 'navigation/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'services/connectivity_service.dart';

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase bağlandı');
  } catch (e) {
    debugPrint('Firebase hatası: $e');
  }

  // Self-healing: bağlantı izlemeyi başlat
  ConnectivityService().startMonitoring();

  runApp(const VibeoApp());
}

class VibeoApp extends StatelessWidget {
  const VibeoApp({super.key});

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
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.cyanAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            secondary: Colors.cyanAccent,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const OfflineWrapper(child: _AuthGate()),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill,
                      size: 72, color: Colors.cyanAccent),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Colors.cyanAccent),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // Kullanıcı giriş yapmış — profili yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserProvider>().fetchCurrentUser();
          });
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}
