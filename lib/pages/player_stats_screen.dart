// lib/pages/player_stats_screen.dart
//
// Schermata di dettaglio statistiche giocatore (Tiri/Passaggi/Drib/Difesa)
// estratta da tactical_formation_widget.dart per ridurre la dimensione del
// file e migliorare la separazione di responsabilita'.
//
// // [FAV-extract-playerstats]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/l10n_helper.dart';
import '../models/player.dart';
import '../painters/formation_painters.dart';
import 'player_profile_screen.dart';
import 'player_comparison_screen.dart';

class PlayerStatsScreen extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;

  const PlayerStatsScreen({
    Key? key,
    required this.player,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, bool> notifications = {
    'goals': false,
    'assists': false,
    'yellowCard': false,
    'redCard': false,
    'substitution': false,
    'shots': false,
    'tackles': false,
    'passes': false,
    'foulsCommitted': false,
    'foulsSuffered': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // 8 tabs ora!
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'player_${widget.player.id}_notifications';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        setState(() {
          notifications = decoded.map((k, v) => MapEntry(k, v as bool));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'player_${widget.player.id}_notifications';
      final jsonString = json.encode(notifications);
      await prefs.setString(key, jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${tr(context, 'Notifiche salvate per')} ${widget.player.name}!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(context, 'Errore nel salvataggio:')} $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleAllNotifications(bool value) {
    setState(() {
      notifications = notifications.map((key, _) => MapEntry(key, value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            _buildTabBar(isDark),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primaryColor),
                          SizedBox(height: 16),
                          Text(
                            tr(context, 'Caricamento preferenze...'),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(theme, isDark),
                        _buildShotTab(theme, isDark),
                        _buildPassTab(theme, isDark),
                        _buildDribTab(theme, isDark),
                        _buildDefTab(theme, isDark),
                        _buildNotificationsTab(theme, isDark),
                        _buildPerformanceTab(theme, isDark), // NUOVO!
                        _buildProfileTab(theme, isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  // BOTTONE CONFRONTA
                  IconButton(
                    icon: const Icon(Icons.compare_arrows),
                    onPressed: () => _openComparison(),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: tr(context, tr(context, 'Confronta giocatori')),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.player.photo != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.player.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.player.position,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.player.teamName} • #${widget.player.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.player.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
        indicator: BoxDecoration(
          gradient:
              const LinearGradient(colors: [Colors.black, Color(0xFF424242)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: 'Tutto'),
          Tab(text: 'Shot'),
          Tab(text: 'Pass'),
          Tab(text: 'Drib'),
          Tab(text: 'Def'),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications, size: 16),
              SizedBox(width: 4),
              Text(tr(context, 'Notifiche')),
            ],
          )),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 16),
              SizedBox(width: 4),
              Text(tr(context, 'Prestazioni')),
            ],
          )),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 4),
              Text(tr(context, 'Profilo')),
            ],
          )),
        ],
      ),
    );
  }

  static const offensivaColor = Color(0xFF00C853);
  static const difensivaColor = Color(0xFF1976D2);
  static const duelliColor = Color(0xFFFF9800);
  static const passaggiColor = Color(0xFF9C27B0);
  static const altroColor = Color(0xFF00BCD4);

  Widget _buildAllTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeatmap(),
        const SizedBox(height: 24),
        _buildStatItem('Gol', widget.player.goals?.toString() ?? '0',
            Icons.sports_soccer, theme, offensivaColor),
        _buildStatItem('xG', '0.25', Icons.query_stats, theme, offensivaColor),
        _buildStatItem('Assists', widget.player.assists?.toString() ?? '0',
            Icons.assist_walker, theme, offensivaColor),
        _buildStatItem('xA', '0.15', Icons.trending_up, theme, offensivaColor),
        Divider(height: 32),
        _buildStatItem(
            'Contributi difesa', '12', Icons.shield, theme, difensivaColor),
        _buildStatItem(tr(context, 'Contrasti (vinti)'), '${widget.player.tackles ?? 0} (1)',
            Icons.sports_kabaddi, theme, difensivaColor),
        _buildStatItem(
            tr(context, 'Intercetti'),
            widget.player.interceptions?.toString() ?? '0',
            Icons.block,
            theme,
            difensivaColor),
        _buildStatItem(
            tr(context, 'Chiusure difensive'), '11', Icons.lock, theme, difensivaColor),
        _buildStatItem(tr(context, 'Tiri respinti'), '1', Icons.sports_volleyball, theme,
            difensivaColor),
        _buildStatItem('Recuperi', '2', Icons.cached, theme, difensivaColor),
        Divider(height: 32),
        _buildStatItem(tr(context, 'Duelli a terra (vinti)'), '6 (1)', Icons.sports_mma,
            theme, duelliColor),
        _buildStatItem(tr(context, 'Duelli aerei (vinti)'), '6 (1)', Icons.flight_takeoff,
            theme, duelliColor),
        _buildStatItem(tr(context, 'Falli'), '3', Icons.warning, theme, duelliColor),
        _buildStatItem(tr(context, 'Dribbling (riusciti)'), '0 (0)', Icons.directions_run,
            theme, duelliColor),
        Divider(height: 32),
        _buildStatItem(
            tr(context, 'Passaggi (precisi)'),
            '${widget.player.passes ?? 0} (29/35 83%)',
            Icons.sync_alt,
            theme,
            passaggiColor),
        _buildStatItem(
            tr(context, 'Passaggi chiave'), '0', Icons.vpn_key, theme, passaggiColor),
        _buildStatItem(tr(context, 'Cross (precisi)'), '0 (0)', Icons.filter_tilt_shift,
            theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi metà avversaria'), '5/10 (50%)',
            Icons.trending_up, theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi propria metà'), '24/25 (96%)',
            Icons.trending_down, theme, passaggiColor),
        Divider(height: 32),
        _buildStatItem(tr(context, 'Tocchi'), '54', Icons.touch_app, theme, altroColor),
        _buildStatItem(
            'Palla persa', '7', Icons.remove_circle_outline, theme, altroColor),
        _buildStatItem(tr(context, 'Tiri (in porta)'), '${widget.player.shots ?? 0} (0)',
            Icons.sports, theme, altroColor),
        _buildStatItem(
            tr(context, 'Tiri totali'), '1', Icons.sports_baseball, theme, altroColor),
        _buildStatItem(tr(context, 'Tiri respinti'), '1', Icons.block, theme, altroColor),
      ],
    );
  }

  Widget _buildShotTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem('Gol', widget.player.goals?.toString() ?? '0',
            Icons.sports_soccer, theme, offensivaColor),
        _buildStatItem('xG', '0.25', Icons.query_stats, theme, offensivaColor),
        _buildStatItem(
            tr(context, 'Tiri totali'), '1', Icons.sports_baseball, theme, offensivaColor),
        _buildStatItem(
            tr(context, 'Tiri in porta'), '0', Icons.sports, theme, offensivaColor),
        _buildStatItem(
            tr(context, 'Tiri respinti'), '1', Icons.block, theme, offensivaColor),
      ],
    );
  }

  Widget _buildPassTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildStatItem(tr(context, 'Passaggi totali'), '${widget.player.passes ?? 0}',
            Icons.sync_alt, theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi precisi'), '29/35 (83%)', Icons.check_circle,
            theme, passaggiColor),
        _buildStatItem(
            tr(context, 'Passaggi chiave'), '0', Icons.vpn_key, theme, passaggiColor),
        _buildStatItem(
            'Cross', '0 (0)', Icons.filter_tilt_shift, theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi metà avversaria'), '5/10 (50%)',
            Icons.trending_up, theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi propria metà'), '24/25 (96%)',
            Icons.trending_down, theme, passaggiColor),
        _buildStatItem(tr(context, 'Passaggi lunghi'), '2/3 (67%)', Icons.arrow_forward,
            theme, passaggiColor),
      ],
    );
  }

  Widget _buildDribTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem(
            'Dribbling', '0', Icons.directions_run, theme, duelliColor),
        _buildStatItem(tr(context, 'Dribbling riusciti'), '0 (0%)', Icons.check_circle,
            theme, duelliColor),
        _buildStatItem(tr(context, 'Tocchi'), '54', Icons.touch_app, theme, duelliColor),
        _buildStatItem('Palla persa', '7', Icons.remove_circle_outline, theme,
            duelliColor),
        _buildStatItem(
            tr(context, 'Duelli a terra'), '6 (1)', Icons.sports_mma, theme, duelliColor),
        _buildStatItem(
            tr(context, 'Duelli aerei'), '6 (1)', Icons.flight_takeoff, theme, duelliColor),
      ],
    );
  }

  Widget _buildDefTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem(
            'Contributi difesa', '12', Icons.shield, theme, difensivaColor),
        _buildStatItem(tr(context, 'Contrasti'), '${widget.player.tackles ?? 0}',
            Icons.sports_kabaddi, theme, difensivaColor),
        _buildStatItem(tr(context, 'Contrasti vinti'), '1 (1)', Icons.emoji_events, theme,
            difensivaColor),
        _buildStatItem(
            tr(context, 'Intercetti'),
            widget.player.interceptions?.toString() ?? '0',
            Icons.block,
            theme,
            difensivaColor),
        _buildStatItem(
            tr(context, 'Chiusure difensive'), '11', Icons.lock, theme, difensivaColor),
        _buildStatItem(tr(context, 'Tiri respinti'), '1', Icons.sports_volleyball, theme,
            difensivaColor),
        _buildStatItem('Recuperi', '2', Icons.cached, theme, difensivaColor),
        _buildStatItem(tr(context, 'Falli'), '3', Icons.warning, theme, difensivaColor),
        if (widget.player.yellowCards != null && widget.player.yellowCards! > 0)
          _buildStatItem(
              tr(context, 'Cartellini gialli'),
              widget.player.yellowCards.toString(),
              Icons.square,
              theme,
              Colors.yellow[700]!),
        if (widget.player.redCards != null && widget.player.redCards! > 0)
          _buildStatItem('Cartellini rossi', widget.player.redCards.toString(),
              Icons.square, theme, Colors.red),
      ],
    );
  }

  Widget _buildNotificationsTab(ThemeData theme, bool isDark) {
    final allEnabled = notifications.values.every((v) => v);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.notifications_active,
                  size: 48, color: theme.primaryColor),
              SizedBox(height: 12),
              Text(
                tr(context, 'Notifiche Personalizzate'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ricevi notifiche per ogni azione di ${widget.player.name.split(' ').last}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _toggleAllNotifications(!allEnabled),
          icon: Icon(allEnabled
              ? Icons.notifications_off
              : Icons.notifications_active),
          label: Text(
            allEnabled ? tr(context, 'Disattiva tutte') : 'Attiva tutte',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allEnabled ? Colors.grey[700] : theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),
        const SizedBox(height: 24),
        _buildNotificationToggle(
            'Goal segnati',
            'Ricevi notifica quando segna un goal',
            Icons.sports_soccer,
            'goals',
            offensivaColor,
            isDark),
        _buildNotificationToggle(
            'Assist',
            'Ricevi notifica quando fa un assist',
            Icons.assist_walker,
            'assists',
            offensivaColor,
            isDark),
        _buildNotificationToggle(
            tr(context, 'Cartellino giallo'),
            'Ricevi notifica per ammonizioni',
            Icons.square,
            'yellowCard',
            Color(0xFFFFC107),
            isDark),
        _buildNotificationToggle(
            tr(context, 'Cartellino rosso'),
            'Ricevi notifica per espulsioni',
            Icons.square,
            'redCard',
            Color(0xFFE53935),
            isDark),
        _buildNotificationToggle(
            tr(context, 'Sostituzioni'),
            'Ricevi notifica quando entra/esce',
            Icons.swap_horiz,
            'substitution',
            Color(0xFF2196F3),
            isDark),
        _buildNotificationToggle(
            tr(context, 'Tiri in porta'),
            'Ricevi notifica per tiri in porta',
            Icons.sports,
            'shots',
            passaggiColor,
            isDark),
        _buildNotificationToggle(
            tr(context, 'Contrasti vinti'),
            'Ricevi notifica per contrasti importanti',
            Icons.sports_kabaddi,
            'tackles',
            difensivaColor,
            isDark),
        _buildNotificationToggle(
            tr(context, 'Passaggi chiave'),
            'Ricevi notifica per passaggi decisivi',
            Icons.vpn_key,
            'passes',
            passaggiColor,
            isDark),
        _buildNotificationToggle(
            tr(context, 'Falli commessi'),
            'Ricevi notifica quando commette un fallo',
            Icons.warning_amber,
            'foulsCommitted',
            duelliColor,
            isDark),
        _buildNotificationToggle(
            tr(context, 'Falli subiti'),
            'Ricevi notifica quando subisce un fallo',
            Icons.personal_injury,
            'foulsSuffered',
            altroColor,
            isDark),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveNotifications,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save),
              const SizedBox(width: 8),
              Text(
                tr(context, 'Salva preferenze notifiche'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NEW TAB PROFILO!
  Widget _buildProfileTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.account_circle, size: 64, color: theme.primaryColor),
                SizedBox(height: 16),
                Text(
                  tr(context, 'Profilo Completo'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scopri informazioni dettagliate su ${widget.player.name.split(' ')[0]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openFullProfile(),
                  icon: Icon(Icons.person),
                  label: Text(
                    tr(context, 'Vedi Profilo Completo'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildQuickInfo(
              tr(context, 'Informazioni'),
              [
                {'icon': Icons.cake, 'label': 'Età', 'value': '27 anni'},
                {'icon': Icons.height, 'label': 'Altezza', 'value': '183 cm'},
                {
                  'icon': Icons.fitness_center,
                  'label': 'Peso',
                  'value': '78 kg'
                },
                {
                  'icon': Icons.flag,
                  'label': 'Nazionalità',
                  'value': '🇮🇹 Italia'
                },
              ],
              theme,
              isDark),
          const SizedBox(height: 16),
          _buildQuickInfo(
              'Contratto',
              [
                {
                  'icon': Icons.shield,
                  'label': 'Squadra',
                  'value': widget.player.teamName
                },
                {
                  'icon': Icons.calendar_today,
                  'label': 'Scadenza',
                  'value': '30/06/2027'
                },
                {'icon': Icons.euro, 'label': 'Valore', 'value': '€45.0M'},
              ],
              theme,
              isDark),
        ],
      ),
    );
  }

  // TAB PRESTAZIONI CON GRAFICI
  Widget _buildPerformanceTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header sezione
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.show_chart, size: 48, color: theme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  'Prestazioni Recenti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analisi ultimi 10 match di ${widget.player.name.split(' ')[0]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rating Trend (Line Chart)
          _buildRatingTrendChart(theme, isDark),

          const SizedBox(height: 24),

          // Goal + Assist (Bar Chart)
          _buildGoalAssistChart(theme, isDark),

          const SizedBox(height: 24),

          // Form Indicator
          _buildFormIndicator(theme, isDark),

          const SizedBox(height: 24),

          // Minuti giocati trend
          _buildMinutesChart(theme, isDark),

          const SizedBox(height: 24),

          // Confronto media campionato
          _buildComparisonStats(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildRatingTrendChart(ThemeData theme, bool isDark) {
    // Dati mock ultimi 10 match
    final ratings = [6.5, 7.2, 6.8, 7.5, 8.0, 7.8, 6.9, 7.3, 7.7, 8.2];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.timeline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend Rating',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ultimi 10 match',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Color(0xFF00C853), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${ratings.last.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: LineChartPainter(
                values: ratings,
                color: const Color(0xFF00C853),
                isDark: isDark,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAssistChart(ThemeData theme, bool isDark) {
    // Dati mock ultimi 10 match
    final goals = [0, 1, 0, 2, 1, 0, 0, 1, 0, 1];
    final assists = [1, 0, 1, 0, 0, 1, 0, 0, 1, 0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'Goal & Assist'),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Contributi offensivi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_soccer,
                            size: 14, color: Color(0xFF00C853)),
                        const SizedBox(width: 4),
                        Text(
                          '${goals.reduce((a, b) => a + b)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assistant,
                            size: 14, color: Color(0xFF2196F3)),
                        const SizedBox(width: 4),
                        Text(
                          '${assists.reduce((a, b) => a + b)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: BarChartPainter(
                goalsData: goals,
                assistsData: assists,
                isDark: isDark,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormIndicator(ThemeData theme, bool isDark) {
    // Forma ultimi 5 match: W=Win, D=Draw, L=Loss
    final form = ['W', 'W', 'L', 'D', 'W'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'Forma Recente'),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ultimi 5 match della squadra',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: form.reversed.map((result) {
              Color color;
              IconData icon;
              String label;

              switch (result) {
                case 'W':
                  color = const Color(0xFF00C853);
                  icon = Icons.check_circle;
                  label = formInitial(context, 'W');
                  break;
                case 'D':
                  color = const Color(0xFFFFC107);
                  icon = Icons.remove_circle;
                  label = formInitial(context, 'D');
                  break;
                case 'L':
                  color = const Color(0xFFE53935);
                  icon = Icons.cancel;
                  label = formInitial(context, 'L');
                  break;
                default:
                  color = Colors.grey;
                  icon = Icons.help;
                  label = '?';
              }

              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesChart(ThemeData theme, bool isDark) {
    final minutes = [90, 78, 90, 85, 90, 73, 90, 90, 62, 90];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minuti Giocati',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tempo in campo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${minutes.reduce((a, b) => a + b)} min',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: MinutesChartPainter(
                minutes: minutes,
                color: const Color(0xFF9C27B0),
                isDark: isDark,
              ),
              size: const Size(double.infinity, 150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStats(ThemeData theme, bool isDark) {
    final playerStats = {
      'Rating': 7.4,
      'Goal/90': 0.6,
      'Assist/90': 0.3,
      'Pass%': 85.2,
      'Tackle': 2.1,
    };

    final leagueAvg = {
      'Rating': 6.8,
      'Goal/90': 0.4,
      'Assist/90': 0.2,
      'Pass%': 78.5,
      'Tackle': 1.8,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.compare_arrows,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'vs Media Campionato'),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      tr(context, 'Confronto prestazioni'),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...playerStats.entries.map((entry) {
            final playerValue = entry.value;
            final avgValue = leagueAvg[entry.key]!;
            final difference = ((playerValue - avgValue) / avgValue * 100);
            final isPositive = difference > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            playerValue.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? const Color(0xFF00C853).withOpacity(0.2)
                                  : const Color(0xFFE53935).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: isPositive
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFE53935),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${difference.abs().toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFE53935),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: (playerValue * 100).toInt(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (100 - playerValue * 100).toInt(),
                        child: Container(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Media: ${avgValue.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(String title, List<Map<String, dynamic>> items,
      ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData,
                        color: theme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    String key,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: notifications[key] ?? false,
        onChanged: (value) {
          setState(() {
            notifications[key] = value;
          });
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 52, top: 4),
          child: Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildHeatmap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: SofaScoreHeatmapPainter(),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, ThemeData theme, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _openFullProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerProfileScreen(player: widget.player),
      ),
    );
  }

  void _openComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerComparisonScreen(
          initialPlayers: [widget.player],
          allPlayers: widget.allPlayers,
        ),
      ),
    );
  }
}

// HEATMAP CORRETTA

// HEATMAP CORRETTA DEFINITIVA
