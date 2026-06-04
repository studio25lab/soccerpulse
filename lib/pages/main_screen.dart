import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'home_screen.dart';
import 'standings_screen.dart';
import 'calendar_screen.dart';
import 'favorites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StandingsScreen(),
    CalendarScreen(),
    FavoritesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: tr(context, 'Classifica'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: tr(context, 'Calendario'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: tr(context, 'Preferiti'),
          ),
        ],
      ),
    );
  }
}
