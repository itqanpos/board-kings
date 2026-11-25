import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/domino/domino_game_screen.dart';
import '../features/domino/domino_lobby_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/games/game_selection_screen.dart';
import '../features/home/home_screen.dart';
import '../features/ludo/ludo_game_screen.dart';
import '../features/ludo/ludo_lobby_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/store/cosmetic_store_screen.dart';
import '../features/store/supabase_account_screen.dart';
import '../shared/widgets/game_ui.dart';

class BoardKingsApp extends StatefulWidget {
  const BoardKingsApp({super.key, this.initialLocation = '/splash'});

  final String initialLocation;

  @override
  State<BoardKingsApp> createState() => _BoardKingsAppState();
}

class _BoardKingsAppState extends State<BoardKingsApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/games', builder: (context, state) => const GameSelectionScreen()),
      GoRoute(path: '/ludo-lobby', builder: (context, state) => const LudoLobbyScreen()),
      GoRoute(path: '/domino-lobby', builder: (context, state) => const DominoLobbyScreen()),
      GoRoute(path: '/ludo', builder: (context, state) => const LudoGameScreen()),
      GoRoute(
        path: '/domino',
        builder: (context, state) {
          final requestedCount = int.tryParse(state.uri.queryParameters['players'] ?? '') ?? 2;
          final playerCount = requestedCount >= 2 && requestedCount <= 4 ? requestedCount : 2;
          return DominoGameScreen(playerCount: playerCount);
        },
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/friends', builder: (context, state) => const FriendsScreen()),
      GoRoute(path: '/store', builder: (context, state) => const CosmeticStoreScreen()),
      GoRoute(path: '/account', builder: (context, state) => const SupabaseAccountScreen()),
    ],
    errorBuilder: (context, state) => GameScaffold(
      title: 'تعذر فتح الصفحة',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_off_rounded, color: coral, size: 34),
            const SizedBox(height: 14),
            Text('المسار غير متاح', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'تحقق من الرابط ثم حاول مرة أخرى.'),
            const SizedBox(height: 18),
            GameActionButton(label: 'العودة للرئيسية', onPressed: () => context.go('/home')),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'BOARD KINGS',
        debugShowCheckedModeBanner: false,
        theme: buildBoardKingsTheme(),
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF26354C), ink, Color(0xFF121C2A)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: coral,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: coral.withOpacity(0.24), blurRadius: 36)],
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: ink, size: 42),
                ),
                const SizedBox(height: 22),
                Text('BOARD KINGS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 1.7)),
                const SizedBox(height: 7),
                const Text('اللعب يجمعنا', style: TextStyle(color: mutedText, letterSpacing: 1.1)),
                const SizedBox(height: 28),
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: aqua)),
              ],
            ),
          ),
        ),
      );
}
