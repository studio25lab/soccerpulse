// lib/pages/match_player_profile_screen.dart
//
// Schermata profilo giocatore aperta dal contesto di una partita.
// Mostra stats live del match, stagione, skills, carriera.
// Estratta da match_detail_screen.dart (era PlayerProfileScreen interna,
// rinominata MatchPlayerProfileScreen per evitare collisione con
// la PlayerProfileScreen di lib/pages/player_profile_screen.dart).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soccerpulse/models/local_match_models.dart';
import '../utils/l10n_helper.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../models/player_notification_settings.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../services/player_notification_preferences_service.dart';
import 'match_detail_screen.dart';
import '../utils/mock_player_profile_data.dart';
import 'match_player_profile_internals.dart';

class MatchPlayerProfileScreen extends StatefulWidget {
  final LocalLineupPlayer player;
  final String teamName;
  final Color teamColor;

  const MatchPlayerProfileScreen({
    super.key,
    required this.player,
    required this.teamName,
    required this.teamColor,
  });

  @override
  State<MatchPlayerProfileScreen> createState() => _MatchPlayerProfileScreenState();
}

class _MatchPlayerProfileScreenState extends State<MatchPlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get isCoach => widget.player.position == 'ALL';
  int get _tabCount => isCoach ? 3 : 4;
  final HapticService _playerHaptic = HapticService();

  // ── Player Notification Service ──
  final PlayerNotificationPreferencesService _playerNotifService =
      PlayerNotificationPreferencesService();
  late PlayerNotificationSettings _playerNotifSettings;
  Map<String, bool> get _playerNotifPrefs => _playerNotifSettingsToMap();
  bool get _playerNotifEnabled => _playerNotifSettings.hasActiveNotifications;

  Map<String, bool> _playerNotifSettingsToMap() {
    return {
      'goals': _playerNotifSettings.notifyGoals,
      'yellowCards': _playerNotifSettings.notifyYellowCard,
      'redCards': _playerNotifSettings.notifyRedCard,
      'foulsCommitted': _playerNotifSettings.notifyFoulCommitted,
      'foulsSuffered': _playerNotifSettings.notifyFoulSuffered,
      'shots': _playerNotifSettings.notifyShotsOffTarget,
      'shotsOnTarget': _playerNotifSettings.notifyShotsOnTarget,
      'offsides': _playerNotifSettings.notifyOffsides,
      'fantaRatingHT': _playerNotifSettings.notifyKeyPasses,
      'fantaRatingFT': _playerNotifSettings.notifyDribblesSuccessful,
    };
  }

  void _updatePlayerNotifFromKey(String key, bool value) {
    switch (key) {
      case 'goals':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyGoals: value);
        break;
      case 'yellowCards':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyYellowCard: value);
        break;
      case 'redCards':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyRedCard: value);
        break;
      case 'foulsCommitted':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyFoulCommitted: value);
        break;
      case 'foulsSuffered':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyFoulSuffered: value);
        break;
      case 'shots':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyShotsOffTarget: value);
        break;
      case 'shotsOnTarget':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyShotsOnTarget: value);
        break;
      case 'offsides':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyOffsides: value);
        break;
      case 'fantaRatingHT':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyKeyPasses: value);
        break;
      case 'fantaRatingFT':
        _playerNotifSettings = _playerNotifSettings.copyWith(notifyDribblesSuccessful: value);
        break;
    }
    _playerNotifService.saveSettingsForPlayer(_playerNotifSettings);
  }

  void _setAllPlayerNotif(bool value) {
    _playerNotifSettings = _playerNotifSettings.copyWith(
      notifyGoals: value,
      notifyYellowCard: value,
      notifyRedCard: value,
      notifyFoulCommitted: value,
      notifyFoulSuffered: value,
      notifyShotsOnTarget: value,
      notifyShotsOffTarget: value,
      notifyOffsides: value,
      notifyKeyPasses: value,
      notifyDribblesSuccessful: value,
    );
    _playerNotifService.saveSettingsForPlayer(_playerNotifSettings);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    // Carica impostazioni notifiche giocatore dal service
    _playerNotifSettings = _playerNotifService.getSettingsForPlayer(
      widget.player.number,
      widget.player.name,
    );
    _playerNotifService.loadSettings().then((_) {
      if (mounted) {
        setState(() {
          _playerNotifSettings = _playerNotifService.getSettingsForPlayer(
            widget.player.number,
            widget.player.name,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Player Notification Settings Bottom Sheet ──
  void _showPlayerNotificationDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.player;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allOn = _playerNotifPrefs.values.every((v) => v);
            final anyOn = _playerNotifPrefs.values.any((v) => v);
            final activeCount =
                _playerNotifPrefs.values.where((v) => v).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with player info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        // Player number
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: widget.teamColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.teamColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${p.number}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: widget.teamColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifiche ${p.name} (Stagione)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                anyOn
                                    ? '$activeCount/${_playerNotifPrefs.length} attive'
                                    : tr(context, 'Nessuna notifica attiva'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle all
                        GestureDetector(
                          onTap: () {
                            _playerHaptic.lightImpact();
                            final newVal = !allOn;
                            setSheetState(() {
                              _setAllPlayerNotif(newVal);
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: allOn
                                  ? widget.teamColor
                                  : isDark
                                      ? Colors.white10
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: allOn
                                    ? widget.teamColor
                                    : isDark
                                        ? Colors.white24
                                        : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              allOn ? S.of(context)!.deactivate : S.of(context)!.activateAll,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: allOn
                                    ? Colors.white
                                    : isDark
                                        ? Colors.white70
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                      color: isDark ? Colors.white12 : Colors.grey[200],
                      height: 1),

                  // Scrollable tiles
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── AZIONI OFFENSIVE ──
                          _pNotifSection(tr(context, 'Azioni offensive'),
                              Icons.sports_soccer, isDark),
                          _pNotifTile(
                            key: 'goals',
                            icon: Icons.sports_soccer,
                            title: 'Goal',
                            subtitle:
                                'Notifica quando ${p.name} segna un goal',
                            color: const Color(0xFF4CAF50),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'shots',
                            icon: Icons.gps_not_fixed,
                            title: localizeShotData(context, 'Tiri totali'),
                            subtitle: localizeShotData(context, 'Tutti i tentativi verso la porta'),
                            color: const Color(0xFF42A5F5),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'shotsOnTarget',
                            icon: Icons.gps_fixed,
                            title: localizeShotData(context, 'Tiri in porta'),
                            subtitle: 'Tiri nello specchio della porta',
                            color: const Color(0xFF2196F3),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'offsides',
                            icon: Icons.front_hand,
                            title: tr(context, 'Fuorigioco'),
                            subtitle: 'Quando viene segnalato in offside',
                            color: const Color(0xFF7E57C2),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),

                          const SizedBox(height: 16),

                          // ── DISCIPLINA ──
                          _pNotifSection(S.of(context)!.disciplinaLabel, Icons.style, isDark),
                          _pNotifTile(
                            key: 'yellowCards',
                            icon: Icons.square_rounded,
                            title: 'Cartellino giallo',
                            subtitle: 'Ammonizioni e doppi gialli',
                            color: const Color(0xFFFFCA28),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'redCards',
                            icon: Icons.square_rounded,
                            title: 'Cartellino rosso',
                            subtitle: 'Espulsioni dirette o per doppio giallo',
                            color: const Color(0xFFE53935),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'foulsCommitted',
                            icon: Icons.warning_amber,
                            title: tr(context, 'Falli commessi'),
                            subtitle: 'Falli fatti dal giocatore',
                            color: const Color(0xFFFF7043),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'foulsSuffered',
                            icon: Icons.personal_injury,
                            title: tr(context, 'Falli subiti'),
                            subtitle: 'Falli subiti dal giocatore',
                            color: const Color(0xFF8D6E63),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),

                          const SizedBox(height: 16),

                          // ── FANTACALCIO ──
                          _pNotifSection(
                              'Fantacalcio', Icons.star_rate, isDark),
                          _pNotifTile(
                            key: 'fantaRatingHT',
                            icon: Icons.star_half,
                            title: 'Voto fine 1° tempo',
                            subtitle:
                                'Voto parziale fantacalcio all\'intervallo',
                            color: const Color(0xFFAB47BC),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                          _pNotifTile(
                            key: 'fantaRatingFT',
                            icon: Icons.star,
                            title: 'Voto finale',
                            subtitle:
                                'Voto definitivo fantacalcio a fine partita',
                            color: const Color(0xFF9C27B0),
                            isDark: isDark,
                            setSheetState: setSheetState,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pNotifSection(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Icon(icon,
            size: 16,
            color: isDark ? Colors.white38 : Colors.grey[500]),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? Colors.white38 : Colors.grey[500],
            )),
      ]),
    );
  }

  Widget _pNotifTile({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required StateSetter setSheetState,
  }) {
    final isOn = _playerNotifPrefs[key] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _playerHaptic.lightImpact();
            setSheetState(() {
              _updatePlayerNotifFromKey(key, !isOn);
            });
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isOn
                  ? color.withValues(alpha: isDark ? 0.12 : 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOn
                    ? color.withValues(alpha: isDark ? 0.3 : 0.2)
                    : isDark
                        ? Colors.white10
                        : Colors.grey[200]!,
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isOn ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isOn
                        ? color
                        : isDark
                            ? Colors.white30
                            : Colors.grey[400]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOn
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                  ? Colors.white54
                                  : Colors.grey[500]),
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white30 : Colors.grey[400],
                        )),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: isOn
                      ? color
                      : isDark
                          ? Colors.white12
                          : Colors.grey[300],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment:
                      isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

    // ── Dati reali giocatori stagione 2022-23 ──
  Map<String, dynamic> _getSeasonData() {
    final p = widget.player;
    final data = getMockPlayerData(p.name);
    if (data != null) return data;
    // Fallback generico per giocatori non mappati
    return {
      'appearances': 15 + (p.number % 10),
      'goals': 0,
      'assists': 0,
      'yellowCards': p.yellowCards > 0 ? p.yellowCards : (p.number % 3),
      'redCards': 0,
      'avgRating': p.rating > 0 ? p.rating : 6.5,
      'minutesPlayed': (15 + (p.number % 10)) * 75,
      'recentRatings': [6.5, 6.8, 6.2, 7.0, 6.4],
      'recentForm': ['D', 'W', 'L', 'W', 'D'],
      'skills': {'VEL': 65.0, 'TIR': 65.0, 'PAS': 65.0, 'DRI': 65.0, 'DIF': 65.0, 'FIS': 65.0},
      'birthDate': '01/01/1995',
      'age': 28,
      'nationality': '🏳️ N/D',
      'height': 180,
      'weight': 75,
      'foot': 'Destro',
      'career': [{'team': widget.teamName, 'years': '2022 - Presente', 'apps': '${15 + (p.number % 10)}', 'goals': '0'}],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final divider = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final data = _getSeasonData();
    final p = widget.player;

    Color ratingBg;
    final avg = (data['avgRating'] as double);
    if (avg >= 7.5) {
      ratingBg = const Color(0xFF1B5E20);
    } else if (avg >= 7.0)
      ratingBg = const Color(0xFF388E3C);
    else if (avg >= 6.5)
      ratingBg = const Color(0xFFF9A825);
    else
      ratingBg = const Color(0xFFEF6C00);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        // ═══ SLIVER APP BAR — Premium Style ═══
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF121212) : widget.teamColor,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, size: 22),
                tooltip: 'Home',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                },
              ),
            // Cuore preferiti
            StatefulBuilder(builder: (ctx, setSheetState) {
              final favService = ctx.read<FavoritesService>();
              final playerId = widget.player.name.hashCode.abs();
              final isFav = favService.isPlayerFavorite(playerId);
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isFav ? Colors.red.withValues(alpha: 0.3) : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: Colors.white, size: 18,
                  ),
                ),
                onPressed: () {
                  _playerHaptic.lightImpact();
                  setState(() {
                    favService.togglePlayerFavorite(playerId);
                    if (!isFav) {
                      final seasonData2 = getPlayerSeasonData(widget.player.name);
                      favService.storePlayerMeta(playerId, {
                        'name': widget.player.name,
                        'position': widget.player.position,
                        'number': widget.player.number,
                        'rating': seasonData2?['avgRating'] ?? widget.player.rating,
                        'goals': seasonData2?['goals'] ?? 0,
                        'assists': seasonData2?['assists'] ?? 0,
                        'appearances': seasonData2?['appearances'] ?? 0,
                        'yellowCards': seasonData2?['yellowCards'] ?? 0,
                        'redCards': seasonData2?['redCards'] ?? 0,
                        'nationality': seasonData2?['nationality'] ?? '',
                        'age': seasonData2?['age'] ?? 0,
                        'team': widget.teamName,
                      });
                    }
                  });
                },
              );
            }),
            // Campanella notifiche
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _playerNotifEnabled
                      ? widget.teamColor.withValues(alpha: 0.3)
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _playerNotifEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: _showPlayerNotificationDialog,
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.teamColor.withValues(alpha: 0.9),
                    widget.teamColor.withValues(alpha: 0.6),
                    bg,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Player number in rounded square
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(
                        child: isCoach
                          ? const Icon(Icons.assignment_ind_rounded, size: 42, color: Colors.white)
                          : Text('${p.number}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Name
                    Text(p.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    // Team name
                    Text(widget.teamName,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 10),
                    // Info chips + rating
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (isCoach) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(tr(context, 'Allenatore'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      if (!isCoach) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(p.position,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      if (!isCoach) const SizedBox(width: 8),
                      // Rating badge with glow
                      if (!isCoach) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: ratingBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: ratingBg.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(avg.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ═══ TAB BAR ═══
        SliverPersistentHeader(
          pinned: true,
          delegate: MPPStickyTabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: isDark && widget.teamColor.computeLuminance() < 0.3
                  ? Color.lerp(widget.teamColor, Colors.white, 0.5)!
                  : widget.teamColor,
              unselectedLabelColor: lb,
              indicatorColor: isDark && widget.teamColor.computeLuminance() < 0.3
                  ? Color.lerp(widget.teamColor, Colors.white, 0.5)!
                  : widget.teamColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: localizeShotData(context, 'Stagione')),
                Tab(text: localizeShotData(context, 'Carriera')),
                Tab(text: localizeShotData(context, 'Partite')),
                if (!isCoach) const Tab(text: 'Overall FC26'),
              ],
            ),
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),
          ),
        ),

        // ═══ TAB CONTENT ═══
        SliverFillRemaining(
          child: TabBarView(controller: _tabController, children: [
            // ── TAB 1: STAGIONE ──
            _buildSeasonTab(data, p, tx, lb, cardBg, divider, isDark),
            // ── TAB 2: CARRIERA ──
            _buildCareerTab(data, tx, lb, cardBg, divider, isDark),
            // ── TAB 3: PARTITE ──
            _buildMatchesTab(data, p, tx, lb, cardBg, divider, isDark),
            // ── TAB 4: OVERALL FC26 ──
            if (!isCoach) _buildSkillsTab(data, tx, lb, cardBg, isDark),

          ]),
        ),
      ]),
    );
  }

  // ── SEASON TAB ──
  Widget _buildSeasonTab(Map<String, dynamic> data, LocalLineupPlayer p,
      Color tx, Color lb, Color cardBg, Color divider, bool isDark) {
    final isGK = p.position == 'GK';
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Key stats grid
      _sectionTitle(isCoach ? tr(context, 'Riepilogo Stagione') : S.of(context)!.statisticheStagione, tx),
      const SizedBox(height: 10),
      if (isCoach) ...[
        Row(children: [
          _statBoxIcon(Icons.sports, tr(context, 'Panchine'), '36', const Color(0xFF7E57C2), cardBg, tx, lb),
          const SizedBox(width: 10),
          _statBoxIcon(Icons.emoji_events, tr(context, 'Vittorie'), '18', const Color(0xFF4CAF50), cardBg, tx, lb),
          const SizedBox(width: 10),
          _statBoxIcon(Icons.handshake, tr(context, 'Pareggi'), '10', const Color(0xFFF9A825), cardBg, tx, lb),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statBoxIcon(Icons.cancel_outlined, tr(context, 'Sconfitte'), '8', const Color(0xFFD32F2F), cardBg, tx, lb),
          const SizedBox(width: 10),
          _statBoxIcon(Icons.sports_soccer, tr(context, 'GF/GS'), '52/30', const Color(0xFF2196F3), cardBg, tx, lb),
          const SizedBox(width: 10),
          _statBoxIcon(Icons.trending_up, tr(context, 'Media Pt'), '1.78', const Color(0xFF2E7D32), cardBg, tx, lb),
        ]),
      ] else ...[
      Row(children: [
        _statBoxIcon(Icons.calendar_today_rounded, localizeShotData(context, 'Pres.'), '${data['appearances']}', const Color(0xFF7E57C2), cardBg, tx, lb),
        const SizedBox(width: 10),
        _statBoxIcon(Icons.sports_soccer, 'Goal', '${data['goals']}', const Color(0xFF4CAF50), cardBg, tx, lb),
        const SizedBox(width: 10),
        _statBoxIcon(Icons.assistant_rounded, 'Assist', '${data['assists']}', const Color(0xFF2196F3), cardBg, tx, lb),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statBoxIcon(Icons.timer_outlined, S.of(context)!.minuti, '${data['minutesPlayed']}', const Color(0xFF26A69A), cardBg, tx, lb),
        const SizedBox(width: 10),
        _statBoxIcon(Icons.square_rounded, localizeShotData(context, 'Cart.'), '${data['yellowCards']}', const Color(0xFFF9A825), cardBg, tx, lb),
        const SizedBox(width: 10),
        _statBoxIcon(Icons.star_rounded, localizeShotData(context, 'Media'), (data['avgRating'] as double).toStringAsFixed(1), const Color(0xFF2E7D32), cardBg, tx, lb),
      ]),
      ],

      const SizedBox(height: 24),

      // Recent form
      _sectionTitle(localizeShotData(context, isCoach ? 'Ultimi 5 risultati' : tr(context, 'Ultime 5 partite')), tx),
      const SizedBox(height: 10),
      if (isCoach) Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: divider)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final r in [
            {'opp': 'Milan', 'score': '2-1', 'res': 'W', 'home': true},
            {'opp': 'Napoli', 'score': '0-0', 'res': 'D', 'home': false},
            {'opp': 'Lazio', 'score': '3-1', 'res': 'W', 'home': true},
            {'opp': 'Inter', 'score': '1-2', 'res': 'L', 'home': false},
            {'opp': 'Roma', 'score': '2-0', 'res': 'W', 'home': true},
          ])
            GestureDetector(
              onTap: () {
                final hName = (r['home'] as bool) ? widget.teamName : r['opp'] as String;
                final aName = (r['home'] as bool) ? r['opp'] as String : widget.teamName;
                final scores = (r['score'] as String).split('-');
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchDetailScreen(
                  match: SoccerMatch(id: r.hashCode, date: DateTime.now(), time: '20:45', status: 'FT',
                    venue: '', homeTeamId: 0, awayTeamId: 0, homeTeamName: hName, awayTeamName: aName,
                    homeScore: int.parse(scores[0]), awayScore: int.parse(scores[1]),
                    leagueName: 'Serie A', season: 2023, round: ''),
                )));
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon((r['home'] as bool) ? Icons.home_rounded : Icons.flight_rounded, size: 13, color: lb),
                const SizedBox(height: 3),
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: r['res'] == 'W' ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                        : r['res'] == 'D' ? const Color(0xFFF9A825).withValues(alpha: 0.15)
                        : const Color(0xFFD32F2F).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: r['res'] == 'W' ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                        : r['res'] == 'D' ? const Color(0xFFF9A825).withValues(alpha: 0.4)
                        : const Color(0xFFD32F2F).withValues(alpha: 0.4))),
                  child: Center(child: Text(r['score'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: r['res'] == 'W' ? const Color(0xFF2E7D32) : r['res'] == 'D' ? const Color(0xFFF9A825) : const Color(0xFFD32F2F))))),
                const SizedBox(height: 3),
                Text(r['opp'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: tx)),
              ]),
            ),
        ]),
      ) else Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: divider)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (int i = 0; i < 5; i++)
            Column(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (data['recentForm'] as List)[i] == 'W' ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                      : (data['recentForm'] as List)[i] == 'D' ? const Color(0xFFF9A825).withValues(alpha: 0.15)
                      : const Color(0xFFD32F2F).withValues(alpha: 0.15),
                  shape: BoxShape.circle),
                child: Center(child: Text((data['recentRatings'] as List)[i].toStringAsFixed(1),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: (data['recentForm'] as List)[i] == 'W' ? const Color(0xFF2E7D32)
                        : (data['recentForm'] as List)[i] == 'D' ? const Color(0xFFF9A825) : const Color(0xFFD32F2F))))),
              const SizedBox(height: 4),
              Text('G${i + 1}', style: TextStyle(fontSize: 10, color: lb)),
            ]),
        ]),
      ),

      const SizedBox(height: 24),

      // Detailed stats list
      _sectionTitle(localizeShotData(context, isCoach ? 'Riepilogo allenatore' : tr(context, 'Dettaglio statistiche')), tx),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: divider)),
        child: Column(children: [
          if (isCoach) ...[
            _profileStatRow(tr(context, 'Panchine totali'), '36', tx, lb, divider),
            _profileStatRow(tr(context, 'Vittorie'), '18', tx, lb, divider, valueColor: const Color(0xFF2E7D32)),
            _profileStatRow(tr(context, 'Pareggi'), '10', tx, lb, divider, valueColor: const Color(0xFFF9A825)),
            _profileStatRow(tr(context, 'Sconfitte'), '8', tx, lb, divider, valueColor: const Color(0xFFD32F2F)),
            _profileStatRow(tr(context, '% Vittorie'), '50%', tx, lb, divider),
            _profileStatRow(tr(context, 'Gol fatti'), '52', tx, lb, divider),
            _profileStatRow(tr(context, 'Gol subiti'), '30', tx, lb, divider),
            _profileStatRow(tr(context, 'Diff. reti'), '+22', tx, lb, divider, valueColor: const Color(0xFF2E7D32)),
            _profileStatRow(tr(context, 'Media punti'), '1.78', tx, lb, Colors.transparent),
          ] else ...[
            _profileStatRow(
                tr(context, 'Presenze (Titolare)'),
                '${data['appearances']} (${(data['appearances'] as int) - 4})',
                tx, lb, divider),
            _profileStatRow(
                S.of(context)!.minutesPlayedLabel, '${data['minutesPlayed']}', tx, lb, divider),
            _profileStatRow(S.of(context)!.gol, '${data['goals']}', tx, lb, divider),
            _profileStatRow(tr(context, 'Assist'), '${data['assists']}', tx, lb, divider),
          if (!isGK)
            _profileStatRow(
                S.of(context)!.mediaVoto,
                (data['avgRating'] as double).toStringAsFixed(2),
                tx,
                lb,
                divider),
          _profileStatRow(
              S.of(context)!.ammonizioni, '${data['yellowCards']}', tx, lb, divider,
              valueColor: const Color(0xFFF9A825)),
          if ((data['redCards'] as int) > 0)
            _profileStatRow(
                'Espulsioni', '${data['redCards']}', tx, lb, divider,
                valueColor: const Color(0xFFD32F2F)),
          if (!isGK)
            _profileStatRow(
                'Min/Gol',
                (data['goals'] as int) > 0
                    ? '${((data['minutesPlayed'] as int) / (data['goals'] as int)).round()}\''
                    : '-',
                tx,
                lb,
                divider),
          _profileStatRow(
              'Min/Assist',
              (data['assists'] as int) > 0
                  ? '${((data['minutesPlayed'] as int) / (data['assists'] as int)).round()}\''
                  : '-',
              tx,
              lb,
              Colors.transparent),
          ],
        ]),
      ),
    ]);
  }

  // ── SKILLS TAB (FC26 REDESIGN) ──
  // ── MATCHES TAB (Partite) ──
  bool _showAllMatches = false;

  Widget _buildMatchesTab(Map<String, dynamic> data, LocalLineupPlayer p,
      Color tx, Color lb, Color cardBg, Color divider, bool isDark) {
    final allMatches = _getPlayerRecentMatches(p);
    final matches = _showAllMatches ? allMatches : allMatches.take(5).toList();
    final hasMore = allMatches.length > 5 && !_showAllMatches;
    final teamColor = widget.teamColor;

    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionTitle(tr(context, isCoach ? 'Ultime Partite (Allenatore)' : 'Ultime Partite'), tx),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            ...matches.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final isLast = i == matches.length - 1 && !hasMore;
              final isUpcoming = m['status'] == 'upcoming';
              final rating = m['rating'] as double;
              final events = m['events'] as List<Map<String, dynamic>>;

              Color ratingColor;
              if (rating >= 7.5) {
                ratingColor = const Color(0xFF1B5E20);
              } else if (rating >= 7.0) ratingColor = const Color(0xFF388E3C);
              else if (rating >= 6.5) ratingColor = const Color(0xFFF9A825);
              else if (rating >= 6.0) ratingColor = const Color(0xFFEF6C00);
              else ratingColor = const Color(0xFFD32F2F);
              // For coaches, determine match result
              final isTeamHome = m['homeTeam'] == widget.teamName;
              final teamScore = isTeamHome ? (m['homeScore'] as int) : (m['awayScore'] as int);
              final oppScore = isTeamHome ? (m['awayScore'] as int) : (m['homeScore'] as int);
              final coachWon = !isUpcoming && teamScore > oppScore;
              final coachDraw = !isUpcoming && teamScore == oppScore;

              return GestureDetector(
                onTap: isUpcoming ? null : () {
                  final demoMatch = SoccerMatch(
                    id: 1000 + i,
                    date: DateTime.now(),
                    time: isUpcoming ? m['time'] as String : '20:45',
                    status: 'FT',
                    venue: 'Stadio Olimpico',
                    homeTeamId: 0,
                    homeTeamName: m['homeTeam'] as String,
                    awayTeamId: 0,
                    awayTeamName: m['awayTeam'] as String,
                    homeScore: m['homeScore'] as int,
                    awayScore: m['awayScore'] as int,
                    leagueName: 'Serie A',
                    season: 2023,
                    round: 'Giornata ${27 - i}',
                  );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(match: demoMatch),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: divider)),
                  ),
                  child: Row(children: [
                    // ── Data + status ──
                    SizedBox(
                      width: 48,
                      child: Column(children: [
                        Text(m['date'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tx),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text(isUpcoming ? m['time'] as String : 'FINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isUpcoming ? teamColor : lb,
                            ),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    // Divider verticale
                    Container(
                      width: 1, height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: divider,
                    ),
                    // ── Teams (no score here) ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _matchTeamRow(m['homeTeam'] as String, m['homeTeam'] == widget.teamName,
                              null, tx, lb, isDark),
                          const SizedBox(height: 3),
                          _matchTeamRow(m['awayTeam'] as String, m['awayTeam'] == widget.teamName,
                              null, tx, lb, isDark),
                        ],
                      ),
                    ),
                    // ── Events column (fixed width, LEFT of score) ──
                    SizedBox(
                      width: 32,
                      child: events.isNotEmpty
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 2,
                              runSpacing: 2,
                              children: events.map((ev) {
                                if (ev['type'] == 'goal') {
                                  return Icon(Icons.sports_soccer, size: 13,
                                      color: isDark ? Colors.white70 : Colors.black87);
                                } else if (ev['type'] == 'assist') {
                                  return Container(
                                    width: 14, height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? Colors.white54 : Colors.grey[600]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('A',
                                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white54 : Colors.grey[600]),
                                      ),
                                    ),
                                  );
                                } else if (ev['type'] == 'yellowCard') {
                                  return Container(
                                    width: 9, height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDD835),
                                      borderRadius: BorderRadius.circular(1.5),
                                      boxShadow: [
                                        BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 3),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }).toList(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    // ── Score column ──
                    if (!isUpcoming)
                      SizedBox(
                        width: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m['homeScore']}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
                            const SizedBox(height: 3),
                            Text('${m['awayScore']}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
                          ],
                        ),
                      ),
                    // ── Rating ──
                    const SizedBox(width: 8),
                    if (isUpcoming)
                      SizedBox(
                        width: 36,
                        child: Center(child: Icon(Icons.star_outline_rounded, size: 20, color: lb)),
                      )
                    else if (isCoach)
                      Container(
                        width: 36, height: 28,
                        decoration: BoxDecoration(
                          color: coachWon ? const Color(0xFF2E7D32) : coachDraw ? const Color(0xFFF9A825) : const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(coachWon ? formInitial(context, 'W') : coachDraw ? formInitial(context, 'D') : formInitial(context, 'L'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 36, height: 28,
                        decoration: BoxDecoration(
                          color: ratingColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                  ]),
                ),
              );
            }),
            // ── Carica partite precedenti ──
            if (hasMore)
              GestureDetector(
                onTap: () {
                  setState(() { _showAllMatches = true; });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: divider)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.expand_more_rounded, size: 18, color: isDark && teamColor.computeLuminance() < 0.3 ? Color.lerp(teamColor, Colors.white, 0.5)! : teamColor),
                      const SizedBox(width: 6),
                      Text(tr(context, 'Carica partite precedenti'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark && teamColor.computeLuminance() < 0.3 ? Color.lerp(teamColor, Colors.white, 0.5)! : teamColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _matchTeamRow(String team, bool isOwnTeam, int? score, Color tx, Color lb, bool isDark) {
    final colors = _getTeamColors(team);
    return Row(children: [
      // Team logo con iniziali
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: colors[0].withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: colors[0].withValues(alpha: 0.3), width: 0.5),
        ),
        child: Center(
          child: Text(
            team.length > 3 ? team.substring(0, 3).toUpperCase() : team.toUpperCase(),
            style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: colors[0]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(team,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isOwnTeam ? FontWeight.w700 : FontWeight.w400,
            color: tx,
          ),
        ),
      ),
      if (score != null)
        SizedBox(
          width: 20,
          child: Text('$score',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx),
            textAlign: TextAlign.right,
          ),
        ),
    ]);
  }

  List<Color> _getTeamColors(String team) {
    const map = {
      'Lazio': [Color(0xFF87CEEB), Color(0xFFFFFFFF)],
      'Milan': [Color(0xFFD32F2F), Color(0xFF000000)],
      'Juventus': [Color(0xFF000000), Color(0xFFFFFFFF)],
      'Inter': [Color(0xFF0047AB), Color(0xFF000000)],
      'Roma': [Color(0xFFB71C1C), Color(0xFFFFA000)],
      'Napoli': [Color(0xFF1565C0), Color(0xFFFFFFFF)],
      'Atalanta': [Color(0xFF1A237E), Color(0xFF000000)],
      'Fiorentina': [Color(0xFF7B1FA2), Color(0xFFFFFFFF)],
      'Torino': [Color(0xFF8B0000), Color(0xFFFFFFFF)],
      'Bologna': [Color(0xFFB71C1C), Color(0xFF1565C0)],
      'Sassuolo': [Color(0xFF2E7D32), Color(0xFF000000)],
      'Monza': [Color(0xFFD32F2F), Color(0xFFFFFFFF)],
      'Udinese': [Color(0xFF212121), Color(0xFFFFFFFF)],
      'Lecce': [Color(0xFFF9A825), Color(0xFFD32F2F)],
      'Empoli': [Color(0xFF1565C0), Color(0xFFFFFFFF)],
      'Salernitana': [Color(0xFF8B0000), Color(0xFFFFFFFF)],
      'Cagliari': [Color(0xFFD32F2F), Color(0xFF1565C0)],
      'Genoa': [Color(0xFFD32F2F), Color(0xFF1565C0)],
      'Verona': [Color(0xFFF9A825), Color(0xFF1565C0)],
      'Frosinone': [Color(0xFFF9A825), Color(0xFF1565C0)],
    };
    return map[team] ?? [const Color(0xFF757575), const Color(0xFFFFFFFF)];
  }

  List<Map<String, dynamic>> _getPlayerRecentMatches(LocalLineupPlayer p) {
    // Coach: generate matches for their team
    if (isCoach) {
      final team = widget.teamName;
      final opponents = ['Milan', 'Napoli', 'Lazio', 'Inter', 'Roma', 'Juventus', 'Atalanta', 'Fiorentina', 'Torino', 'Verona'];
      final scores = [[2,1],[0,0],[3,1],[1,2],[2,0],[1,1],[3,2],[0,1],[2,2],[1,0]];
      final results = ['W','D','W','L','W','D','W','L','D','W'];
      final dates = ['07/03','01/03','25/02','18/02','11/02','04/02','28/01','21/01','14/01','07/01'];
      final homes = [true,false,true,false,true,false,true,false,true,false];
      return [
        for (int i = 0; i < 10; i++)
          {
            'date': dates[i],
            'status': i == 0 ? 'upcoming' : 'played',
            'time': '20:45',
            'homeTeam': homes[i] ? team : opponents[i % opponents.length],
            'awayTeam': homes[i] ? opponents[i % opponents.length] : team,
            'homeScore': homes[i] ? scores[i][0] : scores[i][1],
            'awayScore': homes[i] ? scores[i][1] : scores[i][0],
            'result': i == 0 ? '-' : results[i],
            'rating': i == 0 ? 0.0 : 5.5 + (i % 5) * 0.4,
            'events': <Map<String, dynamic>>[],
          },
      ];
    }
    final isHome = widget.teamName == 'Lazio';
    final pos = p.position;
    final isAttacker = pos == 'ST' || pos == 'LW' || pos == 'RW' || pos == 'CF' || pos == 'AM';
    final isMidfielder = pos == 'CM' || pos == 'DM' || pos == 'AM';
    final isDefender = pos == 'CB' || pos == 'LB' || pos == 'RB';

    if (isHome) {
      return [
        {
          'date': '07/03', 'status': 'upcoming', 'time': '18:00',
          'homeTeam': 'Lazio', 'awayTeam': 'Udinese',
          'homeScore': 0, 'awayScore': 0, 'result': '-', 'rating': 0.0,
          'events': <Map<String, dynamic>>[],
        },
        {
          'date': '01/03', 'status': 'played',
          'homeTeam': 'Sassuolo', 'awayTeam': 'Lazio',
          'homeScore': 2, 'awayScore': 1, 'result': 'L',
          'rating': _playerRatingForMatch(p, 0),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
          ],
        },
        {
          'date': '25/02', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Milan',
          'homeScore': 2, 'awayScore': 1, 'result': 'W',
          'rating': p.rating > 0 ? p.rating : 6.5,
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
            if (isMidfielder) {'type': 'assist'},
          ],
        },
        {
          'date': '18/02', 'status': 'played',
          'homeTeam': 'Juventus', 'awayTeam': 'Lazio',
          'homeScore': 1, 'awayScore': 1, 'result': 'D',
          'rating': _playerRatingForMatch(p, 2),
          'events': <Map<String, dynamic>>[
            if (isDefender) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '11/02', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Fiorentina',
          'homeScore': 3, 'awayScore': 0, 'result': 'W',
          'rating': _playerRatingForMatch(p, 3),
          'events': <Map<String, dynamic>>[
            if (isAttacker) ...[{'type': 'goal'}, {'type': 'goal'}],
            if (isMidfielder) {'type': 'assist'},
          ],
        },
        // ── Partite extra (visibili dopo "Carica") ──
        {
          'date': '04/02', 'status': 'played',
          'homeTeam': 'Napoli', 'awayTeam': 'Lazio',
          'homeScore': 0, 'awayScore': 1, 'result': 'W',
          'rating': _playerRatingForMatch(p, 4),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
            if (isMidfielder) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '28/01', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Cagliari',
          'homeScore': 1, 'awayScore': 0, 'result': 'W',
          'rating': _playerRatingForMatch(p, 5),
          'events': <Map<String, dynamic>>[
            if (isDefender) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '21/01', 'status': 'played',
          'homeTeam': 'Roma', 'awayTeam': 'Lazio',
          'homeScore': 2, 'awayScore': 2, 'result': 'D',
          'rating': _playerRatingForMatch(p, 6),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
            if (isMidfielder) {'type': 'assist'},
          ],
        },
        {
          'date': '14/01', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Empoli',
          'homeScore': 2, 'awayScore': 0, 'result': 'W',
          'rating': _playerRatingForMatch(p, 7),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'assist'},
          ],
        },
        {
          'date': '07/01', 'status': 'played',
          'homeTeam': 'Atalanta', 'awayTeam': 'Lazio',
          'homeScore': 1, 'awayScore': 3, 'result': 'W',
          'rating': _playerRatingForMatch(p, 8),
          'events': <Map<String, dynamic>>[
            if (isAttacker) ...[{'type': 'goal'}, {'type': 'assist'}],
            if (isDefender) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '23/12', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Lecce',
          'homeScore': 2, 'awayScore': 1, 'result': 'W',
          'rating': _playerRatingForMatch(p, 9),
          'events': <Map<String, dynamic>>[],
        },
        {
          'date': '17/12', 'status': 'played',
          'homeTeam': 'Torino', 'awayTeam': 'Lazio',
          'homeScore': 0, 'awayScore': 0, 'result': 'D',
          'rating': _playerRatingForMatch(p, 10),
          'events': <Map<String, dynamic>>[
            if (isMidfielder) {'type': 'yellowCard'},
          ],
        },
      ];
    } else {
      return [
        {
          'date': '07/03', 'status': 'upcoming', 'time': '20:45',
          'homeTeam': 'Milan', 'awayTeam': 'Torino',
          'homeScore': 0, 'awayScore': 0, 'result': '-', 'rating': 0.0,
          'events': <Map<String, dynamic>>[],
        },
        {
          'date': '01/03', 'status': 'played',
          'homeTeam': 'Milan', 'awayTeam': 'Monza',
          'homeScore': 3, 'awayScore': 1, 'result': 'W',
          'rating': _playerRatingForMatch(p, 0),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
            if (isMidfielder) {'type': 'assist'},
          ],
        },
        {
          'date': '25/02', 'status': 'played',
          'homeTeam': 'Lazio', 'awayTeam': 'Milan',
          'homeScore': 2, 'awayScore': 1, 'result': 'L',
          'rating': p.rating > 0 ? p.rating : 6.0,
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
          ],
        },
        {
          'date': '18/02', 'status': 'played',
          'homeTeam': 'Milan', 'awayTeam': 'Inter',
          'homeScore': 1, 'awayScore': 2, 'result': 'L',
          'rating': _playerRatingForMatch(p, 2),
          'events': <Map<String, dynamic>>[
            if (isDefender) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '11/02', 'status': 'played',
          'homeTeam': 'Atalanta', 'awayTeam': 'Milan',
          'homeScore': 0, 'awayScore': 2, 'result': 'W',
          'rating': _playerRatingForMatch(p, 3),
          'events': <Map<String, dynamic>>[
            if (isAttacker) ...[{'type': 'goal'}, {'type': 'assist'}],
          ],
        },
        // ── Extra ──
        {
          'date': '04/02', 'status': 'played',
          'homeTeam': 'Milan', 'awayTeam': 'Bologna',
          'homeScore': 2, 'awayScore': 0, 'result': 'W',
          'rating': _playerRatingForMatch(p, 4),
          'events': <Map<String, dynamic>>[
            if (isAttacker) {'type': 'goal'},
          ],
        },
        {
          'date': '28/01', 'status': 'played',
          'homeTeam': 'Genoa', 'awayTeam': 'Milan',
          'homeScore': 1, 'awayScore': 1, 'result': 'D',
          'rating': _playerRatingForMatch(p, 5),
          'events': <Map<String, dynamic>>[
            if (isMidfielder) {'type': 'yellowCard'},
          ],
        },
        {
          'date': '21/01', 'status': 'played',
          'homeTeam': 'Milan', 'awayTeam': 'Roma',
          'homeScore': 3, 'awayScore': 2, 'result': 'W',
          'rating': _playerRatingForMatch(p, 6),
          'events': <Map<String, dynamic>>[
            if (isAttacker) ...[{'type': 'goal'}, {'type': 'goal'}],
            if (isMidfielder) {'type': 'assist'},
          ],
        },
        {
          'date': '14/01', 'status': 'played',
          'homeTeam': 'Verona', 'awayTeam': 'Milan',
          'homeScore': 0, 'awayScore': 1, 'result': 'W',
          'rating': _playerRatingForMatch(p, 7),
          'events': <Map<String, dynamic>>[],
        },
        {
          'date': '07/01', 'status': 'played',
          'homeTeam': 'Milan', 'awayTeam': 'Udinese',
          'homeScore': 4, 'awayScore': 1, 'result': 'W',
          'rating': _playerRatingForMatch(p, 8),
          'events': <Map<String, dynamic>>[
            if (isAttacker) ...[{'type': 'goal'}, {'type': 'assist'}],
          ],
        },
        {
          'date': '23/12', 'status': 'played',
          'homeTeam': 'Cagliari', 'awayTeam': 'Milan',
          'homeScore': 1, 'awayScore': 2, 'result': 'W',
          'rating': _playerRatingForMatch(p, 9),
          'events': <Map<String, dynamic>>[
            if (isDefender) {'type': 'yellowCard'},
          ],
        },
      ];
    }
  }

  double _playerRatingForMatch(LocalLineupPlayer p, int matchIdx) {
    final base = p.rating > 0 ? p.rating : 6.5;
    final offsets = [-0.3, 0.0, 0.2, 0.5, -0.1, 0.3, -0.2, 0.1, 0.4, -0.4, 0.1];
    final offset = offsets[matchIdx % offsets.length];
    return double.parse((base + offset).clamp(5.5, 9.0).toStringAsFixed(1));
  }

  Widget _buildSkillsTab(Map<String, dynamic> data, Color tx, Color lb,
      Color cardBg, bool isDark) {
    final skills = data['skills'] as Map<String, dynamic>? ?? {};
    final overall = data['overall'] as int? ?? 0;

    // Rating tier color
    Color tierColor;
    String tierLabel;
    if (overall >= 83) {
      tierColor = const Color(0xFFD4AF37); // Gold
      tierLabel = 'GOLD';
    } else if (overall >= 75) {
      tierColor = const Color(0xFFC0C0C0); // Silver
      tierLabel = 'SILVER';
    } else {
      tierColor = const Color(0xFFCD7F32); // Bronze
      tierLabel = 'BRONZE';
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── OVR HERO CARD ──
      Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    tierColor.withValues(alpha: 0.15),
                    tierColor.withValues(alpha: 0.05),
                  ]
                : [
                    tierColor.withValues(alpha: 0.12),
                    tierColor.withValues(alpha: 0.04),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tierColor.withValues(alpha: isDark ? 0.3 : 0.25),
            width: 1.5,
          ),
        ),
        child: Column(children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tierLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tierColor,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Big OVR number
          Text(
            '$overall',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: tierColor,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OVERALL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tx.withValues(alpha: 0.5),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          // Mini stat chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: skills.entries.map((e) {
              final val = (e.value as num).toInt();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatColor(val).withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _getStatColor(val).withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    tr(context, e.key),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tx.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$val',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _getStatColor(val),
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ]),
      ),

      // ── RUOLI FC26 ──
      const SizedBox(height: 8),
      _sectionTitle(localizeShotData(context, 'Posizioni'), tx),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Builder(builder: (ctx) {
          final pos = widget.player.position;
          final roles = _getFC26Roles(pos, overall);
          return Column(
            children: roles.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isLast = i == roles.length - 1;
              final fit = r['fit'] as int; // 0-100
              Color fitColor;
              if (fit >= 80) {
                fitColor = const Color(0xFF2E7D32);
              } else if (fit >= 60) fitColor = const Color(0xFF689F38);
              else if (fit >= 40) fitColor = const Color(0xFFF9A825);
              else fitColor = const Color(0xFFEF6C00);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
                  )),
                ),
                child: Row(children: [
                  // Position badge
                  Container(
                    width: 42, height: 28,
                    decoration: BoxDecoration(
                      color: fitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: fitColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(r['pos'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fitColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Role name
                  Expanded(
                    child: Text(tr(context, r['name'] as String),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
                  ),
                ]),
              );
            }).toList(),
          );
        }),
      ),
      const SizedBox(height: 20),
      // ── STAT BARS ──
      _sectionTitle(tr(context, 'Dettaglio parametri'), tx),
      const SizedBox(height: 12),
      ...skills.entries.map((e) {
        final label = e.key;
        final val = (e.value as num).toDouble();
        final color = _getStatColor(val.toInt());
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 36,
              child: Text(
                tr(context, label),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tx.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Stack(children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled bar
                FractionallySizedBox(
                  widthFactor: (val / 99).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '${val.toInt()}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ]),
        );
      }),
    ]);
  }

  // Stat color helper for FC26 bars
  List<Map<String, dynamic>> _getFC26Roles(String position, int overall) {
    // Ruoli FC26 basati sulla posizione reale + overall
    const rolesMap = {
      'GK': [
        {'pos': 'POR', 'name': 'Portiere', 'baseFit': 95},
        {'pos': 'POR-L', 'name': 'Portiere Libero', 'baseFit': 55},
      ],
      'CB': [
        {'pos': 'DC', 'name': 'Difensore Centrale', 'baseFit': 95},
        {'pos': 'DCS', 'name': 'Difensore Centrale Sinistro', 'baseFit': 80},
        {'pos': 'DCD', 'name': 'Difensore Centrale Destro', 'baseFit': 80},
      ],
      'LB': [
        {'pos': 'TS', 'name': 'Terzino Sinistro', 'baseFit': 95},
        {'pos': 'ES', 'name': 'Esterno Sinistro', 'baseFit': 70},
        {'pos': 'DCS', 'name': 'Difensore Centrale Sinistro', 'baseFit': 50},
      ],
      'RB': [
        {'pos': 'TD', 'name': 'Terzino Destro', 'baseFit': 95},
        {'pos': 'ED', 'name': 'Esterno Destro', 'baseFit': 70},
        {'pos': 'DCD', 'name': 'Difensore Centrale Destro', 'baseFit': 50},
      ],
      'DM': [
        {'pos': 'CDC', 'name': 'Centrocampista Difensivo', 'baseFit': 95},
        {'pos': 'CC', 'name': 'Centrocampista Centrale', 'baseFit': 75},
        {'pos': 'DC', 'name': 'Difensore Centrale', 'baseFit': 45},
      ],
      'CM': [
        {'pos': 'CC', 'name': 'Centrocampista Centrale', 'baseFit': 95},
        {'pos': 'CDC', 'name': 'Centrocampista Difensivo', 'baseFit': 65},
        {'pos': 'COC', 'name': 'Centrocampista Offensivo', 'baseFit': 70},
        {'pos': 'ES', 'name': 'Esterno Sinistro', 'baseFit': 45},
      ],
      'AM': [
        {'pos': 'COC', 'name': 'Centrocampista Offensivo', 'baseFit': 95},
        {'pos': 'CC', 'name': 'Centrocampista Centrale', 'baseFit': 60},
        {'pos': 'AS', 'name': 'Ala Sinistra', 'baseFit': 70},
        {'pos': 'AD', 'name': 'Ala Destra', 'baseFit': 70},
      ],
      'LW': [
        {'pos': 'AS', 'name': 'Ala Sinistra', 'baseFit': 95},
        {'pos': 'ES', 'name': 'Esterno Sinistro', 'baseFit': 75},
        {'pos': 'AT', 'name': 'Attaccante', 'baseFit': 65},
        {'pos': 'AD', 'name': 'Ala Destra', 'baseFit': 55},
      ],
      'RW': [
        {'pos': 'AD', 'name': 'Ala Destra', 'baseFit': 95},
        {'pos': 'ED', 'name': 'Esterno Destro', 'baseFit': 75},
        {'pos': 'AT', 'name': 'Attaccante', 'baseFit': 65},
        {'pos': 'AS', 'name': 'Ala Sinistra', 'baseFit': 55},
      ],
      'CF': [
        {'pos': 'AT', 'name': 'Attaccante', 'baseFit': 95},
        {'pos': 'COC', 'name': 'Centrocampista Offensivo', 'baseFit': 65},
        {'pos': 'AS', 'name': 'Ala Sinistra', 'baseFit': 60},
        {'pos': 'AD', 'name': 'Ala Destra', 'baseFit': 60},
      ],
      'ST': [
        {'pos': 'AT', 'name': 'Attaccante', 'baseFit': 95},
        {'pos': 'ATD', 'name': 'Seconda Punta', 'baseFit': 80},
        {'pos': 'AS', 'name': 'Ala Sinistra', 'baseFit': 50},
        {'pos': 'AD', 'name': 'Ala Destra', 'baseFit': 50},
      ],
    };

    final roles = rolesMap[position] ?? rolesMap['CM']!;
    // Aggiusta fit in base all'overall
    final overallFactor = (overall - 60) / 40.0; // 0.0 at 60, 1.0 at 100
    return roles.map((r) {
      final base = r['baseFit'] as int;
      final adjusted = (base * (0.7 + 0.3 * overallFactor)).round().clamp(15, 99);
      return {'pos': r['pos'], 'name': r['name'], 'fit': adjusted};
    }).toList();
  }

  Color _getStatColor(int val) {
    if (val >= 80) return const Color(0xFF4CAF50); // Green
    if (val >= 70) return const Color(0xFF8BC34A); // Light green
    if (val >= 60) return const Color(0xFFF9A825); // Amber 800 (contrasto su chiaro)
    if (val >= 50) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  // ── CAREER TAB ──
  Widget _buildCareerTab(Map<String, dynamic> data, Color tx, Color lb,
      Color cardBg, Color divider, bool isDark) {
    var career = data['career'] as List<Map<String, String>>? ?? [];
    // Override career for coaches with V/P/S data
    if (isCoach) {
      final coachCareerData = <String, List<Map<String, String>>>{
        'José Mourinho': [
          {'team': 'Roma', 'years': '2021-2024', 'apps': '128', 'goals': '0', 'wins': '62', 'draws': '30', 'losses': '36'},
          {'team': 'Tottenham', 'years': '2019-2021', 'apps': '86', 'goals': '0', 'wins': '44', 'draws': '19', 'losses': '23'},
          {'team': 'Manchester Utd', 'years': '2016-2018', 'apps': '144', 'goals': '0', 'wins': '84', 'draws': '31', 'losses': '29'},
          {'team': 'Chelsea', 'years': '2013-2015', 'apps': '136', 'goals': '0', 'wins': '80', 'draws': '29', 'losses': '27'},
          {'team': 'Real Madrid', 'years': '2010-2013', 'apps': '178', 'goals': '0', 'wins': '128', 'draws': '28', 'losses': '22'},
          {'team': 'Inter', 'years': '2008-2010', 'apps': '108', 'goals': '0', 'wins': '67', 'draws': '26', 'losses': '15'},
          {'team': 'Chelsea', 'years': '2004-2007', 'apps': '185', 'goals': '0', 'wins': '124', 'draws': '40', 'losses': '21'},
          {'team': 'Porto', 'years': '2002-2004', 'apps': '127', 'goals': '0', 'wins': '91', 'draws': '22', 'losses': '14'},
        ],
        'Thiago Motta': [
          {'team': 'Bologna', 'years': '2022 - Presente', 'apps': '72', 'goals': '0', 'wins': '33', 'draws': '22', 'losses': '17'},
          {'team': 'Spezia', 'years': '2021-2022', 'apps': '36', 'goals': '0', 'wins': '10', 'draws': '13', 'losses': '13'},
          {'team': 'Genoa U19', 'years': '2019-2021', 'apps': '48', 'goals': '0', 'wins': '22', 'draws': '12', 'losses': '14'},
        ],
        'Simone Inzaghi': [
          {'team': 'Inter', 'years': '2021 - Presente', 'apps': '158', 'goals': '0', 'wins': '98', 'draws': '30', 'losses': '30'},
          {'team': 'Lazio', 'years': '2016-2021', 'apps': '246', 'goals': '0', 'wins': '131', 'draws': '52', 'losses': '63'},
        ],
        'Stefano Pioli': [
          {'team': 'Milan', 'years': '2019-2024', 'apps': '242', 'goals': '0', 'wins': '138', 'draws': '50', 'losses': '54'},
          {'team': 'Fiorentina', 'years': '2017-2019', 'apps': '80', 'goals': '0', 'wins': '32', 'draws': '20', 'losses': '28'},
          {'team': 'Inter', 'years': '2016-2017', 'apps': '28', 'goals': '0', 'wins': '14', 'draws': '5', 'losses': '9'},
          {'team': 'Lazio', 'years': '2014-2016', 'apps': '92', 'goals': '0', 'wins': '42', 'draws': '22', 'losses': '28'},
        ],
        'Massimiliano Allegri': [
          {'team': 'Juventus', 'years': '2021-2024', 'apps': '138', 'goals': '0', 'wins': '72', 'draws': '38', 'losses': '28'},
          {'team': 'Juventus', 'years': '2014-2019', 'apps': '269', 'goals': '0', 'wins': '191', 'draws': '44', 'losses': '34'},
          {'team': 'Milan', 'years': '2010-2014', 'apps': '168', 'goals': '0', 'wins': '82', 'draws': '42', 'losses': '44'},
        ],
        'Luciano Spalletti': [
          {'team': 'Napoli', 'years': '2021-2023', 'apps': '82', 'goals': '0', 'wins': '55', 'draws': '14', 'losses': '13'},
          {'team': 'Inter', 'years': '2017-2019', 'apps': '98', 'goals': '0', 'wins': '52', 'draws': '22', 'losses': '24'},
          {'team': 'Roma', 'years': '2005-2009', 'apps': '192', 'goals': '0', 'wins': '100', 'draws': '48', 'losses': '44'},
        ],
        'Maurizio Sarri': [
          {'team': 'Lazio', 'years': '2021-2024', 'apps': '120', 'goals': '0', 'wins': '55', 'draws': '28', 'losses': '37'},
          {'team': 'Juventus', 'years': '2019-2020', 'apps': '52', 'goals': '0', 'wins': '34', 'draws': '9', 'losses': '9'},
          {'team': 'Chelsea', 'years': '2018-2019', 'apps': '63', 'goals': '0', 'wins': '39', 'draws': '12', 'losses': '12'},
          {'team': 'Napoli', 'years': '2015-2018', 'apps': '146', 'goals': '0', 'wins': '96', 'draws': '26', 'losses': '24'},
        ],
        'Gian Piero Gasperini': [
          {'team': 'Atalanta', 'years': '2016 - Presente', 'apps': '380', 'goals': '0', 'wins': '198', 'draws': '82', 'losses': '100'},
          {'team': 'Inter', 'years': '2011', 'apps': '5', 'goals': '0', 'wins': '1', 'draws': '1', 'losses': '3'},
          {'team': 'Genoa', 'years': '2006-2011', 'apps': '188', 'goals': '0', 'wins': '62', 'draws': '52', 'losses': '74'},
        ],
        'Vincenzo Italiano': [
          {'team': 'Fiorentina', 'years': '2021-2024', 'apps': '150', 'goals': '0', 'wins': '68', 'draws': '38', 'losses': '44'},
          {'team': 'Spezia', 'years': '2019-2021', 'apps': '78', 'goals': '0', 'wins': '30', 'draws': '22', 'losses': '26'},
        ],
        'Ivan Juric': [
          {'team': 'Torino', 'years': '2021-2024', 'apps': '118', 'goals': '0', 'wins': '38', 'draws': '34', 'losses': '46'},
          {'team': 'Verona', 'years': '2019-2021', 'apps': '80', 'goals': '0', 'wins': '28', 'draws': '24', 'losses': '28'},
        ],
      };
      career = coachCareerData[widget.player.name] ?? career;
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Personal info
      _sectionTitle(tr(context, 'Informazioni personali'), tx),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: divider)),
        child: Column(children: [
          _infoRow(tr(context, 'Data di nascita'), '${data['birthDate']}', tx, lb, divider),
          _infoRow(tr(context, 'Età'), '${data['age']} ${tr(context, 'anni')}', tx, lb, divider),
          _infoRow(tr(context, 'Nazionalità'), tr(context, data['nationality'] as String? ?? ''), tx, lb, divider),
          if (!isCoach) ...[_infoRow(tr(context, 'Altezza'), '${data['height']} cm', tx, lb, divider),
          _infoRow(tr(context, 'Peso'), '${data['weight']} kg', tx, lb, divider),
          _infoRow(
              tr(context, 'Piede preferito'), tr(context, data['foot'] as String? ?? ''), tx, lb, Colors.transparent),],
        ]),
      ),

      const SizedBox(height: 24),

      // Career history
      _sectionTitle(tr(context, 'Storico carriera'), tx),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: divider)),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.teamColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(
                  flex: 3,
                  child: Text(tr(context, 'Squadra'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: lb))),
              Expanded(
                  flex: 3,
                  child: Text(tr(context, 'Periodo'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: lb))),
              if (isCoach) ...[
                Expanded(flex: 1, child: Text(standingsAbbr(context, 'V'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(standingsAbbr(context, 'P'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(standingsAbbr(context, 'S'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red), textAlign: TextAlign.center)),
              ] else ...[
                Expanded(flex: 1, child: Text('App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(S.of(context)!.gol, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
              ],
            ]),
          ),
          ...career.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isLast = i == career.length - 1;
            final isCurrent = c['years']!.contains('Presente');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: divider, width: 0.5))),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Row(children: [
                      Builder(builder: (ctx) {
                        final colors = _getTeamColors(c['team']!);
                        final abbr = c['team']!.length > 3
                            ? c['team']!.substring(0, 3).toUpperCase()
                            : c['team']!.toUpperCase();
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors[0].withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Center(
                            child: Text(abbr,
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: colors[0]),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(c['team']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent ? widget.teamColor : tx,
                              ),
                              overflow: TextOverflow.ellipsis)),
                    ])),
                Expanded(
                    flex: 3,
                    child: Text(c['years']!.replaceAll('Presente', tr(context, 'Presente')),
                        style: TextStyle(fontSize: 12, color: lb))),
                if (isCoach) ...[
                  Expanded(flex: 1, child: Text(c['wins'] ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700]), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(c['draws'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(c['losses'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red), textAlign: TextAlign.center)),
                ] else ...[
                  Expanded(flex: 1, child: Text(c['apps']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(c['goals']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx), textAlign: TextAlign.center)),
                ],
              ]),
            );
          }),
          // Totals row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.teamColor.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(
                  flex: 6,
                  child: Text(tr(context, 'Totale carriera'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800))),
              if (isCoach) ...[
                Expanded(flex: 1, child: Text(career.fold(0, (sum, c) => sum + int.parse(c['wins'] ?? '0')).toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green[700]), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(career.fold(0, (sum, c) => sum + int.parse(c['draws'] ?? '0')).toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text(career.fold(0, (sum, c) => sum + int.parse(c['losses'] ?? '0')).toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.red), textAlign: TextAlign.center)),
              ] else ...[
              Expanded(
                  flex: 1,
                  child: Text(
                    career
                        .fold(0, (sum, c) => sum + int.parse(c['apps']!))
                        .toString(),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: tx),
                    textAlign: TextAlign.center,
                  )),
              Expanded(
                  flex: 1,
                  child: Text(
                    career
                        .fold(0, (sum, c) => sum + int.parse(c['goals']!))
                        .toString(),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: tx),
                    textAlign: TextAlign.center,
                  )),
              ],
            ]),
          ),
        ]),
      ),
    ]);
  }

  // ── Helpers ──
  Widget _sectionTitle(String title, Color tx) {
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: widget.teamColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tx, letterSpacing: 0.2)),
    ]);
  }
  Widget _statBoxIcon(IconData icon, String label, String value, Color color, Color cardBg, Color tx, Color lb) {
    final isDarkLocal = tx == Colors.white || tx == const Color(0xFFFFFFFF);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDarkLocal ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: tx)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: lb), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _profileStatRow(
      String label, String value, Color tx, Color lb, Color divider,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: divider, width: 0.5))),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: lb))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? tx)),
      ]),
    );
  }

  Widget _infoRow(
      String label, String value, Color tx, Color lb, Color divider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: divider, width: 0.5))),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: lb))),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: tx)),
      ]),
    );
  }
}
