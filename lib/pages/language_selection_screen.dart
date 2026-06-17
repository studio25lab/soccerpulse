// lib/pages/language_selection_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;

  const LanguageSelectionScreen({
    Key? key,
    this.isInitialSetup = false,
  }) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  String? _selectedLanguage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _languages = [
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCurrentLanguage();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language_code') ?? 'it';
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    _haptic.mediumImpact();

    setState(() {
      _selectedLanguage = languageCode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    // Update app locale
    if (mounted) {
      // TODO: per cambio lingua live integrare con
      //   context.read<ThemeService>().setLocale(Locale(languageCode))
      // Per ora la lingua si applica al riavvio della schermata.

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'it'
                ? 'Lingua impostata su Italiano'
                : 'Language set to ${_getLanguageName(languageCode)}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate back or to main screen
      if (widget.isInitialSetup) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  String _getLanguageName(String code) {
    return _languages.firstWhere((lang) => lang['code'] == code)['name'] ??
        code;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title:
            Text(widget.isInitialSetup ? 'Choose Language' : tr(context, 'Cambia lingua')),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.language,
                        size: 80,
                        color: theme.primaryColor,
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(
                        widget.isInitialSetup
                            ? 'Select your preferred language'
                            : tr(context, 'Seleziona la tua lingua preferita'),
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Languages List
                Expanded(
                  child: ListView.builder(
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final language = _languages[index];
                      final isSelected = _selectedLanguage == language['code'];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: GlassmorphicCard(
                          child: InkWell(
                            onTap: () => _saveLanguage(language['code']!),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // Flag
                                  Text(
                                    language['flag']!,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 20),

                                  // Language name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          language['name']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          language['code']!.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Selection indicator
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ).animate().scale(
                                          duration: 300.ms,
                                          curve: Curves.elasticOut,
                                        )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey[400],
                                      size: 36,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 50),
                          )
                          .slideX(
                            begin: isSelected ? -0.02 : 0.02,
                            end: 0,
                            duration: 400.ms,
                          );
                    },
                  ),
                ),

                // Info text
                if (!widget.isInitialSetup)
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'La modifica sarà applicata immediatamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
