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
        scaffoldBackgroundColor:
            Colors.transparent, // Tetap transparan untuk background gambar
        // --- SETTING GLOBAL UNTUK SEMUA SEARCH/TEXTFIELD ---
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // Putih bersih untuk semua input
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIconColor: const Color(
            0xFF27AE60,
          ), // Warna icon search global hijau
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          // Border saat tidak ditekan
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),

          // Border saat ditekan (Focus)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF27AE60), width: 1.5),
          ),

          // Border default lainnya
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      // Builder ini akan membungkus semua halaman (child) dengan Stack background
      builder: (context, child) {
        // Mendapatkan orientasi saat ini
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8EC),
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 1. LAMPION (Tengah Atas)
              Positioned(
                top: isLandscape
                    ? MediaQuery.of(context).size.height * 0.2
                    : MediaQuery.of(context).size.height * 0.1,
                left: 0,
                right: 0,
                child: Image.asset(
                  'lib/assets/images/lampion.png',
                  // Di landscape, lampion dibuat lebih kecil (tinggi 15% layar) supaya tidak makan tempat
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

              // 2. MASJID (Kiri Bawah)
              Positioned(
                bottom: 0,
                left: 0,
                child: SizedBox(
                  // Di landscape gunakan 25% lebar layar, di portrait 40%
                  width: screenWidth * (isLandscape ? 0.25 : 0.4),
                  child: Image.asset(
                    'lib/assets/images/masjid.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              ),

              // 3. SEKOLAH (Kanan Bawah)
              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  // Di landscape gunakan 25% lebar layar, di portrait 40%
                  width: screenWidth * (isLandscape ? 0.25 : 0.4),
                  child: Image.asset(
                    'lib/assets/images/sekolah.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),

              // 4. TULISAN/GAMBAR TENGAH (Watermark)
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity:
                        0.8, // Dibuat sangat samar agar tidak mengganggu konten
                    child: Image.asset(
                      'lib/assets/images/SiSmart.png',
                      // Ukuran logo tengah mengecil di landscape agar tidak bertumpuk dengan masjid/sekolah
                      width: screenWidth * (isLandscape ? 0.3 : 0.6),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 5. KONTEN APLIKASI
              if (child != null) child,
            ],
          ),
        );
      },
    );
  }
}
