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
import 'services/favorite_notification_coordinator.dart';
import 'services/haptic_service.dart';
import 'services/match_notification_preferences_service.dart';
import 'services/team_notification_preferences_service.dart';
import 'services/player_notification_preferences_service.dart';

// Pages
import 'pages/home_screen.dart';
import 'pages/calendar_screen.dart';
import 'pages/favorites_screen.dart';
import 'pages/standings_screen.dart';
import 'pages/settings_screen.dart';
import 'pages/search_screen.dart';

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
  // 🆕 Inizializza il servizio notifiche squadre
  final teamNotificationPrefsService = TeamNotificationPreferencesService();
  await teamNotificationPrefsService.loadSettings();

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
        ChangeNotifierProvider.value(
            value: teamNotificationPrefsService), // 🆕
      ],
      child: const SoccerPulseApp(),
    ),
  );
}

class SoccerPulseApp extends StatelessWidget {
  const SoccerPulseApp({super.key});

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
            '/': (context) => MainScreen(key: MainScreen.globalKey),
            '/search': (context) => const SearchScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF00BFA5); // Vivid Teal
    const secondaryColor = Color(0xFF66BB6A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
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
        selectedColor: primaryColor.withValues(alpha: 0.2),
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
        selectedColor: primaryColor.withValues(alpha: 0.3),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

// Main Screen con navigazione
class MainScreen extends StatefulWidget {
  static final GlobalKey<_MainScreenState> globalKey = GlobalKey<_MainScreenState>();
  static int get currentTabIndex => globalKey.currentState?._currentIndex ?? 0;
  static int? pendingStandingsTab;
  static void switchTab(int index, {int? subTab}) {
    pendingStandingsTab = subTab;
    // _onPageChanged esegue setState() dall'interno dello State (legale)
    globalKey.currentState?._onPageChanged(index);
  }
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  late AnimationController _fabAnimationController;
  late AnimationController _notificationAnimationController;

  FavoriteNotificationCoordinator? _favNotifCoordinator;

  // Pagine principali
  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(),
    const FavoritesScreen(),
    const StandingsScreen(),
  ];

  // Titoli pagine (localizzati nel build)
  List<String> _getTitles(BuildContext context) {
    final s = S.of(context)!;
    return ['SoccerPulse', s.calendar, s.favorites, s.standings];
  }

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

      // Coordinatore notifiche per le squadre preferite
      // TODO API: quando l-app sara collegata alle API, dopo
      // aver creato il LiveUpdateService chiamare
      //   liveUpdateService.startLiveUpdates(leagueId: 135);
      // per attivare il polling. Il coordinator qui sotto
      // ascolta goalStream e fara scattare i banner in
      // automatico per le squadre/partite preferite.
      _favNotifCoordinator = FavoriteNotificationCoordinator(
        liveUpdateService: liveUpdateService,
        matchNotifService:
            context.read<MatchNotificationPreferencesService>(),
        teamNotifService:
            context.read<TeamNotificationPreferencesService>(),
        onFavoriteGoal: ({
          required String homeTeam,
          required String awayTeam,
          required int homeScore,
          required int awayScore,
          required String scorer,
          required int minute,
          String? homeTeamLogo,
          String? awayTeamLogo,
        }) {
          LiveNotificationOverlay.globalKey.currentState
              ?.showGoalNotification(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: homeScore,
            awayScore: awayScore,
            scorer: scorer,
            minute: minute,
            homeTeamLogo: homeTeamLogo,
            awayTeamLogo: awayTeamLogo,
          );
        },
      );
      _favNotifCoordinator!.start();
    });
  }

  @override
  void dispose() {
    _favNotifCoordinator?.dispose();
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

    return LiveNotificationOverlay(
      key: LiveNotificationOverlay.globalKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitles(context)[_currentIndex]),
          actions: [
            // Icona ricerca
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _haptic.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                Navigator.pushNamed(context, '/settings');
              },
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        // [FAV-testbtn] pulsante TEMPORANEO per testare i banner
        floatingActionButton: FloatingActionButton(
          heroTag: 'fav_testbtn',
          mini: true,
          tooltip: 'Test notifiche',
          onPressed: _testNotifications,
          child: const Icon(Icons.notifications_active),
        ),
        body: Stack(
          children: [
            // Contenuto principale con PageView
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),

            // Quick Settings Panel (overlay)
            const QuickSettingsPanel(),

            // Debug button removed for production
          ],
        ),

        // Bottom Navigation
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              _haptic.lightImpact();
              setState(() {
                _currentIndex = index;
              });
              _onPageChanged(index);
            },
            items: [
              BottomNavigationBarItem(
                icon:
                    Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
                label: S.of(context)!.home,
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 1
                    ? Icons.calendar_today
                    : Icons.calendar_today_outlined),
                label: S.of(context)!.calendar,
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
                label: S.of(context)!.favorites,
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 3
                    ? Icons.leaderboard
                    : Icons.leaderboard_outlined),
                label: S.of(context)!.standings,
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

  // TODO API: rimuovere _testNotifications e il relativo FAB
  // "campanella" quando le notifiche scatteranno dal flusso
  // live reale. E codice solo di sviluppo.
  // Funzione di test per notifiche (SOLO PER DEVELOPMENT)
  // [FAV-testall] lancia in sequenza tutti gli 11 banner (3s di
  // distanza). Ogni banner si puo chiudere con tap o swipe.
  void _testNotifications() {
    _haptic.mediumImpact();

    void show(int seconds, void Function() action) {
      Future.delayed(Duration(seconds: seconds), () {
        final overlay = LiveNotificationOverlay.globalKey.currentState;
        if (overlay != null) action();
      });
    }

    // 0s - GOL
    show(0, () {
      LiveNotificationOverlay.globalKey.currentState?.showGoalNotification(
        homeTeam: 'Inter',
        awayTeam: 'Milan',
        homeScore: 1,
        awayScore: 0,
        scorer: 'Lautaro Martinez',
        minute: 23,
      );
    });

    // 3s - Cartellino Giallo
    show(3, () {
      LiveNotificationOverlay.globalKey.currentState?.showCardNotification(
        player: 'Theo Hernandez',
        team: 'Milan',
        cardType: CardType.yellow,
        minute: 25,
      );
    });

    // 6s - Cartellino Rosso
    show(6, () {
      LiveNotificationOverlay.globalKey.currentState?.showCardNotification(
        player: 'Rafael Leao',
        team: 'Milan',
        cardType: CardType.red,
        minute: 38,
      );
    });

    // 9s - Partita Iniziata
    show(9, () {
      LiveNotificationOverlay.globalKey.currentState
          ?.showMatchStartNotification(
        homeTeam: 'Juventus',
        awayTeam: 'Napoli',
        competition: 'Serie A',
      );
    });

    // 12s - Partita Terminata
    show(12, () {
      LiveNotificationOverlay.globalKey.currentState
          ?.showMatchEndNotification(
        homeTeam: 'Roma',
        awayTeam: 'Lazio',
        homeScore: 2,
        awayScore: 2,
      );
    });

    // 15s - Fallo
    show(15, () {
      // [FAV-testcount] nuova firma con conteggio
      LiveNotificationOverlay.globalKey.currentState?.showFoulNotification(
        homeTeam: 'Lazio',
        awayTeam: 'Milan',
        homeCount: 12,
        awayCount: 15,
        isHomeTeam: true,
        minute: 41,
      );
    });

    // 18s - Fuori gioco
    show(18, () {
      // [FAV-testoff] nuova firma con conteggio
      LiveNotificationOverlay.globalKey.currentState
          ?.showOffsideNotification(
        homeTeam: 'Lazio',
        awayTeam: 'Milan',
        homeCount: 2,
        awayCount: 3,
        isHomeTeam: false,
        minute: 44,
      );
    });

    // 21s - Calcio d'angolo
    show(21, () {
      // [FAV-testcount] nuova firma con conteggio
      LiveNotificationOverlay.globalKey.currentState
          ?.showCornerNotification(
        homeTeam: 'Lazio',
        awayTeam: 'Milan',
        homeCount: 4,
        awayCount: 6,
        isHomeTeam: false,
        minute: 47,
      );
    });

    // 24s - Rigore assegnato
    show(24, () {
      LiveNotificationOverlay.globalKey.currentState
          ?.showPenaltyNotification(
        team: 'Milan',
        minute: 52,
      );
    });

    // 27s - Sostituzione
    show(27, () {
      LiveNotificationOverlay.globalKey.currentState
          ?.showSubstitutionNotification(
        playerOut: 'Luis Alberto',
        playerIn: 'Matias Vecino',
        team: 'Lazio',
        minute: 60,
      );
    });

    // 30s - Revisione VAR
    show(30, () {
      LiveNotificationOverlay.globalKey.currentState?.showVarNotification(
        outcome: 'Gol annullato per fuorigioco',
        team: 'Milan',
        minute: 63,
      );
    });
  }

}


// ── Smooth fade + slide-up page transition ──
class SmoothPageRoute<T> extends MaterialPageRoute<T> {
  SmoothPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);
}

// ── Custom PageTransitionsBuilder for ThemeData ──
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}
