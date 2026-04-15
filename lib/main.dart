import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/routes.dart';
import 'core/config/supabase_client.dart';
import 'core/navigation/messenger_key.dart';
import 'core/navigation/navigator_key.dart';
import 'features/device/fcm_service.dart';

Future<void> setupFCMListener() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('NOTIF MASUK (FOREGROUND)');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');

    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message.notification?.body ?? 'Notifikasi baru')),
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await SupabaseConfig.init();

  await FcmService.initPermission();

  await setupFCMListener();

  FcmService.listenTokenRefresh();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.gate,
      onGenerateRoute: AppRouter.onGenerateRoute,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF27AE60), 
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIconColor: const Color(0xFF27AE60),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),


          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF27AE60), width: 1.5),
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
        ),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(const Color(0xFF27AE60)),
          trackColor: MaterialStateProperty.all(const Color(0xFF27AE60).withOpacity(0.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF27AE60),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF27AE60)),
            backgroundColor: const Color(0xFF27AE60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    
        ),
        
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF27AE60),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.all(const Color(0xFF27AE60)),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(const Color(0xFF27AE60)),
          side: BorderSide(color: const Color(0xFF27AE60)),
        ),
      ),

      builder: (context, child) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8EC),
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned(
                top: isLandscape
                    ? MediaQuery.of(context).size.height * 0.2
                    : MediaQuery.of(context).size.height * 0.1,
                left: 0,
                right: 0,
                child: Image.asset(
                  'lib/assets/images/lampion.png',

                  height: isLandscape
                      ? MediaQuery.of(context).size.height * 1
                      : null,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),

              isLandscape
                  ? Positioned(
                      top: MediaQuery.of(context).size.height * 0.2,
                      left: 0,
                      right: 0,
                      child: Image.asset(
                        'lib/assets/images/lampion.png',
                        height: MediaQuery.of(context).size.height * 1,
                        fit: BoxFit.contain,
                        alignment: Alignment.topRight,
                      ),
                    )
                  : Container(),
              isLandscape
                  ? Positioned(
                      top: MediaQuery.of(context).size.height * 0.2,
                      left: 0,
                      right: 0,
                      child: Image.asset(
                        'lib/assets/images/lampion.png',
                        height: MediaQuery.of(context).size.height * 1,
                        fit: BoxFit.contain,
                        alignment: Alignment.topLeft,
                      ),
                    )
                  : Container(),

              Positioned(
                bottom: 0,
                left: 0,
                child: SizedBox(
                  width: screenWidth * (isLandscape ? 0.25 : 0.4),
                  child: Image.asset(
                    'lib/assets/images/sekolah.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  width: screenWidth * (isLandscape ? 0.25 : 0.4),
                  child: Image.asset(
                    'lib/assets/images/masjid.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),

              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'lib/assets/images/SiSmart.png',

                      width: screenWidth * (isLandscape ? 0.3 : 0.6),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              if (child != null) child,
            ],
          ),
        );
      },
    );
  }
}
