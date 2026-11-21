import 'package:material_ui/material_ui.dart';

import 'screens/login_page.dart';
import 'screens/main_shell.dart';
import 'screens/register_page.dart';
import 'services/session_manager.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EntreLineasApp());
}

class EntreLineasApp extends StatelessWidget {
  const EntreLineasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entre Líneas — Revista Literaria & Librería',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => SessionManager.instance.isAuthenticated
            ? const MainShell()
            : const LoginPage(),
      },
    );
  }
}
