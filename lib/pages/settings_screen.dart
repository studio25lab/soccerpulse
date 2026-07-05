// lib/pages/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/favorites_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HapticService _haptic = HapticService();

  bool _matchNotifications = true;
  bool _goalNotifications = true;
  bool _newsNotifications = false;
  bool _autoRefresh = true;
  int _refreshInterval = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;
    final themeService = context.watch<ThemeService>();
    final favoritesService = context.watch<FavoritesService>();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(s.settings),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(s.appearance, Icons.palette),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassmorphicCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: theme.primaryColor,
                      ),
                      title: Text(s.theme),
                      subtitle: Text(
                        themeService.getThemeModeString(),
                        style: TextStyle(color: theme.primaryColor),
                      ),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (value) {
                          _haptic.lightImpact();
                          themeService.toggleTheme(context);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.language,
                        color: theme.primaryColor,
                      ),
                      title: Text(s.language),
                      subtitle: Text(themeService.getLocaleString()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.lightImpact();
                        _showLanguageDialog(context, themeService, s);
                      },
                    ),
                  ],
                ),
              ),
            ).animate().slideX(begin: -0.1, end: 0).fadeIn(),
            _buildSectionHeader(s.notifications, Icons.notifications),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassmorphicCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.sports_soccer),
                      title: Text(s.matchNotifications),
                      subtitle: Text(s.matchNotificationsDesc),
                      value: _matchNotifications,
                      onChanged: (value) {
                        _haptic.lightImpact();
                        setState(() {
                          _matchNotifications = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.flag),
                      title: Text(s.liveNotifications),
                      subtitle: Text(s.liveNotificationsDesc),
                      value: _goalNotifications,
                      onChanged: (value) {
                        _haptic.lightImpact();
                        setState(() {
                          _goalNotifications = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.newspaper),
                      title: Text(s.favoriteNotifications),
                      subtitle: Text(s.favoriteNotificationsDesc),
                      value: _newsNotifications,
                      onChanged: (value) {
                        _haptic.lightImpact();
                        setState(() {
                          _newsNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideX(
                    begin: 0.1,
                    end: 0,
                    delay: const Duration(milliseconds: 100))
                .fadeIn(),
            _buildSectionHeader(s.data, Icons.sync),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassmorphicCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.refresh),
                      title: Text(s.autoRefresh),
                      subtitle: Text(s.autoRefreshDesc),
                      value: _autoRefresh,
                      onChanged: (value) {
                        _haptic.lightImpact();
                        setState(() {
                          _autoRefresh = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: Text(s.refreshInterval),
                      subtitle:
                          Text('$_refreshInterval ${s.refreshIntervalDesc}'),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: _autoRefresh,
                      onTap: _autoRefresh
                          ? () {
                              _haptic.lightImpact();
                              _showRefreshIntervalDialog(context, s);
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.delete_sweep, color: Colors.orange[700]),
                      title: Text(s.clearCache),
                      subtitle: Text(s.clearCacheDesc),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.mediumImpact();
                        _showClearCacheDialog(context, s);
                      },
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideX(
                    begin: -0.1,
                    end: 0,
                    delay: const Duration(milliseconds: 200))
                .fadeIn(),
            _buildSectionHeader(s.favorites, Icons.favorite),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassmorphicCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sports_soccer),
                      title: Text(s.myFavorites),
                      subtitle: Text(
                          '${favoritesService.favoriteTeamIds.length} ${s.teams}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.lightImpact();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(s.players),
                      subtitle: Text(
                          '${favoritesService.favoritePlayerIds.length} ${s.players.toLowerCase()}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.lightImpact();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.delete_forever, color: Colors.red[700]),
                      title: Text(s.removeAllFavorites),
                      subtitle: Text(s.removeAllFavoritesDesc),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.heavyImpact();
                        _showClearFavoritesDialog(context, favoritesService, s);
                      },
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideX(
                    begin: 0.1,
                    end: 0,
                    delay: const Duration(milliseconds: 300))
                .fadeIn(),
            _buildSectionHeader(s.about, Icons.info),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassmorphicCard(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.info_outline, color: theme.primaryColor),
                      title: Text(s.appVersion),
                      subtitle: Text(s.appTitle),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s.beta,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        _haptic.lightImpact();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        _haptic.lightImpact();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: Text(s.reportBug),
                      subtitle: Text(s.reportBugEmail),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _haptic.lightImpact();
                      },
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideX(
                    begin: -0.1,
                    end: 0,
                    delay: const Duration(milliseconds: 400))
                .fadeIn(),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: theme.primaryColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.appTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.madeWithLove,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.copyright,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(delay: const Duration(milliseconds: 500))
                .fadeIn(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, ThemeService themeService, S s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CountryFlag.fromLanguageCode('it',
                  theme: const ImageTheme(
                      height: 22, width: 32,
                      shape: RoundedRectangle(4))),
              title: const Text('Italiano'),
              onTap: () {
                themeService.setLocale(const Locale('it', 'IT'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CountryFlag.fromCountryCode('GB',
                  theme: const ImageTheme(
                      height: 22, width: 32,
                      shape: RoundedRectangle(4))),
              title: const Text('English'),
              onTap: () {
                themeService.setLocale(const Locale('en', 'US'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _refreshLabel(int seconds) {
    switch (seconds) {
      case 15: return 'Ogni 15 secondi (più veloce)';
      case 30: return 'Ogni 30 secondi (consigliato)';
      case 60: return 'Ogni minuto';
      case 120: return 'Ogni 2 minuti (risparmia batteria)';
      default: return 'Ogni $seconds secondi';
    }
  }

  void _showRefreshIntervalDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.refreshInterval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 60, 120].map((seconds) {
            return ListTile(
              title: Text(_refreshLabel(seconds)),
              leading: Radio<int>(
                value: seconds,
                groupValue: _refreshInterval,
                onChanged: (value) {
                  setState(() {
                    _refreshInterval = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.clearCache),
        content: Text(s.clearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.clearCacheSuccess)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(s.clearCache),
          ),
        ],
      ),
    );
  }

  void _showClearFavoritesDialog(
      BuildContext context, FavoritesService favoritesService, S s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removeAllFavorites),
        content: Text(s.removeAllFavoritesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              favoritesService.clearAllFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.removeAllFavoritesSuccess)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(s.deleteAll),
          ),
        ],
      ),
    );
  }
}
