// lib/widgets/quick_settings_panel.dart

import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/haptic_service.dart';

class QuickSettingsPanel extends StatefulWidget {
  const QuickSettingsPanel({Key? key}) : super(key: key);

  @override
  State<QuickSettingsPanel> createState() => _QuickSettingsPanelState();
}

class _QuickSettingsPanelState extends State<QuickSettingsPanel>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isExpanded = false;

  // Settings
  ThemeMode _selectedTheme = ThemeMode.system;
  String _selectedLanguage = 'it';
  bool _notificationsEnabled = true;
  bool _soundEnabled = false;
  bool _vibrationEnabled = true;
  int _refreshInterval = 30;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    _haptic.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // FAB Button
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton(
            onPressed: _togglePanel,
            backgroundColor: theme.primaryColor,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
            ),
          )
              .animate()
              .scale(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 300),
              )
              .fadeIn(),
        ),

        // Settings Panel
        if (_isExpanded)
          Positioned(
            right: 16,
            bottom: 150,
            child: SlideTransition(
              position: _slideAnimation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero),
              ),
              child: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tr(context, 'Impostazioni Rapide'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Theme Selector
                        _buildThemeSection(theme, isDark),

                        const Divider(height: 1),

                        // Language Selector
                        _buildLanguageSection(theme, isDark),

                        const Divider(height: 1),

                        // Notifications Settings
                        _buildNotificationsSection(theme, isDark),

                        const Divider(height: 1),

                        // Refresh Settings
                        _buildRefreshSection(theme, isDark),

                        const Divider(height: 1),

                        // Quick Actions
                        _buildQuickActions(theme, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 300),
                )
                .fadeIn(),
          ),
      ],
    );
  }

  Widget _buildThemeSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tema',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption(
                'Chiaro',
                Icons.light_mode,
                ThemeMode.light,
                theme,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                'Scuro',
                Icons.dark_mode,
                ThemeMode.dark,
                theme,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                'Auto',
                Icons.brightness_auto,
                ThemeMode.system,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
      String label, IconData icon, ThemeMode mode, ThemeData theme) {
    final isSelected = _selectedTheme == mode;

    return Expanded(
      child: InkWell(
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            _selectedTheme = mode;
          });
          // Applica il tema con Provider
          context.read<ThemeService>().setThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? theme.primaryColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? theme.primaryColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Lingua',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLanguageOption('it', 'Italiano', 'it', theme),
              const SizedBox(width: 8),
              _buildLanguageOption('gb', 'English', 'en', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
      String countryCode, String label, String code, ThemeData theme) {
    final isSelected = _selectedLanguage == code;

    return Expanded(
      child: InkWell(
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            _selectedLanguage = code;
          });
          // Cambia lingua
          if (code == 'it') {
            context.read<ThemeService>().setLocale(const Locale('it', 'IT'));
          } else if (code == 'en') {
            context.read<ThemeService>().setLocale(const Locale('en', 'US'));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              CountryFlag.fromCountryCode(countryCode,
                  theme: const ImageTheme(
                      height: 22, width: 32,
                      shape: RoundedRectangle(4))),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? theme.primaryColor : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'Notifiche'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            tr(context, 'Notifiche Goal'),
            Icons.sports_soccer,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildToggleOption(
            'Suoni',
            Icons.volume_up,
            _soundEnabled,
            (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          _buildToggleOption(
            'Vibrazione',
            Icons.vibration,
            _vibrationEnabled,
            (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String label, IconData icon, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (newValue) {
                _haptic.lightImpact();
                onChanged(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.refresh,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Aggiornamento Live',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Intervallo',
                style: TextStyle(fontSize: 13),
              ),
              Row(
                children: [
                  _buildIntervalOption(15, theme),
                  _buildIntervalOption(30, theme),
                  _buildIntervalOption(60, theme),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalOption(int seconds, ThemeData theme) {
    final isSelected = _refreshInterval == seconds;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            _refreshInterval = seconds;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${seconds}s',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Azioni Rapide',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  Icons.delete_sweep,
                  'Pulisci Cache',
                () {
                  _haptic.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'Cache pulita'))),
                  );
                },
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.sync,
                  'Sincronizza',
                () {
                  _haptic.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'Sincronizzazione avviata'))),
                  );
                },
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            Icons.bug_report,
            'Segnala Problema',
            () {
              _haptic.mediumImpact();
              // Apri form segnalazione
            },
            Colors.red,
          ),
        ],
      ),
    );
  }

  // [FAV-qsp-fix] ritorna InkWell nudo; l-Expanded lo mette il
  // chiamante, ma solo quando il bottone e dentro un Row.
  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
  }
}
