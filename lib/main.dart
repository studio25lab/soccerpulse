// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Services
import 'services/theme_service.dart';
import 'services/favorites_service.dart';
import 'services/live_update_service.dart';
import 'services/haptic_service.dart';
import 'services/match_notification_preferences_service.dart';
import 'services/player_notification_preferences_service.dart';

// Pages
import 'pages/home_screen.dart';
import 'pages/calendar_screen.dart';
import 'pages/favorites_screen.dart';
import 'pages/standings_screen.dart';
import 'pages/settings_screen.dart';
import 'pages/global_search_screen.dart';
import 'pages/enhanced_h2h_screen.dart';

// Widgets
import 'widgets/live_notification_overlay.dart';
import 'widgets/quick_settings_panel.dart';

// Generated
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurazione orientamento (opzionale, rimuovi per supportare landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurazione status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Inizializza servizi
  final themeService = ThemeService();
  await themeService.loadPreferences();

  final favoritesService = FavoritesService();
  await favoritesService.loadFavorites();

  final liveUpdateService = LiveUpdateService();

  // 🆕 Inizializza il servizio notifiche match
  final matchNotificationPrefsService = MatchNotificationPreferencesService();
  await matchNotificationPrefsService.loadSettings();

  // 🆕 Inizializza il servizio notifiche giocatori
  final playerNotificationPrefsService = PlayerNotificationPreferencesService();
  await playerNotificationPrefsService.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: favoritesService),
        ChangeNotifierProvider.value(value: liveUpdateService),
        ChangeNotifierProvider.value(
            value: matchNotificationPrefsService), // 🆕
        ChangeNotifierProvider.value(
            value: playerNotificationPrefsService), // 🆕
      ],
      child: const SoccerPulseApp(),
    ),
  );
}

class SoccerPulseApp extends StatelessWidget {
  const SoccerPulseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'SoccerPulse',
          debugShowCheckedModeBanner: false,

          // Tema
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeService.themeMode,

          // Localizzazione
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it', 'IT'),
            Locale('en', 'US'),
          ],
          locale: themeService.locale,

          // Routes
          initialRoute: '/',
          routes: {
            '/': (context) => const MainScreen(),
            '/search': (context) => const GlobalSearchScreen(),
            '/h2h': (context) => const EnhancedH2HScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF2E7D32); // Verde calcio
    const secondaryColor = Color(0xFF66BB6A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
        error: Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF66BB6A);
    const secondaryColor = Color(0xFF81C784);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: Color(0xFFEF5350),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

// Main Screen con navigazione
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  late AnimationController _fabAnimationController;
  late AnimationController _notificationAnimationController;

  // Pagine principali
  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(),
    const FavoritesScreen(),
    const StandingsScreen(),
  ];

  // Titoli pagine
  final List<String> _titles = [
    'SoccerPulse',
    'Calendario',
    'Preferiti',
    'Classifiche',
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Inizializza live updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final liveUpdateService = context.read<LiveUpdateService>();
      liveUpdateService.startLiveUpdates();

      // Listener per notifiche di goal
      liveUpdateService.addListener(() {
        _handleLiveUpdate(liveUpdateService);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _notificationAnimationController.dispose();
    super.dispose();
  }

  void _handleLiveUpdate(LiveUpdateService service) {
    // Gestione eventi live (goal, cartellini, etc)
    // Qui puoi attivare le notifiche in base agli eventi
  }

  void _onPageChanged(int index) {
    _haptic.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LiveNotificationOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            // Icona ricerca
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _haptic.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalSearchScreen(),
                  ),
                );
              },
            ),
            // Icona confronto H2H (solo nella pagina classifiche)
            if (_currentIndex == 3)
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: () {
                  _haptic.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnhancedH2HScreen(),
                    ),
                  );
                },
              ),
            // Icona impostazioni
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _haptic.lightImpact();
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            // Contenuto principale con PageView
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _pages,
            ),

            // Quick Settings Panel (overlay)
            const QuickSettingsPanel(),

            // Test button per notifiche (SOLO IN DEBUG)
            if (!const bool.fromEnvironment('dart.vm.product'))
              Positioned(
                left: 16,
                bottom: 80,
                child: FloatingActionButton(
                  heroTag: 'test_notification',
                  mini: true,
                  backgroundColor: Colors.orange,
                  onPressed: _testNotifications,
                  child: const Icon(Icons.bug_report, size: 20),
                ),
              ),
          ],
        ),

        // Bottom Navigation
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              _haptic.lightImpact();
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            items: [
              BottomNavigationBarItem(
                icon:
                    Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 1
                    ? Icons.calendar_today
                    : Icons.calendar_today_outlined),
                label: 'Calendario',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(_currentIndex == 2
                        ? Icons.favorite
                        : Icons.favorite_border),
                    // Badge per numero preferiti
                    Consumer<FavoritesService>(
                      builder: (context, favorites, child) {
                        final count = favorites.totalFavorites;
                        if (count == 0) return const SizedBox.shrink();

                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                label: 'Preferiti',
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 3
                    ? Icons.leaderboard
                    : Icons.leaderboard_outlined),
                label: 'Classifiche',
              ),
            ],
          )
              .animate()
              .slideY(
                begin: 1,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              )
              .fadeIn(),
        ),
      ),
    );
  }

  // Funzione di test per notifiche (SOLO PER DEVELOPMENT)
  void _testNotifications() {
    _haptic.mediumImpact();

    // Test notifica goal
    LiveNotificationOverlay.of(context)?.showGoalNotification(
      homeTeam: 'Inter',
      awayTeam: 'Milan',
      homeScore: 1,
      awayScore: 0,
      scorer: 'Lautaro Martinez',
      minute: 23,
      homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
    );

    // Test cartellino giallo dopo 2 secondi
    Future.delayed(const Duration(seconds: 2), () {
      LiveNotificationOverlay.of(context)?.showCardNotification(
        player: 'Theo Hernandez',
        team: 'Milan',
        cardType: CardType.yellow,
        minute: 25,
      );
    });

    // Test inizio partita dopo 4 secondi
    Future.delayed(const Duration(seconds: 4), () {
      LiveNotificationOverlay.of(context)?.showMatchStartNotification(
        homeTeam: 'Juventus',
        awayTeam: 'Napoli',
        competition: 'Serie A',
      );
    });

    // Test fine partita dopo 6 secondi
    Future.delayed(const Duration(seconds: 6), () {
      LiveNotificationOverlay.of(context)?.showMatchEndNotification(
        homeTeam: 'Roma',
        awayTeam: 'Lazio',
        homeScore: 2,
        awayScore: 2,
      );
    });
  }
}
