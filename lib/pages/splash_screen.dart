import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainNavigation(key: MainNavigation.globalKey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
              Theme.of(context).primaryColor.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animato
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '⚽',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .then(delay: 200.ms)
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),

              const SizedBox(height: 40),

              // App name
              const Text(
                'SoccerPulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 16),

              // Tagline
              const Text(
                'Il tuo calcio, sempre aggiornato',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(context, 'Caricamento...'),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
