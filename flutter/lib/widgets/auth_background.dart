import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.inkNavyDeep,
            AppColors.inkNavy,
            AppColors.espressoDark,
          ],
        ),
        image: DecorationImage(
          image: const AssetImage('assets/images/login_background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.inkNavyDeep.withValues(alpha: 0.45),
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
