import 'package:flutter/material.dart';

const Color ink = Color(0xFF101827);
const Color panel = Color(0xFF192437);
const Color panelRaised = Color(0xFF223149);
const Color coral = Color(0xFFFF775F);
const Color aqua = Color(0xFF6BD8C8);
const Color gold = Color(0xFFF4C66A);
const Color mutedText = Color(0xFFA8B4C7);

ThemeData buildBoardKingsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: coral,
    brightness: Brightness.dark,
  ).copyWith(
    primary: coral,
    secondary: aqua,
    surface: panel,
    onSurface: const Color(0xFFF7F4ED),
    outline: const Color(0xFF3A4B63),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ink,
    appBarTheme: const AppBarTheme(
      backgroundColor: ink,
      foregroundColor: Color(0xFFF7F4ED),
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.12),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(fontSize: 13, height: 1.45),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: coral,
        foregroundColor: ink,
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF7F4ED),
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: Color(0xFF3A4B63)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: panelRaised,
      selectedColor: coral,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      side: BorderSide.none,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    dividerColor: const Color(0xFF314159),
  );
}

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.scrollable = true,
    this.showBack = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool scrollable;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Text(title),
        actions: trailing == null ? null : [trailing!],
      ),
      body: SafeArea(
        top: false,
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: child,
              ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF202E43), panel],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 7))],
        ),
        child: child,
      );
}

class GameLobbyHero extends StatelessWidget {
  const GameLobbyHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [accent.withOpacity(0.2), panelRaised, panel],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.32)),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: accent.withOpacity(0.17), borderRadius: BorderRadius.circular(19)),
              child: Icon(icon, color: accent, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: mutedText, height: 1.4)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: accent.withOpacity(0.13), borderRadius: BorderRadius.circular(30)),
                    child: Text(badge, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: aqua))),
        ],
      );
}

class GameActionButton extends StatelessWidget {
  const GameActionButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.play_arrow_rounded),
          label: Text(label),
        ),
      );
}

class ComingSoonLabel extends StatelessWidget {
  const ComingSoonLabel({super.key, this.label = 'قريباً'});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30)),
        child: Text(label, style: const TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
