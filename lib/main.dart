import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  runApp(const PennyPalApp());
}

class PennyPalApp extends StatefulWidget {
  const PennyPalApp({super.key});

  @override
  State<PennyPalApp> createState() => PennyPalAppState();

  static PennyPalAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<PennyPalAppState>();
}

class PennyPalAppState extends State<PennyPalApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() { super.initState(); _restoreTheme(); }
  Future<void> _restoreTheme() async { final p=await SharedPreferences.getInstance(); final v=p.getString('themeMode'); if(!mounted)return; setState(()=>_themeMode=v=='dark'?ThemeMode.dark:v=='system'?ThemeMode.system:ThemeMode.light); }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode != themeMode) setState(() => _themeMode = themeMode);
    SharedPreferences.getInstance().then((p) => p.setString('themeMode', themeMode.name));
  }

  /// Changes the active theme without overwriting the signed-in user's saved
  /// preference. Authentication screens use this to stay consistently light.
  void setSessionThemeMode(ThemeMode themeMode) {
    if (_themeMode != themeMode) setState(() => _themeMode = themeMode);
  }

  Future<void> restoreSavedTheme() => _restoreTheme();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'PennyPal',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _themeMode,
    home: const SplashScreen(),
  );
}
