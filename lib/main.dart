import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalogue_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/admin_auth_service.dart';
import 'services/firebase_config.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/supabase_storage_service.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await StorageService.init();
  await AdminAuthService.init();
  await AdminAuthService.restoreSession();
  await FirebaseConfig.initialize();
  await SupabaseStorageService.initialize(
    url: 'https://xuytzirldkqtthqhcwjk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1eXR6aXJsZGtxdHRocWhjd2prIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NzYwODcsImV4cCI6MjEwOTU1MjA4N30.W37HrJ73_hd1SkoVm3CJUCGQdoiU3lWXSndWiQMSf4U',
  );
  await NotificationService.init();

  runApp(const ShalimarStoreApp());
}

class ShalimarStoreApp extends StatelessWidget {
  const ShalimarStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => CatalogueProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdminProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}