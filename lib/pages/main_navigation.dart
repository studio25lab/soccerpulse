// lib/pages/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/l10n.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'favorites_screen.dart';
import 'standings_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  final FavoritesService _favoritesService = FavoritesService();
  final ThemeService _themeService = ThemeService();

  late int _selectedIndex;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _bottomNavAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _bottomNavSlideAnimation;

  bool _isFabExpanded = false;
  DateTime? _lastBackPress;

  // Pages
  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(),
    const FavoritesScreen(),
    const StandingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _initAnimations();
    _checkFirstLaunch();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bottomNavSlideAnimation = CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeOutCubic,
    );

    _bottomNavAnimationController.forward();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch && mounted) {
      // Show onboarding or tutorial
      await prefs.setBool('first_launch', false);
      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Benvenuto in SoccerPulse! ⚽',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_soccer,
              size: 80,
              color: Colors.green,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text(
              'Segui le tue squadre preferite, ricevi aggiornamenti in tempo reale e non perdere mai una partita!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showQuickTour();
            },
            child: const Text('Tour Rapido'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Inizia'),
          ),
        ],
      ),
    );
  }

  void _showQuickTour() {
    // Show tooltips or overlays for main features
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Swipe tra le pagine o usa la barra in basso'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    _haptic.lightImpact();
    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleFab() {
    _haptic.mediumImpact();
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });

    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_selectedIndex != 0) {
      // Go back to home
      _onItemTapped(0);
      return false;
    }

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premi di nuovo per uscire'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _pages,
            ),

            // FAB Menu Overlay
            if (_isFabExpanded)
              GestureDetector(
                onTap: _toggleFab,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        ),

        // Bottom Navigation Bar
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_bottomNavSlideAnimation),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              indicatorColor: theme.primaryColor.withOpacity(0.1),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: theme.primaryColor),
                  label: s.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon:
                      Icon(Icons.calendar_today, color: theme.primaryColor),
                  label: s.calendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite, color: theme.primaryColor),
                  label: s.favorites,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.leaderboard_outlined),
                  selectedIcon:
                      Icon(Icons.leaderboard, color: theme.primaryColor),
                  label: s.standings,
                ),
              ],
            ),
          ),
        ),

        // Floating Action Button
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expanded menu items
            if (_isFabExpanded) ...[
              _buildFabMenuItem(
                icon: Icons.search,
                label: 'Cerca',
                onTap: () {
                  _toggleFab();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                heroTag: 'search',
                index: 0,
              ),
              const SizedBox(height: 12),
              _buildFabMenuItem(
                icon: Icons.notifications,
                label: 'Notifiche',
                onTap: () {
                  _toggleFab();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                heroTag: 'notifications',
                index: 1,
              ),
              const SizedBox(height: 12),
              _buildFabMenuItem(
                icon: Icons.settings,
                label: 'Impostazioni',
                onTap: () {
                  _toggleFab();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                heroTag: 'settings',
                index: 2,
              ),
              const SizedBox(height: 12),
            ],

            // Main FAB
            FloatingActionButton(
              onPressed: _toggleFab,
              backgroundColor: theme.primaryColor,
              elevation: 8,
              heroTag: 'main_fab',
              child: AnimatedRotation(
                turns: _isFabExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isFabExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
              ),
            ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required String heroTag,
    required int index,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.2, end: 0),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: Theme.of(context).primaryColor,
          heroTag: heroTag,
          child: Icon(icon, color: Colors.white),
        ).animate().scale(
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }
}

// Extension for smooth page navigation
extension PageControllerExtension on PageController {
  Future<void> animateToPageWithCurve(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    return animateToPage(
      page,
      duration: duration,
      curve: curve,
    );
  }
}
