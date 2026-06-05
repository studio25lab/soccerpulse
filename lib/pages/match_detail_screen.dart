// lib/pages/match_detail_screen.dart
// ============================================================================
// MATCH DETAIL SCREEN - VERSIONE ULTRA COMPLETA
// ============================================================================
// ✅ Statistiche coerenti: 15 tiri home, 8 tiri away (= mappa tiri)
// ✅ Passaggi coerenti: somma giocatori singoli = totale squadra
// ✅ 8 Visualizzazioni Advanced Stats con Shot Map INTERATTIVA
// ✅ Sezione Passaggi stile SofaScore (campo heatmap + barre + cerchi)
// ✅ Eventi con Timeline, Filtri, Vista Compatta, Espandibili
// ============================================================================

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../generated/l10n.dart';
import 'team_detail_screen.dart';
import '../api/api_service.dart';
import '../models/team_standing.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/soccer_match.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../services/match_data_service.dart';
import '../models/match_data.dart' hide ShotData;
import 'player_match_stats_screen.dart';
import 'match_player_profile_screen.dart';
import 'coach_profile_screen.dart';
import 'match_player_comparison_screen.dart';
import '../widgets/match_event_overlay.dart';
import '../widgets/tabs/match_form_tab.dart';
import '../widgets/tabs/pre_match_info_tab.dart';
import '../widgets/tabs/h2h_tab.dart';
import '../widgets/tabs/probable_lineups_tab.dart';
import '../widgets/tabs/statistics_tab.dart';
import '../painters/match_detail_painters.dart'; // [FAV-extract-painters]
import 'player_finished_match_screen.dart';
import '../painters/advanced_stats_painters.dart';
import '../widgets/interactive_shot_map_widget.dart';
import '../widgets/player_match_visuals.dart';
import '../widgets/Interactive_defensive_widget.dart';
import '../widgets/player_match_visuals.dart';
import '../services/match_notification_preferences_service.dart';
import '../services/player_notification_preferences_service.dart';
import '../services/live_match_simulator.dart';
import '../models/match_notification_settings.dart';
import '../widgets/notification_settings_widgets.dart';
import '../models/player_notification_settings.dart';
import 'dart:async';
import 'package:soccerpulse/pages/main_navigation.dart';
import 'package:soccerpulse/models/local_match_models.dart';
import 'package:soccerpulse/main.dart';


class MatchDetailScreen extends StatefulWidget {
  final SoccerMatch match;
  const MatchDetailScreen({Key? key, required this.match}) : super(key: key);
  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  final MatchDataService _matchDataService = MatchDataService();

  // ── Notification Services ──
  final MatchNotificationPreferencesService _matchNotifService =
      MatchNotificationPreferencesService();
  final LiveMatchSimulator _liveSimulator = LiveMatchSimulator();
  StreamSubscription<SoccerMatch>? _liveMatchSubscription;
  int _lastProcessedEventCount = 0;

  // ── In-App Notification Queue ──
  final List<MatchEventNotification> _notificationQueue = [];
  bool _isShowingNotification = false;

  MatchData? _matchData;
  bool _isLoadingMatchData = false;

  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _advancedStatsAnimationController;
  late Animation<double> _headerAnimation;

  // Advanced Stats
  String _advancedStatsFilter = 'shotmap';
  bool _advancedStatsShowHome = true;
  // Shotmap: null = tutti, true = home, false = away
  bool? _shotmapSelectedTeam;
  // Passaggi: null = vista comparativa, true = home, false = away
  bool? _passesSelectedTeam;
  // Heatmap: null = entrambe sovrapposte, true = home, false = away
  bool? _heatmapSelectedTeam;
  int _heatmapTimeFilter = 0; // 0=tutti, 1=primo tempo, 2=secondo tempo
  int _shotmapTimeFilter = 0; // 0=tutti, 1=primo tempo, 2=secondo tempo (UI only)
  int _attackTimeFilter = 0;  // 0=tutti, 1=primo tempo, 2=secondo tempo (UI only)
  int _passesTimeFilter = 0;  // 0=tutti, 1=primo tempo, 2=secondo tempo (UI only)
  // Attacco: uses _advancedStatsShowHome from team selector

  // Shot Map Data (coerente con statistiche)
  List<ShotData> _homeShotsData = [];
  int _visualTab = -1;
  List<ShotData> _awayShotsData = [];

  // Defensive Data
  List<DefensiveActionData> _homeDefensiveActions = [];
  List<DefensiveActionData> _awayDefensiveActions = [];
  DefensiveStats _homeDefensiveStats = const DefensiveStats(
      tacklesWon: 15, tacklesTotal: 20, interceptions: 10, rinvii: 9);
  DefensiveStats _awayDefensiveStats = const DefensiveStats(
      tacklesWon: 11, tacklesTotal: 17, interceptions: 8, rinvii: 9);

  // Events
  Set<String> _activeEventFilters = {
    'goal',
    'yellowCard',
    'redCard',
    'substitution'
  }; // default: key events
  bool _eventsChronologicalOrder = true;

  // Lineups
  bool _showHomeLineup = true;

  // Misc
  // ── Notification preferences (backed by service) ──
  late MatchNotificationSettings _matchNotifSettings;
  Map<String, bool> get _notifPrefs => _matchNotifSettingsToMap();
  bool get _matchNotificationsEnabled =>
      _matchNotifSettings.hasActiveNotifications;

  Map<String, bool> _matchNotifSettingsToMap() {
    return {
      'goals': _matchNotifSettings.notifyHomeGoals || _matchNotifSettings.notifyAwayGoals,
      'kickoff': _matchNotifSettings.notifyMatchStart,
      'halftime': _matchNotifSettings.notifyHalfTime,
      'fulltime': _matchNotifSettings.notifyMatchEnd,
      'yellowCards': _matchNotifSettings.notifyYellowCards,
      'redCards': _matchNotifSettings.notifyRedCards,
      'substitutions': _matchNotifSettings.notifySubstitutions,
      'corners': _matchNotifSettings.notifyCorners,
      'offsides': _matchNotifSettings.notifyOffsides,
      'shotsOnTarget': _matchNotifSettings.notifyShotsOnTarget,
      'fouls': _matchNotifSettings.notifyFouls,
      'penalties': _matchNotifSettings.notifyPenalties,
      'var': _matchNotifSettings.notifyVarDecisions,
    };
  }

  void _updateMatchNotifFromKey(String key, bool value) {
    switch (key) {
      case 'goals':
        _matchNotifSettings = _matchNotifSettings.copyWith(
          notifyHomeGoals: value, notifyAwayGoals: value);
        break;
      case 'kickoff':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyMatchStart: value);
        break;
      case 'halftime':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyHalfTime: value);
        break;
      case 'fulltime':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyMatchEnd: value);
        break;
      case 'yellowCards':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyYellowCards: value);
        break;
      case 'redCards':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyRedCards: value);
        break;
      case 'substitutions':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifySubstitutions: value);
        break;
      case 'corners':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyCorners: value);
        break;
      case 'offsides':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyOffsides: value);
        break;
      case 'shotsOnTarget':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyShotsOnTarget: value);
        break;
      case 'fouls':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyFouls: value);
        break;
      case 'penalties':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyPenalties: value);
        break;
      case 'var':
        _matchNotifSettings = _matchNotifSettings.copyWith(notifyVarDecisions: value);
        break;
    }
    // [FAV-D2c-fix] master sync: accendere un toggle accende il master
    if (value && !_matchNotifSettings.enabled) {
      _matchNotifSettings =
          _matchNotifSettings.copyWith(enabled: true);
    }
    // Persiste su disco
    _matchNotifService.saveSettingsForMatch(_matchNotifSettings);
  }

  void _setAllMatchNotif(bool value) {
    // [FAV-D2c-fix] master sync: enabled segue value
    _matchNotifSettings = _matchNotifSettings.copyWith(
      enabled: value,
      notifyHomeGoals: value,
      notifyAwayGoals: value,
      notifyYellowCards: value,
      notifyRedCards: value,
      notifySubstitutions: value,
      notifyShotsOnTarget: value,
      notifyCorners: value,
      notifyPenalties: value,
      notifyFouls: value,
      notifyOffsides: value,
      notifyMatchStart: value,
      notifyHalfTime: value,
      notifySecondHalfStart: value,
      notifyMatchEnd: value,
      notifyVarDecisions: value,
    );
    _matchNotifService.saveSettingsForMatch(_matchNotifSettings);
  }
  final TextEditingController _playerSearchController = TextEditingController();
  String _playerSearchQuery = '';
  int _currentMatchMinute = 67;

  // ==========================================
  // STATISTICHE CENTRALIZZATE (fonte unica)
  // ==========================================
  // --- Generali ---
  static const int _homePossession = 58;
  static const int _awayPossession = 42;
  static const int _homeShotsTotal =
      15; // 2 goal + 5 on_target + 5 off_target + 3 blocked
  static const int _awayShotsTotal =
      8; // 1 goal + 2 on_target + 3 off_target + 2 blocked
  static const int _homeShotsOnTarget = 7; // 2 goal + 5 on_target
  static const int _awayShotsOnTarget = 3; // 1 goal + 2 on_target
  static const int _homeCorners = 6;
  static const int _awayCorners = 4;
  static const int _homeFouls = 12;
  static const int _awayFouls = 15;
  static const int _homeYellowCards = 2;
  static const int _awayYellowCards = 3;
  // --- Fuorigioco (da eventi: Immobile 28'+82', Felipe Anderson 70' = 3 home / Giroud 41', Leao 58' = 2 away) ---
  static const int _homeOffsides = 3;
  static const int _awayOffsides = 2;

  // --- Passaggi (somma giocatori singoli = totale squadra) ---
  static const int _homePassesTotal = 420; // somma 11 titolari ✅
  static const int _homePassesCompleted = 346; // somma 11 titolari ✅
  static const int _awayPassesTotal = 280; // somma 11 titolari ✅
  static const int _awayPassesCompleted = 217; // somma 11 titolari ✅
  static const int _homeThrowIns = 23;
  static const int _awayThrowIns = 24;
  static const int _homeFinalThirdEntries = 54;
  static const int _awayFinalThirdEntries = 42;
  // Passaggi nel terzo offensivo
  static const int _homeFTPasses = 64;
  static const int _homeFTTotal = 98;
  static const int _awayFTPasses = 50;
  static const int _awayFTTotal = 81;
  // Palle lunghe
  static const int _homeLongBallsOk = 17;
  static const int _homeLongBallsTotal = 44;
  static const int _awayLongBallsOk = 24;
  static const int _awayLongBallsTotal = 58;
  // Cross
  static const int _homeCrossOk = 5;
  static const int _homeCrossTotal = 26;
  static const int _awayCrossOk = 4;
  static const int _awayCrossTotal = 19;
  // Distribuzione zona (%)
  static const int _homePassLeft = 33;
  static const int _homePassCenter = 44;
  static const int _homePassRight = 23;
  static const int _awayPassLeft = 28;
  static const int _awayPassCenter = 48;
  static const int _awayPassRight = 24;
  // Passaggi chiave e progressivi
  static const int _homeKeyPasses = 14;
  static const int _awayKeyPasses = 9;
  static const int _homeProgressivePasses = 38;
  static const int _awayProgressivePasses = 27;
  // Distribuzione lunghezza (corti + medi + lunghi = totale passaggi)
  // Home: 234 + 142 + 44 = 420 ✅ | Away: 148 + 74 + 58 = 280 ✅
  static const int _homeShortPasses = 234;
  static const int _homeMediumPasses = 142;
  static const int _homeLongPasses = 44;
  static const int _awayShortPasses = 148;
  static const int _awayMediumPasses = 74;
  static const int _awayLongPasses = 58;
  // Dettaglio accuratezza per zona (per popup interattivo)
  // Home: left 117/139, center 158/185, right 71/96  → 346/420 ✅
  static const int _homePassLeftOk = 117;
  static const int _homePassLeftTotal = 139;
  static const int _homePassCenterOk = 158;
  static const int _homePassCenterTotal = 185;
  static const int _homePassRightOk = 71;
  static const int _homePassRightTotal = 96;
  // Away: left 62/78, center 103/135, right 52/67  → 217/280 ✅
  static const int _awayPassLeftOk = 62;
  static const int _awayPassLeftTotal = 78;
  static const int _awayPassCenterOk = 103;
  static const int _awayPassCenterTotal = 135;
  static const int _awayPassRightOk = 52;
  static const int _awayPassRightTotal = 67;
  // Zona generale (combinata entrambe le squadre)
  // Left: 139+78=217, Center: 185+135=320, Right: 96+67=163, Total: 700 ✅ (420+280)
  static const int _generalZoneLeft = 217;
  static const int _generalZoneCenter = 320;
  static const int _generalZoneRight = 163;
  static const int _generalZoneTotal =
      700; // = _homePassesTotal(420) + _awayPassesTotal(280)

  // ═══════════════════════════════════════════════════════════════
  // HEATMAP — Tocchi reali per 9 zone del campo
  // Zone: [DifSX, DifC, DifDX, CentSX, CentC, CentDX, AttSX, AttC, AttDX]
  // Dati: numero tocchi/azioni in 90 minuti (realistici per Serie A)
  // ═══════════════════════════════════════════════════════════════
  // Home (Lazio) — possesso 58%, attacco a destra, centrocampo dominante
  // ═══════════════════════════════════════════════════════════════
  // HEATMAP — Tocchi reali per zona (mock realistico Serie A)
  // Griglia 4×5 = 20 zone per risoluzione più alta
  // Righe: Difesa, Centrodifesa, Centrocampo, Centroattacco, Attacco
  // Colonne: Sinistra, Centro-Sinistra, Centro-Destra, Destra
  //
  // Lazio (58% poss, 2-1 vincente): gioco verticale, fascia destra forte,
  // centrocampo dominante con Milinkovic-Savic e Luis Alberto,
  // pressing alto, Immobile nel corridoio centrale attacco
  // ═══════════════════════════════════════════════════════════════
  // Lazio (58% poss, vittoria 2-1): gioco dominante in centrocampo centrale,
  // costruzione dal basso con CB centrali, spinta sulle fasce centrali,
  // pochi tocchi negli angoli del campo
  static const List<int> _homeHeatZones = [
    // Difesa:     SX   CSX  CDX  DX     ← zona bassa, costruzione CB
    8, 38, 35, 6,
    // Centrodif:  SX   CSX  CDX  DX     ← salita palla
    18, 72, 65, 15,
    // Centrocamp: SX   CSX  CDX  DX     ← ZONA DOMINANTE Milinkovic+Luis Alberto
    32, 115, 108, 28,
    // Centroatt:  SX   CSX  CDX  DX     ← trequarti, Felipe Anderson + Immobile
    25, 82, 90, 35,
    // Attacco:    SX   CSX  CDX  DX     ← area avversaria
    10, 55, 62, 22,
  ];

  // Milan (42% poss, sconfitta 1-2): blocco basso difensivo compatto,
  // Theo Hernandez unica spinta a sinistra, Leao contropiede,
  // pochissimi tocchi in attacco, centrocampo schiacciato
  static const List<int> _awayHeatZones = [
    // Difesa:     SX   CSX  CDX  DX     ← BLOCCO BASSO DOMINANTE
    35, 95, 90, 30,
    // Centrodif:  SX   CSX  CDX  DX     ← linea difensiva alta
    38, 75, 68, 18,
    // Centrocamp: SX   CSX  CDX  DX     ← schiacciati, poco possesso
    22, 45, 38, 12,
    // Centroatt:  SX   CSX  CDX  DX     ← raramente, solo ripartenze
    15, 18, 14, 5,
    // Attacco:    SX   CSX  CDX  DX     ← quasi zero, solo contropiede Leao
    12, 8, 5, 3,
  ];

  static const int _heatGridCols = 4;
  static const int _heatGridRows = 5;
  // Possesso palla % per terzo
  static const int _homePossDefense = 30;
  static const int _homePossMidfield = 44;
  static const int _homePossAttack = 26;
  static const int _awayPossDefense = 34;
  static const int _awayPossMidfield = 40;
  static const int _awayPossAttack = 26;
  // Territorio — % azioni nella metà campo avversaria (diverso da possesso)
  static const int _homeTerritory = 56;
  static const int _awayTerritory = 44;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.match.isScheduled ? 5 : 6, vsync: this);
    _headerAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _statsAnimationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _advancedStatsAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _headerAnimation = CurvedAnimation(
        parent: _headerAnimationController, curve: Curves.easeOutCubic);
    _headerAnimationController.forward();

    _tabController.addListener(() {
      if (widget.match.isScheduled) return; // No special handling for pre-match
      if (_tabController.index == 1) {
        _statsAnimationController.reset();
        _statsAnimationController.forward();
      } else if (_tabController.index == 3) {
        _advancedStatsAnimationController.reset();
        _advancedStatsAnimationController.forward();
      }
    });

    _loadMatchData();
    _loadShotData();

    _playerSearchController.addListener(() {
      setState(() =>
          _playerSearchQuery = _playerSearchController.text.toLowerCase());
    });
    // ── Carica impostazioni notifiche dal service ──
    _matchNotifSettings = _matchNotifService.getSettingsForMatch(widget.match.id);
    _matchNotifService.loadSettings().then((_) {
      if (mounted) {
        setState(() {
          _matchNotifSettings = _matchNotifService.getSettingsForMatch(widget.match.id);
        });
      }
    });
    // ── Ascolta eventi live per notifiche in-app ──
    _startLiveNotificationListener();
  }

  void _startLiveNotificationListener() {
    final stream = _liveSimulator.getLiveMatchStream(widget.match.id);
    if (stream == null) return;

    _liveMatchSubscription = stream.listen((updatedMatch) {
      final events = _liveSimulator.getMatchEvents(widget.match.id);
      if (events.length > _lastProcessedEventCount) {
        for (int i = _lastProcessedEventCount; i < events.length; i++) {
          _processLiveEvent(events[i]);
        }
        _lastProcessedEventCount = events.length;
      }
    });
  }

  void _processLiveEvent(LiveMatchEvent event) {
    String? eventType;
    switch (event.type) {
      case 'goal': eventType = 'goal'; break;
      case 'yellowCard': eventType = 'yellow_card'; break;
      case 'redCard': eventType = 'red_card'; break;
      case 'penalty': eventType = 'penalty'; break;
      case 'var': eventType = 'var'; break;
      case 'substitution': eventType = 'substitution'; break;
      case 'corner': eventType = 'corner'; break;
      case 'shotOnTarget': eventType = 'shot_on_target'; break;
      case 'offside': eventType = 'offside'; break;
      case 'matchStart': eventType = 'match_start'; break;
      case 'halfTime': eventType = 'half_time'; break;
      case 'secondHalfStart': eventType = 'second_half_start'; break;
      case 'matchEnd': eventType = 'match_end'; break;
      default: return;
    }

    final team = event.teamType == 'home' ? 'home' : (event.teamType == 'away' ? 'away' : null);

    final shouldNotify = _matchNotifService.shouldNotifyEvent(
      matchId: widget.match.id,
      eventType: eventType,
      team: team,
    );

    if (shouldNotify) {
      _showInAppNotification(
        MatchEventNotification(
          type: event.type,
          title: _getNotificationTitle(event),
          subtitle: _getNotificationSubtitle(event),
          icon: _getNotificationIcon(event.type),
          color: _getNotificationColor(event.type),
          minute: event.minute,
        ),
      );
    }
  }

  String _getNotificationTitle(LiveMatchEvent event) {
    switch (event.type) {
      case 'goal': return tr(context, '⚽ GOAL!');
      case 'yellowCard': return tr(context, '🟨 Cartellino Giallo');
      case 'redCard': return tr(context, '🟥 Cartellino Rosso');
      case 'penalty': return tr(context, '⚠️ Rigore');
      case 'var': return tr(context, '📺 VAR Check');
      case 'substitution': return tr(context, '🔄 Sostituzione');
      case 'corner': return tr(context, "🚩 Calcio d'angolo");
      case 'shotOnTarget': return tr(context, '🎯 Tiro in porta');
      case 'offside': return tr(context, '🏳️ Fuorigioco');
      case 'matchStart': return tr(context, '🏁 Partita Iniziata!');
      case 'halfTime': return tr(context, '⏱️ Fine Primo Tempo');
      case 'secondHalfStart': return tr(context, '▶️ Inizio Secondo Tempo');
      case 'matchEnd': return tr(context, '⏱️ Partita Terminata');
      default: return event.type.toUpperCase();
    }
  }

  String _getNotificationSubtitle(LiveMatchEvent event) {
    final teamLabel = event.teamType == 'home'
        ? widget.match.homeTeamName
        : (event.teamType == 'away' ? widget.match.awayTeamName : '');
    // Match-level events (no player)
    if (event.type == 'matchStart' || event.type == 'halfTime' || 
        event.type == 'secondHalfStart' || event.type == 'matchEnd') {
      return '${widget.match.homeTeamName} vs ${widget.match.awayTeamName}';
    }
    String text = "${event.minute}' - ${event.playerName}";
    if (teamLabel.isNotEmpty) text += ' ($teamLabel)';
    if (event.assistBy != null) text += '\n${tr(context, 'Assist')}: ${event.assistBy}';
    if (event.details != null) text += ' - ${event.details}';
    return text;
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'goal': return Icons.sports_soccer;
      case 'yellowCard': return Icons.square_rounded;
      case 'redCard': return Icons.square_rounded;
      case 'penalty': return Icons.sports;
      case 'var': return Icons.tv;
      case 'substitution': return Icons.swap_horiz;
      case 'corner': return Icons.flag;
      case 'shotOnTarget': return Icons.gps_fixed;
      case 'offside': return Icons.outlined_flag;
      case 'matchStart': return Icons.play_circle;
      case 'halfTime': return Icons.pause_circle;
      case 'secondHalfStart': return Icons.play_circle;
      case 'matchEnd': return Icons.stop_circle;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'goal': return const Color(0xFF4CAF50);
      case 'yellowCard': return const Color(0xFFFFC107);
      case 'redCard': return const Color(0xFFF44336);
      case 'penalty': return const Color(0xFFFF9800);
      case 'var': return const Color(0xFF2196F3);
      case 'substitution': return const Color(0xFF42A5F5);
      case 'corner': return const Color(0xFF66BB6A);
      case 'shotOnTarget': return const Color(0xFFAB47BC);
      case 'offside': return const Color(0xFF78909C);
      case 'matchStart': return const Color(0xFF26A69A);
      case 'halfTime': return const Color(0xFF8D6E63);
      case 'secondHalfStart': return const Color(0xFF26A69A);
      case 'matchEnd': return const Color(0xFF5C6BC0);
      default: return const Color(0xFF9E9E9E);
    }
  }

  void _showInAppNotification(MatchEventNotification notif) {
    _notificationQueue.add(notif);
    if (!_isShowingNotification) {
      _displayNextNotification();
    }
  }

  void _displayNextNotification() {
    if (_notificationQueue.isEmpty) {
      _isShowingNotification = false;
      return;
    }
    _isShowingNotification = true;
    final notif = _notificationQueue.removeAt(0);
    _haptic.mediumImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => MatchEventOverlay(
        notification: notif,
        onDismissed: () {
          entry.remove();
          Future.delayed(const Duration(milliseconds: 300), () {
            _displayNextNotification();
          });
        },
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry);
  }

  Future<void> _handleRefresh() async {
    _haptic.mediumImpact();
    // Simula caricamento dati
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // Quando collegheremo le API, qui ricaricheremo i dati
      });
    }
  }

  @override
  void dispose() {
    _liveMatchSubscription?.cancel();
    _tabController.dispose();
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    _advancedStatsAnimationController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchData() async {
    setState(() => _isLoadingMatchData = true);
    try {
      final matchData = await _matchDataService.loadMatchData(widget.match.id,
          forceRefresh: false);
      setState(() {
        _matchData = matchData;
        _isLoadingMatchData = false;
      });
    } catch (e) {
      setState(() => _isLoadingMatchData = false);
    }
  }

  // ============================================================================
  // SHOT DATA - 15 TIRI HOME (7 in porta), 8 TIRI AWAY (3 in porta)
  // ============================================================================
  void _loadShotData() {
    // ====== HOME: 15 TIRI (2 goal + 5 on_target + 5 off_target + 3 blocked) ======
    _homeShotsData = [
      // --- GOAL (2) --- contano come "in porta"
      ShotData(
          playerName: 'Immobile',
          playerPhoto: '',
          minute: 12,
          startX: 0.55,
          startY: 0.22,
          goalX: 0.72,
          goalY: 0.65,
          type: 'goal',
          xG: 0.45,
          xGOT: 0.52,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'In basso a destra'),
      ShotData(
          playerName: 'Felipe Anderson',
          playerPhoto: '',
          minute: 78,
          startX: 0.38,
          startY: 0.28,
          goalX: 0.25,
          goalY: 0.70,
          type: 'goal',
          xG: 0.38,
          xGOT: 0.55,
          situation: 'Contropiede',
          shotType: 'Tiro di sinistro',
          goalZone: 'In basso a sinistra'),

      // --- ON TARGET (5) --- parate del portiere
      ShotData(
          playerName: 'Pedro',
          playerPhoto: '',
          minute: 8,
          startX: 0.68,
          startY: 0.32,
          goalX: 0.80,
          goalY: 0.45,
          type: 'on_target',
          xG: 0.15,
          xGOT: 0.18,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro destra'),
      ShotData(
          playerName: 'Zaccagni',
          playerPhoto: '',
          minute: 33,
          startX: 0.30,
          startY: 0.35,
          goalX: 0.40,
          goalY: 0.50,
          type: 'on_target',
          xG: 0.18,
          xGOT: 0.22,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Centro'),
      ShotData(
          playerName: 'Luis Alberto',
          playerPhoto: '',
          minute: 52,
          startX: 0.45,
          startY: 0.50,
          goalX: 0.55,
          goalY: 0.30,
          type: 'on_target',
          xG: 0.12,
          xGOT: 0.15,
          situation: 'Calcio di punizione',
          shotType: 'Tiro di destro',
          goalZone: 'In alto a destra'),
      ShotData(
          playerName: 'Cataldi',
          playerPhoto: '',
          minute: 60,
          startX: 0.50,
          startY: 0.60,
          goalX: 0.45,
          goalY: 0.55,
          type: 'on_target',
          xG: 0.08,
          xGOT: 0.10,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro'),
      ShotData(
          playerName: 'Immobile',
          playerPhoto: '',
          minute: 71,
          startX: 0.52,
          startY: 0.18,
          goalX: 0.60,
          goalY: 0.40,
          type: 'on_target',
          xG: 0.32,
          xGOT: 0.28,
          situation: 'Gioco aperto',
          shotType: 'Colpo di testa',
          goalZone: 'Centro destra'),

      // --- OFF TARGET (5) --- fuori dallo specchio della porta
      ShotData(
          playerName: 'Zaccagni',
          playerPhoto: '',
          minute: 15,
          startX: 0.25,
          startY: 0.40,
          goalX: -0.20,
          goalY: 0.40,
          type: 'off_target',
          xG: 0.06,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Largo a sinistra'),
      ShotData(
          playerName: 'Luis Alberto',
          playerPhoto: '',
          minute: 38,
          startX: 0.48,
          startY: 0.55,
          goalX: 0.50,
          goalY: -0.25,
          type: 'off_target',
          xG: 0.05,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Sopra la traversa'),
      ShotData(
          playerName: 'Pedro',
          playerPhoto: '',
          minute: 41,
          startX: 0.75,
          startY: 0.38,
          goalX: 1.25,
          goalY: 0.35,
          type: 'off_target',
          xG: 0.08,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Largo a destra'),
      ShotData(
          playerName: 'Felipe Anderson',
          playerPhoto: '',
          minute: 55,
          startX: 0.42,
          startY: 0.42,
          goalX: 0.45,
          goalY: -0.30,
          type: 'off_target',
          xG: 0.10,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Sopra la traversa'),
      ShotData(
          playerName: 'Guendouzi',
          playerPhoto: '',
          minute: 85,
          startX: 0.62,
          startY: 0.65,
          goalX: 1.15,
          goalY: 0.25,
          type: 'off_target',
          xG: 0.04,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Largo a destra'),

      // --- BLOCKED (3) --- respinti dai difensori
      ShotData(
          playerName: 'Pedro',
          playerPhoto: '',
          minute: 48,
          startX: 0.60,
          startY: 0.35,
          goalX: 0.55,
          goalY: 0.50,
          type: 'blocked',
          xG: 0.14,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro'),
      ShotData(
          playerName: 'Immobile',
          playerPhoto: '',
          minute: 67,
          startX: 0.50,
          startY: 0.20,
          goalX: 0.50,
          goalY: 0.45,
          type: 'blocked',
          xG: 0.22,
          situation: 'Gioco aperto',
          shotType: 'Colpo di testa',
          goalZone: 'Centro'),
      ShotData(
          playerName: 'Guendouzi',
          playerPhoto: '',
          minute: 73,
          startX: 0.55,
          startY: 0.58,
          goalX: 0.48,
          goalY: 0.55,
          type: 'blocked',
          xG: 0.06,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro'),
    ];

    // ====== AWAY: 8 TIRI (1 goal + 2 on_target + 3 off_target + 2 blocked) ======
    _awayShotsData = [
      ShotData(
          playerName: 'Giroud',
          playerPhoto: '',
          minute: 56,
          startX: 0.50,
          startY: 0.20,
          goalX: 0.60,
          goalY: 0.25,
          type: 'goal',
          xG: 0.38,
          xGOT: 0.44,
          situation: 'Gioco aperto',
          shotType: 'Colpo di testa',
          goalZone: 'In alto a destra'),
      ShotData(
          playerName: 'Leao',
          playerPhoto: '',
          minute: 18,
          startX: 0.25,
          startY: 0.35,
          goalX: 0.30,
          goalY: 0.50,
          type: 'on_target',
          xG: 0.28,
          xGOT: 0.25,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Centro sinistra'),
      ShotData(
          playerName: 'Brahim Diaz',
          playerPhoto: '',
          minute: 80,
          startX: 0.45,
          startY: 0.45,
          goalX: 0.40,
          goalY: 0.30,
          type: 'on_target',
          xG: 0.10,
          xGOT: 0.12,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'In alto a sinistra'),
      ShotData(
          playerName: 'Leao',
          playerPhoto: '',
          minute: 35,
          startX: 0.20,
          startY: 0.30,
          goalX: -0.18,
          goalY: 0.50,
          type: 'off_target',
          xG: 0.12,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Largo a sinistra'),
      ShotData(
          playerName: 'Theo Hernandez',
          playerPhoto: '',
          minute: 42,
          startX: 0.18,
          startY: 0.55,
          goalX: 0.40,
          goalY: -0.30,
          type: 'off_target',
          xG: 0.05,
          situation: 'Gioco aperto',
          shotType: 'Tiro di sinistro',
          goalZone: 'Sopra la traversa'),
      ShotData(
          playerName: 'Pulisic',
          playerPhoto: '',
          minute: 63,
          startX: 0.70,
          startY: 0.40,
          goalX: 1.20,
          goalY: 0.30,
          type: 'off_target',
          xG: 0.09,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Largo a destra'),
      ShotData(
          playerName: 'Bennacer',
          playerPhoto: '',
          minute: 50,
          startX: 0.55,
          startY: 0.60,
          goalX: 0.50,
          goalY: 0.50,
          type: 'blocked',
          xG: 0.07,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro'),
      ShotData(
          playerName: 'Pulisic',
          playerPhoto: '',
          minute: 71,
          startX: 0.65,
          startY: 0.38,
          goalX: 0.55,
          goalY: 0.45,
          type: 'blocked',
          xG: 0.15,
          situation: 'Gioco aperto',
          shotType: 'Tiro di destro',
          goalZone: 'Centro'),
    ];

    // ── Dati difensivi mock realistici ──
    _homeDefensiveActions = [
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 2,
          fieldX: 0.16,
          fieldY: 0.37,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Cataldi',
          minute: 3,
          fieldX: 0.31,
          fieldY: 0.53,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 9,
          fieldX: 0.17,
          fieldY: 0.61,
          type: 'clearance',
          won: true,
          detail: 'Di piede',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 12,
          fieldX: 0.2,
          fieldY: 0.52,
          type: 'clearance',
          won: true,
          detail: 'Rinvio',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 13,
          fieldX: 0.18,
          fieldY: 0.22,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 14,
          fieldX: 0.25,
          fieldY: 0.71,
          type: 'tackle',
          won: true,
          detail: 'Contrasto',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Lazzari',
          minute: 16,
          fieldX: 0.21,
          fieldY: 0.9,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Guendouzi',
          minute: 18,
          fieldX: 0.49,
          fieldY: 0.52,
          type: 'tackle',
          won: false,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Marusic',
          minute: 19,
          fieldX: 0.18,
          fieldY: 0.25,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 21,
          fieldX: 0.2,
          fieldY: 0.4,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 22,
          fieldX: 0.13,
          fieldY: 0.58,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Guendouzi',
          minute: 23,
          fieldX: 0.41,
          fieldY: 0.77,
          type: 'interception',
          won: true,
          detail: 'Lettura',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Cataldi',
          minute: 27,
          fieldX: 0.46,
          fieldY: 0.5,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Pedro',
          minute: 29,
          fieldX: 0.53,
          fieldY: 0.2,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 31,
          fieldX: 0.2,
          fieldY: 0.23,
          type: 'clearance',
          won: true,
          detail: 'Rinvio',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 33,
          fieldX: 0.18,
          fieldY: 0.3,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 35,
          fieldX: 0.14,
          fieldY: 0.41,
          type: 'clearance',
          won: true,
          detail: 'Di testa',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Cataldi',
          minute: 36,
          fieldX: 0.42,
          fieldY: 0.52,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 37,
          fieldX: 0.19,
          fieldY: 0.22,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Guendouzi',
          minute: 41,
          fieldX: 0.4,
          fieldY: 0.49,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 48,
          fieldX: 0.22,
          fieldY: 0.57,
          type: 'clearance',
          won: true,
          detail: 'Di piede',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 50,
          fieldX: 0.24,
          fieldY: 0.4,
          type: 'clearance',
          won: true,
          detail: 'Di testa',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 53,
          fieldX: 0.22,
          fieldY: 0.68,
          type: 'clearance',
          won: true,
          detail: 'Rinvio',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 55,
          fieldX: 0.2,
          fieldY: 0.62,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Lazzari',
          minute: 56,
          fieldX: 0.25,
          fieldY: 0.91,
          type: 'tackle',
          won: false,
          detail: 'Scivolata',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 60,
          fieldX: 0.12,
          fieldY: 0.5,
          type: 'clearance',
          won: true,
          detail: 'Di piede',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Lazzari',
          minute: 61,
          fieldX: 0.18,
          fieldY: 0.87,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Guendouzi',
          minute: 64,
          fieldX: 0.26,
          fieldY: 0.73,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Cataldi',
          minute: 66,
          fieldX: 0.28,
          fieldY: 0.46,
          type: 'tackle',
          won: false,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Guendouzi',
          minute: 69,
          fieldX: 0.34,
          fieldY: 0.3,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Marusic',
          minute: 70,
          fieldX: 0.15,
          fieldY: 0.1,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 73,
          fieldX: 0.12,
          fieldY: 0.56,
          type: 'tackle',
          won: false,
          detail: 'In piedi',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 74,
          fieldX: 0.09,
          fieldY: 0.75,
          type: 'clearance',
          won: true,
          detail: 'Rinvio',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Marusic',
          minute: 76,
          fieldX: 0.28,
          fieldY: 0.14,
          type: 'tackle',
          won: true,
          detail: 'Contrasto',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Cataldi',
          minute: 82,
          fieldX: 0.38,
          fieldY: 0.26,
          type: 'interception',
          won: true,
          detail: 'Lettura',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 83,
          fieldX: 0.16,
          fieldY: 0.36,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Patric',
          minute: 84,
          fieldX: 0.14,
          fieldY: 0.6,
          type: 'tackle',
          won: false,
          detail: 'Scivolata',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Vecino',
          minute: 87,
          fieldX: 0.43,
          fieldY: 0.44,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: true),
      DefensiveActionData(
          playerName: 'Romagnoli',
          minute: 88,
          fieldX: 0.12,
          fieldY: 0.64,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: true),
    ];
    _awayDefensiveActions = [
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 3,
          fieldX: 0.19,
          fieldY: 0.52,
          type: 'clearance',
          won: true,
          detail: 'Di testa',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 8,
          fieldX: 0.15,
          fieldY: 0.72,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Calabria',
          minute: 9,
          fieldX: 0.12,
          fieldY: 0.11,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 11,
          fieldX: 0.11,
          fieldY: 0.48,
          type: 'clearance',
          won: true,
          detail: 'Spazzata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 14,
          fieldX: 0.22,
          fieldY: 0.71,
          type: 'clearance',
          won: true,
          detail: 'Di testa',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 15,
          fieldX: 0.09,
          fieldY: 0.64,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Pulisic',
          minute: 16,
          fieldX: 0.47,
          fieldY: 0.22,
          type: 'tackle',
          won: false,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 17,
          fieldX: 0.15,
          fieldY: 0.51,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 18,
          fieldX: 0.27,
          fieldY: 0.33,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 19,
          fieldX: 0.11,
          fieldY: 0.52,
          type: 'interception',
          won: true,
          detail: 'Lettura',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 23,
          fieldX: 0.24,
          fieldY: 0.71,
          type: 'clearance',
          won: true,
          detail: 'Spazzata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Theo Hernandez',
          minute: 25,
          fieldX: 0.1,
          fieldY: 0.85,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Bennacer',
          minute: 32,
          fieldX: 0.4,
          fieldY: 0.61,
          type: 'tackle',
          won: true,
          detail: 'Contrasto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Bennacer',
          minute: 33,
          fieldX: 0.28,
          fieldY: 0.73,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Bennacer',
          minute: 35,
          fieldX: 0.48,
          fieldY: 0.32,
          type: 'interception',
          won: true,
          detail: 'Lettura',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Calabria',
          minute: 38,
          fieldX: 0.33,
          fieldY: 0.21,
          type: 'tackle',
          won: true,
          detail: 'Contrasto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 40,
          fieldX: 0.29,
          fieldY: 0.7,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Theo Hernandez',
          minute: 42,
          fieldX: 0.28,
          fieldY: 0.76,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 44,
          fieldX: 0.12,
          fieldY: 0.74,
          type: 'interception',
          won: true,
          detail: 'Anticipo',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 47,
          fieldX: 0.1,
          fieldY: 0.6,
          type: 'tackle',
          won: true,
          detail: 'Contrasto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 49,
          fieldX: 0.47,
          fieldY: 0.73,
          type: 'tackle',
          won: false,
          detail: 'Tackle laterale',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 51,
          fieldX: 0.11,
          fieldY: 0.2,
          type: 'clearance',
          won: true,
          detail: 'Rinvio',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Kjaer',
          minute: 53,
          fieldX: 0.16,
          fieldY: 0.33,
          type: 'clearance',
          won: true,
          detail: 'Di testa',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 54,
          fieldX: 0.12,
          fieldY: 0.48,
          type: 'clearance',
          won: true,
          detail: 'Di piede',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 60,
          fieldX: 0.28,
          fieldY: 0.59,
          type: 'tackle',
          won: true,
          detail: 'Tackle laterale',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 64,
          fieldX: 0.17,
          fieldY: 0.37,
          type: 'clearance',
          won: true,
          detail: 'Di piede',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Theo Hernandez',
          minute: 69,
          fieldX: 0.09,
          fieldY: 0.85,
          type: 'tackle',
          won: true,
          detail: 'In piedi',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Calabria',
          minute: 73,
          fieldX: 0.27,
          fieldY: 0.2,
          type: 'tackle',
          won: false,
          detail: 'Contrasto',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 75,
          fieldX: 0.17,
          fieldY: 0.63,
          type: 'clearance',
          won: true,
          detail: 'Spazzata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Bennacer',
          minute: 76,
          fieldX: 0.4,
          fieldY: 0.45,
          type: 'tackle',
          won: false,
          detail: 'Tackle laterale',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 77,
          fieldX: 0.12,
          fieldY: 0.4,
          type: 'tackle',
          won: false,
          detail: 'In piedi',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 81,
          fieldX: 0.48,
          fieldY: 0.76,
          type: 'tackle',
          won: true,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tomori',
          minute: 82,
          fieldX: 0.18,
          fieldY: 0.2,
          type: 'tackle',
          won: false,
          detail: 'Scivolata',
          isHomeTeam: false),
      DefensiveActionData(
          playerName: 'Tonali',
          minute: 87,
          fieldX: 0.5,
          fieldY: 0.68,
          type: 'interception',
          won: true,
          detail: 'Intercetto',
          isHomeTeam: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Column(children: [
        _buildEnhancedHeader(theme, isDark),
        _buildModernTabBar(theme, isDark),
        Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
          if (widget.match.isScheduled) ...[
            _buildPreMatchInfoTab(theme, isDark),
            _buildProbableLineupsTab(theme, isDark),
            _buildH2HTab(theme, isDark),
            _buildFormTab(theme, isDark),
            _buildStandingsComparisonTab(theme, isDark),
          ] else ...[
            _buildEnhancedEventsTab(theme, isDark),
            _buildStatisticsTab(theme, isDark),
            _buildLineupsTab(theme, isDark),
            _buildAdvancedStatsTab(theme, isDark),
            _buildInfoTab(theme, isDark),
            _buildH2HTab(theme, isDark),
          ],
        ])),
      ]),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildEnhancedHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.primaryColor,
          theme.primaryColor.withOpacity(0.85),
          theme.primaryColor.withOpacity(0.7)
        ]),
        boxShadow: [
          BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(children: [
        Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          _buildMatchStatusBadge(),
          const SizedBox(width: 12),
          // ── Bell: notifications only ──
          IconButton(
            icon: Icon(
              _matchNotificationsEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: _matchNotificationsEnabled ? const Color(0xFF4CAF50) : Colors.white,
              size: 24,
            ),
            onPressed: () async {
              _haptic.lightImpact();
              await _showMatchNotificationDialog();
              setState(() {
                _matchNotifSettings = _matchNotifService.getSettingsForMatch(widget.match.id);
              });
            },
          ),
          // ── Heart: favorite + auto-enable notifications ──
          Builder(builder: (ctx) {
            final favSvc = ctx.watch<FavoritesService>();
            final isFav = favSvc.isMatchFavorite(widget.match.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border,
                color: isFav ? const Color(0xFFE53935) : Colors.white,
                size: 24,
              ),
              onPressed: () {
                _haptic.lightImpact();
                final wasFav = favSvc.isMatchFavorite(widget.match.id);
                favSvc.toggleMatchFavorite(widget.match.id, status: widget.match.status);
                if (!wasFav) {
                  // Store display data
                  favSvc.storeMatchDisplayData(widget.match.id, {
                    'homeTeam': widget.match.homeTeamName,
                    'awayTeam': widget.match.awayTeamName,
                    'homeLogo': widget.match.homeTeamLogo ?? '',
                    'awayLogo': widget.match.awayTeamLogo ?? '',
                    'homeId': widget.match.homeTeamId,
                    'awayId': widget.match.awayTeamId,
                    'homeScore': widget.match.homeScore,
                    'awayScore': widget.match.awayScore,
                    'status': widget.match.status,
                    'date': widget.match.time,
                    'time': widget.match.time,
                    'league': widget.match.leagueName ?? 'Serie A',
                    'round': widget.match.round ?? '',
                  });
                  // Auto-enable basic notifications
                  final notifSvc = context.read<MatchNotificationPreferencesService>();
                  notifSvc.enableBasicNotifications(widget.match.id);
                  setState(() {
                    _matchNotifSettings = notifSvc.getSettingsForMatch(widget.match.id);
                  });
                }
              },
            );
          }),
          IconButton(
              icon: const Icon(Icons.home_rounded,
                  color: Colors.white, size: 24),
              tooltip: 'Home',
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }),
        ]),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: GestureDetector(
                onTap: () => _navigateToTeamDetail(
                  widget.match.homeTeamId, widget.match.homeTeamName, widget.match.homeTeamLogo),
                child: Column(children: [
              _buildTeamLogo(widget.match.homeTeamLogo),
              const SizedBox(height: 12),
              Text(widget.match.homeTeamName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ]))),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
            child: Text(
                '${widget.match.homeScore ?? 0} - ${widget.match.awayScore ?? 0}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900)),
          ),
          Expanded(
              child: GestureDetector(
                onTap: () => _navigateToTeamDetail(
                  widget.match.awayTeamId, widget.match.awayTeamName, widget.match.awayTeamLogo),
                child: Column(children: [
              _buildTeamLogo(widget.match.awayTeamLogo),
              const SizedBox(height: 12),
              Text(widget.match.awayTeamName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ]))),
        ]),
      ]),
    );
  }




  // Helper: traduce i detail degli eventi
  String _localizeEventDetail(BuildContext context, String? detail) {
    if (detail == null || detail.isEmpty) return '';
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    // ── Token-based detail (always normalized, both IT and EN) ──
    if (detail.startsWith('FOUL_ON:')) {
      final name = detail.substring(8);
      return isEn ? 'Foul on $name' : 'Fallo su $name';
    }
    if (detail == 'CORNER_LEFT') return isEn ? 'Left corner' : 'Corner sinistro';
    if (detail == 'CORNER_RIGHT') return isEn ? 'Right corner' : 'Corner destro';
    if (detail == 'CORNER') return isEn ? 'Corner' : 'Corner';
    if (detail == 'OFFSIDE_ACTIVE') return isEn ? 'Active offside' : 'Fuorigioco attivo';
    if (detail == 'OFFSIDE_PASSIVE') return isEn ? 'Passive offside' : 'Fuorigioco passivo';
    if (detail == 'TACTICAL_FOUL') return isEn ? 'Tactical foul' : 'Fallo tattico';
    if (detail == 'PROTESTS') return isEn ? 'Protests' : 'Proteste';
    // ── Italian token in italian: pass-through; in english: localize ──
    if (!isEn) return detail;
    if (detail.startsWith('Assist:')) return detail;
    return localizeShotData(context, detail);
  }
  void _navigateToTeamDetail(int teamId, String teamName, String? teamLogo) async {
    _haptic.lightImpact();
    try {
      final apiService = ApiService();
      final standings = await apiService.fetchStandings(135);
      final match = standings.where((t) => t.teamId == teamId || t.teamName.contains(teamName) || teamName.contains(t.teamName));
      if (match.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => TeamDetailScreen(teamStanding: match.first),
        ));
        return;
      }
    } catch (_) {}
    // Fallback con dati minimi
    final teamStanding = TeamStanding(
      teamId: teamId,
      teamName: teamName,
      teamLogo: teamLogo,
      position: 0,
      leagueId: 135,
      points: 0, played: 0, wins: 0, draws: 0, losses: 0,
      goalsFor: 0, goalsAgainst: 0, goalsDiff: 0,
      form: '',
      home: TeamStats(played: 0, win: 0, draw: 0, lose: 0, goalsFor: 0, goalsAgainst: 0),
      away: TeamStats(played: 0, win: 0, draw: 0, lose: 0, goalsFor: 0, goalsAgainst: 0),
      status: '',
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TeamDetailScreen(teamStanding: teamStanding),
    ));
  }

  Widget _buildTeamLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.shield,
          color: Colors.white70,
          size: 64,
        ),
      );
    }
    return const Icon(Icons.shield, color: Colors.white70, size: 64);
  }

  Widget _buildMatchStatusBadge() {
    String label;
    Color bgColor;
    IconData? icon;
    bool pulse = false;

    if (widget.match.isLive) {
      label = "$_currentMatchMinute'";
      bgColor = Colors.red;
      icon = Icons.circle;
      pulse = true;
    } else if (widget.match.isHalfTime) {
      label = 'HT';
      bgColor = Colors.orange;
      icon = Icons.pause;
    } else if (widget.match.isFinished) {
      label = 'FT';
      bgColor = Colors.white.withOpacity(0.2);
      icon = null;
    } else if (widget.match.isScheduled) {
      label = widget.match.time;
      bgColor = Colors.white.withOpacity(0.2);
      icon = Icons.access_time;
    } else {
      label = widget.match.status;
      bgColor = Colors.white.withOpacity(0.2);
      icon = null;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(pulse ? 0.9 : 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: pulse ? 2 : 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon,
              size: pulse ? 8 : 14,
              color: pulse ? Colors.white : Colors.white70),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: pulse ? 14 : 13)),
      ]),
    );

    if (pulse) {
      return badge
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2000.ms, color: Colors.white24);
    }
    return badge;
  }

  Widget _buildModernTabBar(ThemeData theme, bool isDark) {
    final eventsCount =
        _matchData?.events.length ?? _generateDetailedMockEvents().length;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: widget.match.isScheduled ? [
            _buildTab(Icons.info_outline, S.of(context)!.info),
            _buildTab(Icons.sports_soccer, tr(context, 'Probabili')),
            _buildTab(Icons.compare_arrows_rounded, S.of(context)!.h2h),
            _buildTab(Icons.trending_up_rounded, tr(context, 'Forma')),
            _buildTab(Icons.leaderboard_rounded, S.of(context)!.classifica),
          ] : [
            _buildTab(Icons.timeline, S.of(context)!.events, badge: eventsCount),
            _buildTab(Icons.bar_chart, S.of(context)!.statistics),
            _buildTab(Icons.sports_soccer, S.of(context)!.formazioni),
            _buildTab(Icons.analytics, S.of(context)!.advanced),
            _buildTab(Icons.info_outline, S.of(context)!.info),
            _buildTab(Icons.compare_arrows_rounded, S.of(context)!.h2h),
          ]),
    );
  }

  Widget _buildTab(IconData icon, String label, {int? badge}) {
    return Tab(
        height: 60,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]));
  }

  // ============================================================================
  // TAB 1: STATISTICS (usa costanti centralizzate)
  // ============================================================================

  // ── Team Header per Stats ──

  // ── Possesso Palla — Widget speciale con arc/donut ──

  // ── Stats Section (card con titolo + lista stat rows) ──

  // ── Premium Stat Row ──

  // ── StatItem helper class ──
  // (defined at bottom of file as top-level)

  // ── Possession Bar Painter ──
  // (defined at bottom of file as top-level)

  // ============================================================================
  // TAB 2: ADVANCED STATS
  // ============================================================================
  Widget _buildStatisticsTab(ThemeData theme, bool isDark) {
    return StatisticsTab(
      homeTeamName: widget.match.homeTeamName,
      awayTeamName: widget.match.awayTeamName,
      homePossession: _homePossession,
      awayPossession: _awayPossession,
      homeShotsTotal: _homeShotsTotal,
      awayShotsTotal: _awayShotsTotal,
      homeShotsOnTarget: _homeShotsOnTarget,
      awayShotsOnTarget: _awayShotsOnTarget,
      homePassesTotal: _homePassesTotal,
      awayPassesTotal: _awayPassesTotal,
      homePassesCompleted: _homePassesCompleted,
      awayPassesCompleted: _awayPassesCompleted,
      homeKeyPasses: _homeKeyPasses,
      awayKeyPasses: _awayKeyPasses,
      homeCrossOk: _homeCrossOk,
      awayCrossOk: _awayCrossOk,
      homeLongBallsOk: _homeLongBallsOk,
      awayLongBallsOk: _awayLongBallsOk,
      homeCorners: _homeCorners,
      awayCorners: _awayCorners,
      homeThrowIns: _homeThrowIns,
      awayThrowIns: _awayThrowIns,
      homeOffsides: _homeOffsides,
      awayOffsides: _awayOffsides,
      homeFouls: _homeFouls,
      awayFouls: _awayFouls,
      homeYellowCards: _homeYellowCards,
      awayYellowCards: _awayYellowCards,
      homeDefensiveStats: _homeDefensiveStats,
      awayDefensiveStats: _awayDefensiveStats,
    );
  }

  Widget _buildAdvancedStatsTab(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        isDark ? Colors.grey[900]! : Colors.grey[50]!,
        isDark ? Colors.grey[850]! : Colors.white
      ])),
      child: Column(children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration:
              BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _buildAdvancedFilterChip(
                    S.of(context)!.mappaTiri, Icons.sports_soccer, 'shotmap', theme),
                const SizedBox(width: 8),
                _buildAdvancedFilterChip(
                    S.of(context)!.attaccoSection, Icons.flash_on, 'attack', theme),
                const SizedBox(width: 8),
                _buildAdvancedFilterChip(
                    S.of(context)!.passaggiSection, Icons.swap_calls, 'passnetwork', theme),
                const SizedBox(width: 8),
                _buildAdvancedFilterChip(
                    S.of(context)!.heatmap, Icons.whatshot, 'heatmap', theme),
                const SizedBox(width: 8),
                _buildAdvancedFilterChip(
                    S.of(context)!.difensiva, Icons.shield, 'defensive', theme),
              ])),
        ),

        Expanded(child: _buildAdvancedVisualization(isDark)),

        // Legenda: escludi shotmap, passnetwork, heatmap (hanno UI propria)
        if (_advancedStatsFilter != 'shotmap' &&
            _advancedStatsFilter != 'passnetwork' &&
            _advancedStatsFilter != 'heatmap' &&
            _advancedStatsFilter != 'defensive' &&
            _advancedStatsFilter != 'attack')
          _buildAdvancedLegend(isDark),
      ]),
    );
  }

  Widget _buildAdvancedFilterChip(
      String label, IconData icon, String filter, ThemeData theme) {
    final isSelected = _advancedStatsFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _advancedStatsFilter = filter);
        _haptic.lightImpact();
        _advancedStatsAnimationController.reset();
        _advancedStatsAnimationController.forward();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ])
                : null,
            color: isSelected ? null : Colors.grey[200],
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[700])),
        ]),
      ),
    );
  }

  // ═══ REUSABLE TEAM SELECTOR (Tutti / Home / Away) — same style as Passaggi/Heatmap ═══
  Widget _buildTeamSelector3(
      bool? selected, ValueChanged<bool?> onChanged, bool isDark,
      {bool showTutti = true}) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    Widget tab(String label, bool? val) {
      final active = selected == val;
      return GestureDetector(
        onTap: () {
          onChanged(val);
          _haptic.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? tx : lb)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (showTutti) ...[
              tab(localizeShotData(context, 'Tutti'), null),
              const SizedBox(width: 4),
            ],
            tab(widget.match.homeTeamName, true),
            const SizedBox(width: 4),
            tab(widget.match.awayTeamName, false),
          ]),
        ),
      ),
    );
  }

  // Period selector (Tutti / 1° Tempo / 2° Tempo) — chip pill coerente con _buildTeamSelector3
  Widget _buildPeriodSelector(
      int value, ValueChanged<int> onChanged, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    Widget chip(String label, int val) {
      final active = value == val;
      return GestureDetector(
        onTap: () {
          onChanged(val);
          _haptic.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? tx : lb)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            chip(localizeShotData(context, 'Tutti'), 0),
            const SizedBox(width: 4),
            chip(tr(context, '1° Tempo'), 1),
            const SizedBox(width: 4),
            chip(tr(context, '2° Tempo'), 2),
          ]),
        ),
      ),
    );
  }

  /// Filtro periodo (Tutti / 1° Tempo / 2° Tempo) — applicato ai dataset
  /// che hanno il minuto (ShotData.minute, LocalMatchEvent.minute,
  /// _mockAttackMomentum[0]). filter: 0=tutti, 1=primo tempo (minute<=45),
  /// 2=secondo tempo (minute>45). Quando arriveranno dati API con recuperi
  /// (45+1, 90+2), normalizzare al numero base prima della chiamata
  /// (es. minute clamp a 45 per 1°T, 90 per 2°T) oppure cambiare la regola
  /// qui in un solo posto.
  bool _inSelectedHalf(int minute, int filter) {
    if (filter == 0) return true;
    if (filter == 1) return minute <= 45;
    return minute > 45;
  }

  /// Filtro periodo per zone heatmap (Patch 7). filter==0 -> dati intatti.
  /// Per 1°T / 2°T scala proporzionalmente al numero di attacchi della squadra
  /// in quel periodo (derivato da _mockAttackMomentum). Quando arriveranno
  /// dati API per-metà, sostituire con i 6 dataset reali (home1T/home2T/
  /// homeAll e analoghi per away).
  List<int> _heatZonesForPeriod(List<int> baseZones, bool isHome, int filter) {
    if (filter == 0) return baseZones;
    final data = _mockAttackMomentum;
    final total = data.where((d) => d[1] == isHome).length;
    if (total == 0) return baseZones;
    final inPeriod = data
        .where((d) => d[1] == isHome && _inSelectedHalf(d[0] as int, filter))
        .length;
    final factor = inPeriod / total;
    return baseZones.map((z) => (z * factor).round()).toList();
  }

  Widget _buildAdvancedVisualization(bool isDark) {
    switch (_advancedStatsFilter) {
      case 'shotmap':
        // Determine which shots to show based on selector
        final List<ShotData> baseShots;
        final Color teamColor;
        if (_shotmapSelectedTeam == null) {
          // Tutti: show all shots, use primary color
          baseShots = [..._homeShotsData, ..._awayShotsData];
          teamColor = const Color(0xFF4CAF50);
        } else if (_shotmapSelectedTeam!) {
          baseShots = _homeShotsData;
          teamColor = const Color(0xFF2196F3);
        } else {
          baseShots = _awayShotsData;
          teamColor = const Color(0xFFE53935);
        }
        // Filtro periodo (Tutti/1°T/2°T) - usa ShotData.minute
        final List<ShotData> shotsToShow = baseShots
            .where((s) => _inSelectedHalf(s.minute, _shotmapTimeFilter))
            .toList();
        return Column(children: [
          _buildTeamSelector3(_shotmapSelectedTeam,
              (val) => setState(() => _shotmapSelectedTeam = val), isDark),
          _buildPeriodSelector(_shotmapTimeFilter,
              (val) => setState(() => _shotmapTimeFilter = val), isDark),
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: InteractiveShotMapWidget(
              shots: shotsToShow,
              teamColor: teamColor,
              isDark: isDark,
              onPlayerTap: (playerName) {
                _haptic.lightImpact();
                final isDk = Theme.of(context).brightness == Brightness.dark;
                final isHome = _homeShotsData.any((s) => s.playerName == playerName);
                _openPlayerStatsFromEvent(playerName, isHome, isDk);
              },
            ),
          )),
        ]);
      case 'passnetwork':
        return _buildPassesView(isDark);
      case 'attack':
        return Column(children: [
          _buildTeamSelector3(_advancedStatsShowHome,
              (val) => setState(() => _advancedStatsShowHome = val!), isDark,
              showTutti: false),
          _buildPeriodSelector(_attackTimeFilter,
              (val) => setState(() => _attackTimeFilter = val), isDark),
          Expanded(child: _buildAttackView(isDark)),
        ]);
      case 'heatmap':
        return _buildHeatmapView(isDark);
      case 'defensive':
        return InteractiveDefensiveWidget(
          homeActions: _homeDefensiveActions,
          awayActions: _awayDefensiveActions,
          homeStats: _homeDefensiveStats,
          awayStats: _awayDefensiveStats,
          homeTeamName: 'Lazio',
          awayTeamName: 'Milan',
          homeColor: const Color(0xFF4CAF50),
          awayColor: const Color(0xFF1565C0),
          isDark: isDark,
        );
      default:
        return Container();
    }
  }

  // ============================================================================
  // ✅ ATTACCO — Sezione offensiva stile SofaScore
  // Campo con heatmap concentrazione gioco + statistiche offensive comparative
  // ============================================================================
  Widget _buildAttackView(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : Colors.white;
    final fieldGreen = const Color(0xFF66BB6A);

    // ── Palette unificata Avanzate (= Difensiva) ──
    const homeColor = Color(0xFF4CAF50); // verde Material (Lazio)
    const awayColor = Color(0xFF1565C0); // blu scuro (Milan)
    final homeName = widget.match.homeTeamName;
    final awayName = widget.match.awayTeamName;

    // ══════ DERIVE ALL STATS FROM _mockAttackMomentum (single source of truth) ══════
    // Filtro periodo: minute e' in d[0]. Quando arriveranno dati API reali,
    // questa where() basta a far funzionare il selettore 1°T/2°T.
    final data = _mockAttackMomentum
        .where((d) => _inSelectedHalf(d[0] as int, _attackTimeFilter))
        .toList();
    final hAttacks = data.where((d) => d[1] == true).length;
    final aAttacks = data.where((d) => d[1] == false).length;
    final hDangerous =
        data.where((d) => d[1] == true && (d[2] as double) >= 0.6).length;
    final aDangerous =
        data.where((d) => d[1] == false && (d[2] as double) >= 0.6).length;

    // Derive other stats from events (also single source of truth)
    final allEvents = _generateDetailedMockEvents()
        .where((e) => _inSelectedHalf(e.minute, _attackTimeFilter))
        .toList();
    final hGoals =
        allEvents.where((e) => e.type == 'goal' && e.isHomeTeam).length;
    final aGoals =
        allEvents.where((e) => e.type == 'goal' && !e.isHomeTeam).length;
    // "Grandi occasioni realizzate" = goals
    // "Grandi occasioni mancate" = on_target shots (saved) = high xG shots that didn't go in
    final hOnTarget = allEvents
        .where((e) =>
            e.type == 'shot' &&
            e.isHomeTeam &&
            e.detail != null &&
            e.detail!.toLowerCase().contains('parato'))
        .length;
    final aOnTarget = allEvents
        .where((e) =>
            e.type == 'shot' &&
            !e.isHomeTeam &&
            e.detail != null &&
            e.detail!.toLowerCase().contains('parato'))
        .length;
    // Tocchi in area = proportional to dangerous attacks * factor
    final hTouches = (hDangerous * 1.5).round();
    final aTouches = (aDangerous * 1.2).round();
    // Falli avversari nel terzo offensivo = subset of opponent fouls
    final hOffFouls =
        allEvents.where((e) => e.type == 'foul' && !e.isHomeTeam).length ~/ 3;
    final aOffFouls =
        allEvents.where((e) => e.type == 'foul' && e.isHomeTeam).length ~/ 3;
    // Fuorigioco
    final hOffsides =
        allEvents.where((e) => e.type == 'offside' && e.isHomeTeam).length;
    final aOffsides =
        allEvents.where((e) => e.type == 'offside' && !e.isHomeTeam).length;

    final stats = [
      AttackStat(S.of(context)!.grandiOccasioniRealizzate, hGoals, aGoals, true),
      AttackStat(S.of(context)!.grandiOccasioniMancate, hOnTarget, aOnTarget, false),
      AttackStat(localizeShotData(context, 'Tocchi area avversaria'), hTouches, aTouches, true),
      AttackStat(
          localizeShotData(context, 'Falli avversari nel terzo offensivo'), hOffFouls, aOffFouls, true),
      AttackStat(tr(context, 'Fuorigioco'), hOffsides, aOffsides, false),
      AttackStat(localizeShotData(context, 'Attacchi pericolosi'), hDangerous, aDangerous, true),
      AttackStat(localizeShotData(context, 'Attacchi'), hAttacks, aAttacks, true),
    ];

    // ══════ CONCENTRATION ZONES from momentum (per team) ══════
    // 6 zones (2 rows x 3 cols): [defense, midfield, attack]
    // Zone intensity = proportion of attacks in that zone
    List<List<double>> _calcZones(bool isHome) {
      final teamData = data.where((d) => d[1] == isHome).toList();
      if (teamData.isEmpty)
        return [
          [0.2, 0.2, 0.2],
          [0.2, 0.2, 0.2]
        ];

      // Count attacks by intensity bucket
      int defCount = 0, midCount = 0, atkCount = 0;
      for (final d in teamData) {
        final intensity = d[2] as double;
        if (intensity < 0.4)
          defCount++;
        else if (intensity < 0.6)
          midCount++;
        else
          atkCount++;
      }
      final total = teamData.length.toDouble();
      final defR = defCount / total; // ~0.4
      final midR = midCount / total; // ~0.25
      final atkR = atkCount / total; // ~0.3

      // Wide range: defense=cold (0.05-0.25), midfield=warm (0.4-0.6), attack=hot (0.7-0.95)
      // Home attacks left→right: left=defense, center=midfield, right=attack
      if (isHome) {
        return [
          [0.05 + defR * 0.2, 0.35 + midR * 0.3, 0.70 + atkR * 0.25],
          [0.08 + defR * 0.15, 0.40 + midR * 0.25, 0.65 + atkR * 0.25],
        ];
      } else {
        // Away attacks right→left: right=defense, center=midfield, left=attack
        return [
          [0.70 + atkR * 0.25, 0.35 + midR * 0.3, 0.05 + defR * 0.2],
          [0.65 + atkR * 0.25, 0.40 + midR * 0.25, 0.08 + defR * 0.15],
        ];
      }
    }

    final selectedZones = _calcZones(_advancedStatsShowHome);
    final selectedColor = _advancedStatsShowHome ? homeColor : awayColor;
    final selectedName = _advancedStatsShowHome ? homeName : awayName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── TITOLO SEZIONE (centrato) ──
        Center(
          child: Text(tr(context, 'Concentrazione attacchi'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
        ),
        const SizedBox(height: 10),
        // ── PITCH HEATMAP ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
                aspectRatio: 1.85,
                child: CustomPaint(
                    painter: AttackHeatmapPainter(
                  zones: selectedZones,
                  isHome: _advancedStatsShowHome,
                  isDark: isDark,
                )),
              ),
          ),
        ),
        const SizedBox(height: 10),

        // ── LEGENDA GRADIENT 5 LIVELLI (stile SofaScore-pro) ──
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Barra gradient con tutti e 5 i colori della scala
            Container(
              width: 260,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDCEDC8), // very light sage (bassa)
                    Color(0xFFC5E1A5), // light lime-green
                    Color(0xFFA5D6A7), // medium-light
                    Color(0xFF81C784), // medium green
                    Color(0xFF66BB6A), // bright medium (alta)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Labels ai bordi
            SizedBox(
              width: 260,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localizeShotData(context, 'Più bassa concentrazione'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                  Text(localizeShotData(context, 'Più alta concentrazione'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // ── OFFENSIVE STATS ──
        ...stats.map((stat) => _buildAttackStatBar(
              stat.label,
              stat.homeVal,
              stat.awayVal,
              homeColor,
              awayColor,
              tx,
              lb,
              cardBg,
              isDark,
              isHigherBetter: stat.higherIsBetter,
            )),
      ]),
    );
  }

  Widget _buildAttackStatBar(
      String label,
      int homeVal,
      int awayVal,
      Color homeColor,
      Color awayColor,
      Color tx,
      Color lb,
      Color cardBg,
      bool isDark,
      {bool isHigherBetter = true}) {
    final maxVal = (homeVal > awayVal ? homeVal : awayVal).clamp(1, 999);
    final homeRatio = homeVal / maxVal;
    final awayRatio = awayVal / maxVal;
    // Il numero più alto ha SEMPRE la barra evidenziata (colore pieno)
    // Il numero più basso ha la barra sbiadita
    final homeHigher = homeVal >= awayVal;
    final awayHigher = awayVal > homeVal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(children: [
        // Values + label
        Row(children: [
          SizedBox(
              width: 36,
              child: Text('$homeVal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: homeHigher ? homeColor : lb),
                  textAlign: TextAlign.left)),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: tx),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 36,
              child: Text('$awayVal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: awayHigher ? awayColor : lb),
                  textAlign: TextAlign.right)),
        ]),
        const SizedBox(height: 6),
        // Bars
        Row(children: [
          // Home bar (right-aligned, grows left)
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
            return Stack(clipBehavior: Clip.none, children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3))),
              Positioned(
                right: 0,
                child: Container(
                  height: 6,
                  width: constraints.maxWidth * homeRatio,
                  decoration: BoxDecoration(
                      color:
                          homeHigher ? homeColor : homeColor.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ]);
          })),
          const SizedBox(width: 4),
          // Away bar (left-aligned, grows right)
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
            return Stack(clipBehavior: Clip.none, children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3))),
              Container(
                height: 6,
                width: constraints.maxWidth * awayRatio,
                decoration: BoxDecoration(
                    color: awayHigher ? awayColor : awayColor.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ]);
          })),
        ]),
      ]),
    );
  }

  // ============================================================================
  // ✅ PASSAGGI — v3 (3 stati: comparativo / home / away)
  // Default: vista comparativa entrambe le squadre
  // Click squadra: vista dettaglio singola con campo + donut + metriche
  // ============================================================================
  Widget _buildPassesView(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F0);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildPeriodSelector(_passesTimeFilter,
            (val) => setState(() => _passesTimeFilter = val), isDark),
        const SizedBox(height: 8),
        // Selettore squadra (refactored Patch 8: usa _buildTeamSelector3
        // riusabile per coerenza con tutte le altre tab)
        _buildTeamSelector3(_passesSelectedTeam,
            (val) => setState(() => _passesSelectedTeam = val), isDark),
        const SizedBox(height: 14),

        // Mostra vista comparativa o vista singola squadra
        if (_passesSelectedTeam == null)
          _passesComparativeView(
              isDark, tx, lb, cardBg, cardBorder, homeColor, awayColor)
        else
          _passesTeamView(
              _passesSelectedTeam!, isDark, tx, lb, cardBg, cardBorder),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // VISTA COMPARATIVA (default — entrambe le squadre, barre + cerchi)
  // ═══════════════════════════════════════════════════════════════
  Widget _passesComparativeView(bool isDark, Color tx, Color lb, Color cardBg,
      Color cardBorder, Color homeColor, Color awayColor) {
    // Percentuali generali (entrambe le squadre combinate)
    final genLeftPct = (_generalZoneLeft / _generalZoneTotal * 100).round();
    final genCenterPct = (_generalZoneCenter / _generalZoneTotal * 100).round();
    final genRightPct = (_generalZoneRight / _generalZoneTotal * 100).round();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Campo generale — distribuzione passaggi partita
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Distribuzione Passaggi'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 4),
          Text('$_generalZoneTotal ${tr(context, 'passaggi totali nella partita')}',
              style: TextStyle(fontSize: 11, color: lb)),
          const SizedBox(height: 12),
          // ── TITOLO SEZIONE (centrato) ──
          Center(
            child: Text(tr(context, 'Distribuzione passaggi per zona'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ),
          const SizedBox(height: 10),
          _generalFieldHeatmap(genLeftPct, genCenterPct, genRightPct, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Header con totali entrambe le squadre
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Precisione Passaggi'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _miniAccuracyBlock(
                    _homePassesCompleted, _homePassesTotal, homeColor, tx, lb)),
            Container(width: 1, height: 70, color: cardBorder),
            Expanded(
                child: _miniAccuracyBlock(
                    _awayPassesCompleted, _awayPassesTotal, awayColor, tx, lb)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Barre comparative
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          _passComparisonBarPremium(S.of(context)!.passaggiPrecisilabel, _homePassesCompleted,
              _awayPassesCompleted, homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(tr(context, 'Rimesse laterali'), _homeThrowIns,
              _awayThrowIns, homeColor, awayColor, tx, lb, isDark),
          SizedBox(height: 22),
          _passComparisonBarPremium(
              tr(context, 'Ingressi terzo offensivo'),
              _homeFinalThirdEntries,
              _awayFinalThirdEntries,
              homeColor,
              awayColor,
              tx,
              lb,
              isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(S.of(context)!.passaggiChiave, _homeKeyPasses,
              _awayKeyPasses, homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 22),
          _passComparisonBarPremium(
              S.of(context)!.passaggiProgressivi,
              _homeProgressivePasses,
              _awayProgressivePasses,
              homeColor,
              awayColor,
              tx,
              lb,
              isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Cerchi accuratezza per tipo
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Accuratezza per Tipo'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passCircularRow(
              S.of(context)!.passaggiTerzoOffensivo,
              _homeFTPasses,
              _homeFTTotal,
              _awayFTPasses,
              _awayFTTotal,
              homeColor,
              awayColor,
              tx,
              lb),
          const SizedBox(height: 24),
          _passCircularRow(
              localizeShotData(context, 'Palle lunghe'),
              _homeLongBallsOk,
              _homeLongBallsTotal,
              _awayLongBallsOk,
              _awayLongBallsTotal,
              homeColor,
              awayColor,
              tx,
              lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Cross'), _homeCrossOk, _homeCrossTotal, _awayCrossOk,
              _awayCrossTotal, homeColor, awayColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  // Campo generale — percentuali combinate entrambe le squadre
  Widget _generalFieldHeatmap(
      int leftPct, int centerPct, int rightPct, bool isDark) {
    final maxPct =
        [leftPct, centerPct, rightPct].reduce((a, b) => a > b ? a : b);
    double zoneOpacity(int val) => 0.40 + (val / maxPct) * 0.55;

    return AspectRatio(
      aspectRatio: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          // Zone sfumate VERDI (palette unificata Avanzate)
          Row(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(leftPct)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(leftPct) - 0.10)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(centerPct)),
                const Color(0xFF2E7D32)
                    .withOpacity(zoneOpacity(centerPct) + 0.05)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(rightPct)),
                const Color(0xFF66BB6A)
                    .withOpacity(zoneOpacity(rightPct) - 0.10)
              ],
            )))),
          ]),
          // Linee campo
          CustomPaint(
              painter: PassFieldLinePainter(isDark: isDark),
              size: Size.infinite),
          // Badge percentuali (non tappabili in vista generale)
          Row(children: [
            Expanded(child: Center(child: _generalZoneBadge('$leftPct%'))),
            Expanded(child: Center(child: _generalZoneBadge('$centerPct%'))),
            Expanded(child: Center(child: _generalZoneBadge('$rightPct%'))),
          ]),
        ]),
      ),
    );
  }

  Widget _generalZoneBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2),
        ],
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A))),
    );
  }

  Widget _miniAccuracyBlock(
      int completed, int total, Color color, Color tx, Color lb) {
    final pct = total > 0 ? (completed / total * 100).round() : 0;
    return Column(children: [
      SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                )),
            Text('$pct%',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ])),
      const SizedBox(height: 10),
      RichText(
          text: TextSpan(children: [
        TextSpan(
            text: '$completed',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        TextSpan(
            text: ' / $total',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: lb)),
      ])),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // VISTA SINGOLA SQUADRA (campo + metriche + donut)
  // ═══════════════════════════════════════════════════════════════
  Widget _passesTeamView(bool isHome, bool isDark, Color tx, Color lb,
      Color cardBg, Color cardBorder) {
    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);
    final teamColor = isHome ? homeColor : awayColor;
    final oppColor = isHome ? awayColor : homeColor;

    final totalPasses = isHome ? _homePassesTotal : _awayPassesTotal;
    final accPasses = isHome ? _homePassesCompleted : _awayPassesCompleted;
    final accPct =
        totalPasses > 0 ? (accPasses / totalPasses * 100).round() : 0;
    final passLeft = isHome ? _homePassLeft : _awayPassLeft;
    final passCenter = isHome ? _homePassCenter : _awayPassCenter;
    final passRight = isHome ? _homePassRight : _awayPassRight;
    final keyPasses = isHome ? _homeKeyPasses : _awayKeyPasses;
    final oppKeyPasses = isHome ? _awayKeyPasses : _homeKeyPasses;
    final progressivePasses =
        isHome ? _homeProgressivePasses : _awayProgressivePasses;
    final oppProgressivePasses =
        isHome ? _awayProgressivePasses : _homeProgressivePasses;
    final shortP = isHome ? _homeShortPasses : _awayShortPasses;
    final mediumP = isHome ? _homeMediumPasses : _awayMediumPasses;
    final longP = isHome ? _homeLongPasses : _awayLongPasses;
    final ftP = isHome ? _homeFTPasses : _awayFTPasses;
    final ftT = isHome ? _homeFTTotal : _awayFTTotal;
    final oppFtP = isHome ? _awayFTPasses : _homeFTPasses;
    final oppFtT = isHome ? _awayFTTotal : _homeFTTotal;
    final lbOk = isHome ? _homeLongBallsOk : _awayLongBallsOk;
    final lbTot = isHome ? _homeLongBallsTotal : _awayLongBallsTotal;
    final oppLbOk = isHome ? _awayLongBallsOk : _homeLongBallsOk;
    final oppLbTot = isHome ? _awayLongBallsTotal : _homeLongBallsTotal;
    final crOk = isHome ? _homeCrossOk : _awayCrossOk;
    final crTot = isHome ? _homeCrossTotal : _awayCrossTotal;
    final oppCrOk = isHome ? _awayCrossOk : _homeCrossOk;
    final oppCrTot = isHome ? _awayCrossTotal : _homeCrossTotal;
    final zLeftOk = isHome ? _homePassLeftOk : _awayPassLeftOk;
    final zLeftTot = isHome ? _homePassLeftTotal : _awayPassLeftTotal;
    final zCenterOk = isHome ? _homePassCenterOk : _awayPassCenterOk;
    final zCenterTot = isHome ? _homePassCenterTotal : _awayPassCenterTotal;
    final zRightOk = isHome ? _homePassRightOk : _awayPassRightOk;
    final zRightTot = isHome ? _homePassRightTotal : _awayPassRightTotal;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header accuratezza grande
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Row(children: [
          SizedBox(
              width: 72,
              height: 72,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: accPct / 100,
                      strokeWidth: 6,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                      strokeCap: StrokeCap.round,
                    )),
                Text('$accPct%',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: teamColor)),
              ])),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(tr(context, 'Precisione Passaggi'),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                const SizedBox(height: 4),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: '$accPasses',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: teamColor)),
                  TextSpan(
                      text: ' / $totalPasses',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: lb)),
                ])),
                const SizedBox(height: 2),
                Text(tr(context, 'passaggi completati'),
                    style: TextStyle(fontSize: 12, color: lb)),
              ])),
        ]),
      ),
      const SizedBox(height: 14),

      // Titolo zone (allineato alla vista Tutti)
      Center(
        child: Text(tr(context, 'Distribuzione passaggi per zona'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
      ),
      const SizedBox(height: 12),
      // Campo minimal con zone + freccia orientamento
      Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: _passFieldMinimal(
            passLeft,
            passCenter,
            passRight,
            zLeftOk,
            zLeftTot,
            zCenterOk,
            zCenterTot,
            zRightOk,
            zRightTot,
            isHome,
            teamColor,
            isDark),
      ),
      const SizedBox(height: 14),

      // Passaggi chiave + progressivi
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          _passMetricRow(Icons.key, S.of(context)!.passaggiChiave, keyPasses, oppKeyPasses,
              teamColor, oppColor, tx, lb, isDark,
              tooltip: "Passaggi che creano un'occasione da gol"),
          const SizedBox(height: 20),
          _passMetricRow(
              Icons.trending_up,
              S.of(context)!.passaggiProgressivi,
              progressivePasses,
              oppProgressivePasses,
              teamColor,
              oppColor,
              tx,
              lb,
              isDark,
              tooltip:
                  S.of(context)!.passaggiAvanzano),
        ]),
      ),
      const SizedBox(height: 14),

      // Donut chart distribuzione lunghezza
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Distribuzione Lunghezza'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passDonutChart(
              shortP, mediumP, longP, totalPasses, teamColor, isDark, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),

      // Cerchi accuratezza per tipo
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(tr(context, 'Accuratezza per Tipo'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 20),
          _passCircularRow(S.of(context)!.passaggiTerzoOffensivo, ftP, ftT, oppFtP,
              oppFtT, teamColor, oppColor, tx, lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Palle lunghe'), lbOk, lbTot, oppLbOk, oppLbTot,
              teamColor, oppColor, tx, lb),
          const SizedBox(height: 24),
          _passCircularRow(localizeShotData(context, 'Cross'), crOk, crTot, oppCrOk, oppCrTot, teamColor,
              oppColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMPO MINIMAL — zone %, freccia orientamento offensivo
  // ═══════════════════════════════════════════════════════════════
  Widget _passFieldMinimal(
    int left,
    int center,
    int right,
    int zLOk,
    int zLTot,
    int zCOk,
    int zCTot,
    int zROk,
    int zRTot,
    bool isHome,
    Color teamColor,
    bool isDark,
  ) {
    final maxPct = [left, center, right].reduce((a, b) => a > b ? a : b);
    double zoneOpacity(int val) => 0.40 + (val / maxPct) * 0.55;

    return AspectRatio(
      aspectRatio: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          // Zone sfumate
          // Zone sfumate VERDI (palette unificata Avanzate)
          Row(children: [
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(left)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(left) - 0.10)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(center)),
                const Color(0xFF2E7D32).withOpacity(zoneOpacity(center) + 0.05)
              ],
            )))),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(zoneOpacity(right)),
                const Color(0xFF66BB6A).withOpacity(zoneOpacity(right) - 0.10)
              ],
            )))),
          ]),
          // Linee campo
          CustomPaint(
              painter: PassFieldLinePainter(isDark: isDark),
              size: Size.infinite),
          // Orientamento offensivo (in basso)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!isHome)
                Icon(Icons.arrow_back_rounded,
                    size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  isHome
                      ? 'Attacca verso destra →'
                      : '← Attacca verso sinistra',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7)),
                ),
              ),
              const SizedBox(width: 4),
              if (isHome)
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Colors.white.withOpacity(0.5)),
            ]),
          ),
          // Badge percentuali tappabili
          Row(children: [
            Expanded(
                child: _tappableZone(
                    'Sinistra', left, zLOk, zLTot, teamColor, isDark)),
            Expanded(
                child: _tappableZone(
                    'Centro', center, zCOk, zCTot, teamColor, isDark)),
            Expanded(
                child: _tappableZone(
                    'Destra', right, zROk, zRTot, teamColor, isDark)),
          ]),
        ]),
      ),
    );
  }

  Widget _tappableZone(String zoneName, int pct, int ok, int total,
      Color teamColor, bool isDark) {
    final acc = total > 0 ? (ok / total * 100).round() : 0;
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        _showZoneDetailPopup(zoneName, pct, ok, total, acc, teamColor, isDark);
      },
      child: Container(
          color: Colors.transparent,
          child: Center(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 2)
                ]),
            child: Text('$pct%',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A))),
          ))),
    );
  }

  void _showZoneDetailPopup(String zoneName, int pct, int ok, int total,
      int acc, Color teamColor, bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.location_on, color: teamColor, size: 22)),
                const SizedBox(width: 12),
                Text('${tr(context, 'Zona')} $zoneName',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                _zoneDetailRow(tr(context, 'Distribuzione'), '$pct%',
                    Icons.pie_chart_outline, teamColor, isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(S.of(context)!.passaggiTotaliLabel, '$total', Icons.swap_calls,
                    teamColor, isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(tr(context, 'Completati'), '$ok', Icons.check_circle_outline,
                    const Color(0xFF4CAF50), isDark),
                const SizedBox(height: 14),
                _zoneDetailRow(
                    'Accuratezza',
                    '$acc%',
                    Icons.gps_fixed,
                    acc >= 80
                        ? const Color(0xFF4CAF50)
                        : acc >= 70
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFF44336),
                    isDark),
                const SizedBox(height: 16),
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                        height: 10,
                        child: Stack(children: [
                          Container(color: Colors.grey.withOpacity(0.12)),
                          FractionallySizedBox(
                              widthFactor: acc / 100,
                              child: Container(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        teamColor,
                                        teamColor.withOpacity(0.7)
                                      ]),
                                      borderRadius: BorderRadius.circular(6)))),
                        ]))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr(context, 'Chiudi'),
                        style: TextStyle(
                            color: teamColor, fontWeight: FontWeight.w700)))
              ],
            ));
  }

  Widget _zoneDetailRow(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // METRIC ROW — passaggi chiave/progressivi
  // ═══════════════════════════════════════════════════════════════
  Widget _passMetricRow(IconData icon, String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb, bool isDark,
      {String? tooltip}) {
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Expanded(
          child: Row(children: [
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
              onTap: () => _showTooltip(label, tooltip, isDark),
              child: Icon(Icons.info_outline, size: 14, color: lb))
        ],
      ])),
      const SizedBox(width: 8),
      Text(value.toString(),
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(width: 6),
      if (!isDraw)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
              color: (isWinning
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(isWinning ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: isWinning
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336)),
        ),
      const SizedBox(width: 4),
      Text('vs ${oppValue.toString()}',
          style: TextStyle(fontSize: 12, color: lb)),
    ]);
  }

  void _showTooltip(String title, String description, bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              content: Text(description,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'))
              ],
            ));
  }

  // ═══════════════════════════════════════════════════════════════
  // BARRA COMPARATIVA PREMIUM
  // ═══════════════════════════════════════════════════════════════
  Widget _passComparisonBarPremium(String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb, bool isDark) {
    final total = value + oppValue;
    final pct = total > 0 ? value / total : 0.5;
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        SizedBox(
            width: 44,
            child: Text(value.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isWinning || isDraw ? tx : lb))),
        const SizedBox(width: 8),
        Expanded(
            child: SizedBox(
                height: 10,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(children: [
                      Expanded(
                          flex: (pct * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [color, color.withOpacity(0.75)]),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      bottomLeft: Radius.circular(5))))),
                      Container(
                          width: 2,
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white),
                      Expanded(
                          flex: ((1 - pct) * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    oppColor.withOpacity(0.35),
                                    oppColor.withOpacity(0.25)
                                  ]),
                                  borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(5),
                                      bottomRight: Radius.circular(5))))),
                    ])))),
        const SizedBox(width: 8),
        SizedBox(
            width: 44,
            child: Text(oppValue.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: !isWinning && !isDraw ? tx : lb),
                textAlign: TextAlign.right)),
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // DONUT CHART
  // ═══════════════════════════════════════════════════════════════
  Widget _passDonutChart(int shortP, int mediumP, int longP, int total,
      Color teamColor, bool isDark, Color tx, Color lb) {
    final shortPct = total > 0 ? (shortP / total * 100).round() : 0;
    final mediumPct = total > 0 ? (mediumP / total * 100).round() : 0;
    final longPct = total > 0 ? (longP / total * 100).round() : 0;
    const shortColor = Color(0xFF4CAF50);
    const mediumColor = Color(0xFFFF9800);
    const longColor = Color(0xFFE53935);
    return Row(children: [
      SizedBox(
          width: 120,
          height: 120,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                    painter: DonutChartPainter(segments: [
                  DonutSegment(value: shortP.toDouble(), color: shortColor),
                  DonutSegment(value: mediumP.toDouble(), color: mediumColor),
                  DonutSegment(value: longP.toDouble(), color: longColor)
                ], strokeWidth: 14, isDark: isDark))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$total',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: tx)),
              Text(tr(context, 'totali'), style: TextStyle(fontSize: 10, color: lb)),
            ]),
          ])),
      const SizedBox(width: 24),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _donutLegendItem(tr(context, 'Corti (<15m)'), shortP, shortPct, shortColor, tx, lb),
        const SizedBox(height: 14),
        _donutLegendItem(
            tr(context, 'Medi (15-30m)'), mediumP, mediumPct, mediumColor, tx, lb),
        const SizedBox(height: 14),
        _donutLegendItem(tr(context, 'Lunghi (>30m)'), longP, longPct, longColor, tx, lb),
      ])),
    ]);
  }

  Widget _donutLegendItem(
      String label, int count, int pct, Color color, Color tx, Color lb) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
        const SizedBox(height: 2),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: '$count',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
          TextSpan(
              text: '  $pct%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ])),
      ])),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // CERCHI PERCENTUALE
  // ═══════════════════════════════════════════════════════════════
  Widget _passCircularRow(String label, int ok, int total, int oppOk,
      int oppTotal, Color color, Color oppColor, Color tx, Color lb) {
    final pct = total > 0 ? (ok / total * 100).round() : 0;
    final oppPct = oppTotal > 0 ? (oppOk / oppTotal * 100).round() : 0;
    return Row(children: [
      SizedBox(
          width: 52,
          child: Text('$ok/$total',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: tx))),
      _circularProgress(pct / 100, '$pct%', color, 62),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb),
              textAlign: TextAlign.center)),
      const SizedBox(width: 10),
      _circularProgress(oppPct / 100, '$oppPct%', oppColor, 62),
      SizedBox(
          width: 52,
          child: Text('$oppOk/$oppTotal',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: tx),
              textAlign: TextAlign.right)),
    ]);
  }

  Widget _circularProgress(
      double progress, String label, Color color, double size) {
    return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5.5,
                  backgroundColor: Colors.grey.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round)),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]));
  }

  // ============================================================================
  // ✅ HEATMAP — v2 (3 stati: combinata / home / away)
  // ============================================================================
  Widget _buildHeatmapView(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F0);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ═══ SELETTORE SQUADRA (3 tab) ═══
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                setState(() => _heatmapSelectedTeam = null);
                _haptic.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _heatmapSelectedTeam == null
                      ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _heatmapSelectedTeam == null
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(localizeShotData(context, 'Tutti'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: _heatmapSelectedTeam == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _heatmapSelectedTeam == null ? tx : lb)),
              ),
            )),
            const SizedBox(width: 4),
            Expanded(
                child: GestureDetector(
              onTap: () {
                setState(() => _heatmapSelectedTeam = true);
                _haptic.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _heatmapSelectedTeam == true
                      ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _heatmapSelectedTeam == true
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(widget.match.homeTeamName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: _heatmapSelectedTeam == true
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _heatmapSelectedTeam == true ? homeColor : lb)),
              ),
            )),
            const SizedBox(width: 4),
            Expanded(
                child: GestureDetector(
              onTap: () {
                setState(() => _heatmapSelectedTeam = false);
                _haptic.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _heatmapSelectedTeam == false
                      ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _heatmapSelectedTeam == false
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(widget.match.awayTeamName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: _heatmapSelectedTeam == false
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _heatmapSelectedTeam == false ? awayColor : lb)),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 10),

        // ═══ FILTRO TEMPO ═══
        Row(children: [
          _heatmapTimeChip(localizeShotData(context, 'Tutti'), 0, isDark, tx, lb),
          const SizedBox(width: 8),
          _heatmapTimeChip(tr(context, '1° Tempo'), 1, isDark, tx, lb),
          const SizedBox(width: 8),
          _heatmapTimeChip(tr(context, '2° Tempo'), 2, isDark, tx, lb),
        ]),
        const SizedBox(height: 14),

        // ── TITOLO SEZIONE (centrato) ──
        Center(
          child: Text(tr(context, 'Mappa di calore - Possesso'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
        ),
        const SizedBox(height: 10),
        // ═══ CAMPO HEATMAP ═══
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: AnimatedBuilder(
                animation: _advancedStatsAnimationController,
                builder: (context, child) {
                  final animVal = _advancedStatsAnimationController.value;
                  if (_heatmapSelectedTeam == null) {
                    // Vista combinata — entrambe le squadre sovrapposte
                    return CustomPaint(
                      painter: CombinedHeatmapPainter(
                        homeZones: _heatZonesForPeriod(
                            _homeHeatZones, true, _heatmapTimeFilter),
                        awayZones: _heatZonesForPeriod(
                            _awayHeatZones, false, _heatmapTimeFilter),
                        gridCols: _heatGridCols,
                        gridRows: _heatGridRows,
                        isDark: isDark,
                        animationValue: animVal,
                      ),
                      child: Container(),
                    );
                  } else {
                    // Patch 7: zone filtrate per periodo (1°T / 2°T / tutti)
                    final homeZonesFiltered = _heatZonesForPeriod(
                        _homeHeatZones, true, _heatmapTimeFilter);
                    final awayZonesFiltered = _heatZonesForPeriod(
                        _awayHeatZones, false, _heatmapTimeFilter);
                    final zones = _heatmapSelectedTeam!
                        ? homeZonesFiltered
                        : awayZonesFiltered;
                    final isHome = _heatmapSelectedTeam!;
                    // Riferimento globale: il max tra TUTTE le zone di ENTRAMBE le squadre (filtrate)
                    // → la squadra con meno possesso avrà colori più freddi
                    final allZones = [...homeZonesFiltered, ...awayZonesFiltered];
                    final globalMax = allZones.reduce((a, b) => a > b ? a : b);
                    return CustomPaint(
                      painter: SingleTeamHeatmapPainter(
                        zones: zones,
                        isHome: isHome,
                        gridCols: _heatGridCols,
                        gridRows: _heatGridRows,
                        isDark: isDark,
                        animationValue: animVal,
                        globalRefMax: globalMax,
                      ),
                      child: Container(),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ═══ LEGENDA GRADIENTE ═══
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr(context, 'Bassa'), style: TextStyle(fontSize: 11, color: lb)),
            const SizedBox(width: 8),
            Container(
              width: 160,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [
                  Color(0xFF81C784),
                  Color(0xFFD4E157),
                  Color(0xFFFFEE58),
                  Color(0xFFFFB300),
                  Color(0xFFFF9800),
                  Color(0xFFFF5722),
                  Color(0xFFF44336),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Text(tr(context, 'Alta'), style: TextStyle(fontSize: 11, color: lb)),
          ]),
        ),
        const SizedBox(height: 8),

        // ═══ STATS ═══
        if (_heatmapSelectedTeam == null)
          _heatmapComparativeStats(
              isDark, tx, lb, cardBg, cardBorder, homeColor, awayColor)
        else
          _heatmapTeamStats(
              _heatmapSelectedTeam!, isDark, tx, lb, cardBg, cardBorder),
      ]),
    );
  }

  Widget _heatmapTimeChip(
      String label, int value, bool isDark, Color tx, Color lb) {
    final active = _heatmapTimeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _heatmapTimeFilter = value);
        _haptic.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (isDark
                  ? Colors.white.withOpacity(0.12)
                  : const Color(0xFF424242).withOpacity(0.08))
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? (isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF424242).withOpacity(0.3))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? (isDark ? Colors.white : const Color(0xFF424242))
                  : lb,
            )),
      ),
    );
  }

  // ═══ HEATMAP STATS — VISTA COMPARATIVA ═══
  Widget _heatmapComparativeStats(bool isDark, Color tx, Color lb, Color cardBg,
      Color cardBorder, Color homeColor, Color awayColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Possesso palla
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(S.of(context)!.possessoPalla,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 16),
          // Barra grande possesso — font uniforme
          Row(children: [
            Text('$_homePossession%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: homeColor)),
            const SizedBox(width: 10),
            Expanded(
                child: SizedBox(
                    height: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(children: [
                        Expanded(
                            flex: _homePossession,
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              homeColor,
                              homeColor.withOpacity(0.75)
                            ])))),
                        Container(
                            width: 2,
                            color: isDark
                                ? const Color(0xFF1A1A1A)
                                : Colors.white),
                        Expanded(
                            flex: _awayPossession,
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              awayColor.withOpacity(0.4),
                              awayColor.withOpacity(0.3)
                            ])))),
                      ]),
                    ))),
            const SizedBox(width: 10),
            Text('$_awayPossession%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: awayColor)),
          ]),
          const SizedBox(height: 18),
          _heatmapCompBar(S.of(context)!.difesaSection, _homePossDefense, _awayPossDefense,
              homeColor, awayColor, tx, lb, isDark),
          SizedBox(height: 14),
          _heatmapCompBar(tr(context, 'Centrocampo'), _homePossMidfield, _awayPossMidfield,
              homeColor, awayColor, tx, lb, isDark),
          const SizedBox(height: 14),
          _heatmapCompBar(S.of(context)!.attaccoSection, _homePossAttack, _awayPossAttack,
              homeColor, awayColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // Territorio
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(localizeShotData(context, 'Dominio Territoriale'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          const SizedBox(height: 4),
          Text(localizeShotData(context, '% azioni nella metà campo avversaria'),
              style: TextStyle(fontSize: 11, color: lb)),
          const SizedBox(height: 14),
          _heatmapCompBar(tr(context, 'Territorio'), _homeTerritory, _awayTerritory,
              homeColor, awayColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  // Barra comparativa con font uniforme per heatmap stats
  Widget _heatmapCompBar(String label, int value, int oppValue, Color color,
      Color oppColor, Color tx, Color lb, bool isDark) {
    final total = value + oppValue;
    final pct = total > 0 ? value / total : 0.5;
    return Column(children: [
      Text(label,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
      const SizedBox(height: 8),
      Row(children: [
        SizedBox(
            width: 36,
            child: Text('$value',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx))),
        const SizedBox(width: 8),
        Expanded(
            child: SizedBox(
                height: 10,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(children: [
                      Expanded(
                          flex: (pct * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                            color,
                            color.withOpacity(0.75)
                          ])))),
                      Container(
                          width: 2,
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white),
                      Expanded(
                          flex: ((1 - pct) * 1000).round(),
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                            oppColor.withOpacity(0.35),
                            oppColor.withOpacity(0.25)
                          ])))),
                    ])))),
        const SizedBox(width: 8),
        SizedBox(
            width: 36,
            child: Text('$oppValue',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                textAlign: TextAlign.right)),
      ]),
    ]);
  }

  // ═══ HEATMAP STATS — VISTA SINGOLA SQUADRA ═══
  Widget _heatmapTeamStats(bool isHome, bool isDark, Color tx, Color lb,
      Color cardBg, Color cardBorder) {
    const homeColor = Color(0xFF1B5E20);
    const awayColor = Color(0xFF1565C0);
    final teamColor = isHome ? homeColor : awayColor;
    final oppColor = isHome ? awayColor : homeColor;
    final possession = isHome ? _homePossession : _awayPossession;
    final oppPossession = isHome ? _awayPossession : _homePossession;
    final territory = isHome ? _homeTerritory : _awayTerritory;
    final oppTerritory = isHome ? _awayTerritory : _homeTerritory;
    final possDefense = isHome ? _homePossDefense : _awayPossDefense;
    final possMidfield = isHome ? _homePossMidfield : _awayPossMidfield;
    final possAttack = isHome ? _homePossAttack : _awayPossAttack;
    final zones = isHome ? _homeHeatZones : _awayHeatZones;
    // Dati aggiuntivi centralizzati
    final totalPasses = isHome ? _homePassesTotal : _awayPassesTotal;
    final accPasses = isHome ? _homePassesCompleted : _awayPassesCompleted;
    final accPct =
        totalPasses > 0 ? (accPasses / totalPasses * 100).round() : 0;
    final corners = isHome ? _homeCorners : _awayCorners;
    final oppCorners = isHome ? _awayCorners : _homeCorners;
    final ftEntries = isHome ? _homeFinalThirdEntries : _awayFinalThirdEntries;
    final oppFtEntries =
        isHome ? _awayFinalThirdEntries : _homeFinalThirdEntries;
    final shots = isHome ? _homeShotsTotal : _awayShotsTotal;
    final oppShots = isHome ? _awayShotsTotal : _homeShotsTotal;
    final shotsOnTarget = isHome ? _homeShotsOnTarget : _awayShotsOnTarget;
    final oppShotsOnTarget = isHome ? _awayShotsOnTarget : _homeShotsOnTarget;
    // Zona più attiva
    final maxZone = zones.reduce((a, b) => a > b ? a : b);
    final maxIdx = zones.indexOf(maxZone).clamp(0, 19);
    const zoneNames = [
      'Difesa SX',
      'Difesa CSX',
      'Difesa CDX',
      'Difesa DX',
      'Centrodif. SX',
      'Centrodif. Centro-SX',
      'Centrodif. Centro-DX',
      'Centrodif. DX',
      'Centrocampo SX',
      'Centrocampo CSX',
      'Centrocampo CDX',
      'Centrocampo DX',
      'Centroatt. SX',
      'Centroatt. CSX',
      'Centroatt. CDX',
      'Centroatt. DX',
      'Attacco SX',
      'Attacco CSX',
      'Attacco CDX',
      'Attacco DX',
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ─── Card principale: possesso + territorio ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          // Due cerchi grandi: possesso e territorio
          Row(children: [
            Expanded(
                child: Column(children: [
              Text(S.of(context)!.possessoSection,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
              const SizedBox(height: 10),
              _circularProgress(
                  possession / 100, '$possession%', teamColor, 62),
              const SizedBox(height: 6),
              Text('vs $oppPossession%',
                  style: TextStyle(fontSize: 12, color: lb)),
            ])),
            Container(
                width: 1,
                height: 80,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04)),
            Expanded(
                child: Column(children: [
              Text(localizeShotData(context, 'Territorio'),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
              const SizedBox(height: 10),
              _circularProgress(territory / 100, '$territory%', teamColor, 62),
              const SizedBox(height: 6),
              Text('vs $oppTerritory%',
                  style: TextStyle(fontSize: 12, color: lb)),
            ])),
          ]),
          const SizedBox(height: 20),
          // Possesso per terzo
          Text(tr(context, 'Possesso per zona'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
          const SizedBox(height: 12),
          _heatmapZoneBar(S.of(context)!.difesaSection, possDefense, 50, teamColor, tx, lb, isDark),
          SizedBox(height: 10),
          _heatmapZoneBar(
              'Centrocampo', possMidfield, 50, teamColor, tx, lb, isDark),
          const SizedBox(height: 10),
          _heatmapZoneBar(S.of(context)!.attaccoSection, possAttack, 50, teamColor, tx, lb, isDark),
        ]),
      ),
      const SizedBox(height: 14),

      // ─── Zona più attiva ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: teamColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.whatshot, color: teamColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(tr(context, 'Zona più attiva'),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                const SizedBox(height: 4),
                Text(zoneNames[maxIdx],
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
                Text('$maxZone ${tr(context, 'tocchi')}',
                    style: TextStyle(
                        fontSize: 12,
                        color: teamColor,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      ),
      const SizedBox(height: 14),

      // ─── Metriche comparative vs avversario ───
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder)),
        child: Column(children: [
          Text(localizeShotData(context, 'Confronto con avversario'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          SizedBox(height: 18),
          _heatmapMetricVs(Icons.sports_soccer, localizeShotData(context, 'Tiri totali'), shots, oppShots,
              teamColor, oppColor, tx, lb),
          SizedBox(height: 16),
          _heatmapMetricVs(Icons.gps_fixed, localizeShotData(context, 'Tiri in porta'), shotsOnTarget,
              oppShotsOnTarget, teamColor, oppColor, tx, lb),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.swap_calls, '${S.of(context)!.passaggiSection} ($accPct%)', accPasses,
              totalPasses - accPasses, teamColor, Colors.grey, tx, lb,
              showOppAsLabel: true, oppLabel: 'errati'),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.flag, tr(context, 'Corner'), corners, oppCorners, teamColor,
              oppColor, tx, lb),
          const SizedBox(height: 16),
          _heatmapMetricVs(Icons.arrow_upward, 'Ingressi terzo off.', ftEntries,
              oppFtEntries, teamColor, oppColor, tx, lb),
        ]),
      ),
      const SizedBox(height: 14),
    ]);
  }

  Widget _heatmapMetricVs(IconData icon, String label, int value, int oppValue,
      Color color, Color oppColor, Color tx, Color lb,
      {bool showOppAsLabel = false, String oppLabel = ''}) {
    final isWinning = value > oppValue;
    final isDraw = value == oppValue;
    return Row(children: [
      Icon(icon, size: 18, color: color.withOpacity(0.7)),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
      Text(value.toString(),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      if (!isDraw) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
              color: (isWinning
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(isWinning ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: isWinning
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336)),
        ),
      ],
      const SizedBox(width: 6),
      Text(showOppAsLabel ? oppLabel : 'vs ${oppValue.toString()}',
          style: TextStyle(fontSize: 12, color: lb)),
    ]);
  }

  Widget _heatmapZoneBar(String label, int value, int max, Color color,
      Color tx, Color lb, bool isDark) {
    return Row(children: [
      SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: lb))),
      Expanded(
          child: SizedBox(
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(children: [
                  Container(
                      color: Colors.grey.withOpacity(isDark ? 0.15 : 0.12)),
                  FractionallySizedBox(
                      widthFactor: (value / max).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.7)]),
                            borderRadius: BorderRadius.circular(5)),
                      )),
                ]),
              ))),
      const SizedBox(width: 10),
      Text('$value%',
          style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
    ]);
  }

  // ============================================================================
  // ALTRE VISUALIZZAZIONI AVANZATE
  // ============================================================================
  Widget _buildAdvancedLegend(bool isDark) {
    List<Map<String, dynamic>> legendItems = [];
    switch (_advancedStatsFilter) {
      case 'heatmap':
        legendItems = [
          {'color': const Color(0xFF81C784), 'label': tr(context, 'Bassa')},
          {'color': const Color(0xFFFFEE58), 'label': localizeShotData(context, 'Media')},
          {'color': const Color(0xFFF44336), 'label': tr(context, 'Alta')}
        ];
        break;
      case 'defensive':
        legendItems = [
          {'color': Colors.red, 'label': 'Tackle'},
          {'color': Colors.orange, 'label': S.of(context)!.intercetti},
          {'color': Colors.yellow[700], 'label': tr(context, 'Rinvii')}
        ];
        break;
      default:
        break;
    }
    if (legendItems.isEmpty) return const SizedBox.shrink();
    return Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: legendItems.map((item) {
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                            color: item['color'],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2))),
                    const SizedBox(width: 6),
                    Text(item['label'],
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ]));
            }).toList()));
  }

  // ============================================================================
  // TAB 3: EVENTI — PREMIUM CENTRAL TIMELINE
  // ============================================================================
  static const _keyEventTypes = {
    'goal',
    'yellowCard',
    'redCard',
    'substitution'
  };

  Widget _buildEnhancedEventsTab(ThemeData theme, bool isDark) {
    final allEvents = _generateDetailedMockEvents();
    allEvents.sort((a, b) => a.minute.compareTo(b.minute));

    // Filter by active event types
    final filteredEvents =
        allEvents.where((e) => _activeEventFilters.contains(e.type)).toList();

    if (!_eventsChronologicalOrder)
      filteredEvents.sort((a, b) => b.minute.compareTo(a.minute));

    // Running score for goal events
    final scoreAtMinute = <int, List<int>>{};
    int hGoals = 0, aGoals = 0;
    final sortedAll = List<LocalMatchEvent>.from(allEvents)
      ..sort((a, b) => a.minute.compareTo(b.minute));
    for (final e in sortedAll) {
      if (e.type == 'goal') {
        if (e.isHomeTeam)
          hGoals++;
        else
          aGoals++;
      }
      scoreAtMinute[e.minute] = [hGoals, aGoals];
    }

    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final homeColor = const Color(0xFF1565C0);
    final awayColor = const Color(0xFFD32F2F);

    return Container(
      color: bg,
      child: Column(children: [
        _buildEventsControls(theme, isDark, allEvents),
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Text(tr(context, 'Nessun evento trovato'),
                      style: TextStyle(fontSize: 16, color: Colors.grey[500])))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredEvents.length + 3,
                  itemBuilder: (context, index) {
                    final isChrono = _eventsChronologicalOrder;
                    // First item: scrollable momentum chart
                    if (index == 0)
                      return _buildMomentumBar(allEvents, isDark, homeColor, awayColor);
                    // Second item: KO if chrono, FT if reverse
                    if (index == 1)
                      return _buildMatchMarker(
                          isChrono ? S.of(context)!.calcioInizio : S.of(context)!.finePartita,
                          isChrono ? 0 : 90,
                          isDark);
                    // Last item: FT if chrono, KO if reverse
                    if (index == filteredEvents.length + 2)
                      return _buildMatchMarker(
                          isChrono ? S.of(context)!.finePartita : S.of(context)!.calcioInizio,
                          isChrono ? 90 : 0,
                          isDark);
                    final event = filteredEvents[index - 2];
                    final score = scoreAtMinute[event.minute] ?? [0, 0];
                    // HT separator: detect crossing between 1st and 2nd half
                    bool needsHT = false;
                    if (index > 2) {
                      final prevEvent = filteredEvents[index - 3];
                      if (isChrono) {
                        needsHT = prevEvent.minute <= 45 && event.minute > 45;
                      } else {
                        needsHT = prevEvent.minute > 45 && event.minute <= 45;
                      }
                    }
                    return Column(children: [
                      if (needsHT) _buildMatchMarker(S.of(context)!.intervallo, 45, isDark),
                      _buildCentralTimelineEvent(
                          event, score, isDark, homeColor, awayColor),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  // ── ATTACK MOMENTUM (SofaScore-style: one team per bar, height = danger) ──
  // Mock attack sequence data: each entry = (minute, isHome, intensity 0.0-1.0)
  // In production this comes from the API attack momentum endpoint
  static final List<List<dynamic>> _mockAttackMomentum = [
    // 1° TEMPO — Lazio dominant opening, Milan responds, back and forth
    [1, true, 0.3], [2, true, 0.5], [3, false, 0.2], [4, true, 0.4],
    [5, true, 0.6], [6, true, 0.7], [7, false, 0.3], [8, true, 0.8],
    [9, true, 0.5], [10, false, 0.4], [11, true, 0.3],
    [12, true, 1.0], // GOL Immobile
    [13, true, 0.4], [14, false, 0.5], [15, true, 0.6], [16, false, 0.3],
    [17, false, 0.6], [18, false, 0.8], [19, false, 0.5], [20, true, 0.3],
    [21, true, 0.5], [22, true, 0.4], [23, true, 0.3], [24, false, 0.4],
    [25, true, 0.5], [26, false, 0.3], [27, false, 0.5], [28, true, 0.6],
    [29, true, 0.3], [30, false, 0.7], [31, false, 0.5], [32, true, 0.4],
    [33, true, 0.7], [34, false, 0.6], [35, false, 0.7], [36, true, 0.3],
    [37, true, 0.4], [38, true, 0.6], [39, false, 0.4], [40, false, 0.5],
    [41, true, 0.5], [42, false, 0.7], [43, true, 0.3], [44, false, 0.4],
    [45, true, 0.3],
    // 2° TEMPO — Milan pressing, Lazio counter, late Lazio surge
    [46, false, 0.5], [47, false, 0.6], [48, true, 0.5], [49, false, 0.4],
    [50, false, 0.7], [51, true, 0.3], [52, true, 0.4], [53, false, 0.5],
    [54, false, 0.6], [55, true, 0.5], [56, false, 0.9], // GOL Giroud
    [57, false, 0.4], [58, true, 0.3], [59, true, 0.5], [60, true, 0.6],
    [61, false, 0.3], [62, true, 0.4], [63, false, 0.6], [64, true, 0.5],
    [65, true, 0.3], [66, false, 0.4], [67, true, 0.7], [68, true, 0.5],
    [69, false, 0.3], [70, true, 0.6], [71, true, 0.8], [72, false, 0.4],
    [73, true, 0.7], [74, true, 0.5], [75, false, 0.3], [76, true, 0.6],
    [77, true, 0.7], [78, true, 1.0], // GOL Felipe Anderson
    [79, true, 0.4], [80, false, 0.6], [81, false, 0.5], [82, true, 0.3],
    [83, false, 0.4], [84, true, 0.5], [85, false, 0.6], [86, true, 0.4],
    [87, false, 0.3], [88, true, 0.5], [89, true, 0.3], [90, false, 0.4],
  ];

  Widget _buildMomentumBar(List<LocalMatchEvent> allEvents, bool isDark,
      Color homeColor, Color awayColor) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final dividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12);
    final data = _mockAttackMomentum;
    final segCount = data.length;

    // Eventi per i marker
    final goalEvents = allEvents.where((e) => e.type == 'goal').toList();
    final cardEvents = allEvents.where((e) => e.type == 'yellowCard' || e.type == 'redCard').toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.show_chart_rounded, size: 14, color: lb),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context)!.faseOffensiva,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: tx, letterSpacing: 0.2)),
                const SizedBox(height: 2),
                Text(tr(context, 'Pressione offensiva minuto per minuto'),
                    style: TextStyle(
                        fontSize: 10, color: lb, fontWeight: FontWeight.w400, height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _momentumLegendDot(homeColor, widget.match.homeTeamName, lb),
          const SizedBox(width: 12),
          _momentumLegendDot(awayColor, widget.match.awayTeamName, lb),
        ]),
        const SizedBox(height: 16),

        // ── Sismografo a barre ──
        SizedBox(
          height: 100,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final barWidth = w / segCount;
            final halfH = 100.0 / 2;
            return Stack(clipBehavior: Clip.none, children: [
              // Subtle grid
              Positioned(
                top: halfH * 0.5,
                left: 0, right: 0,
                child: Container(height: 0.5, color: dividerColor),
              ),
              Positioned(
                top: halfH,
                left: 0, right: 0,
                child: Container(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.18),
                ),
              ),
              Positioned(
                top: halfH * 1.5,
                left: 0, right: 0,
                child: Container(height: 0.5, color: dividerColor),
              ),

              // Bars
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(segCount, (i) {
                  final isHome = data[i][1] as bool;
                  final intensity = (data[i][2] as double).clamp(0.0, 1.0);
                  final barH = intensity * (halfH - 4);
                  final color = isHome ? homeColor : awayColor;
                  final isHighIntensity = intensity > 0.7;

                  return SizedBox(
                    width: barWidth,
                    height: 100,
                    child: Stack(children: [
                      if (isHome && barH > 0)
                        Positioned(
                          bottom: halfH + 1,
                          left: barWidth * 0.12,
                          right: barWidth * 0.12,
                          height: barH,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color.withOpacity(0.3 + intensity * 0.4),
                                  color.withOpacity(0.5 + intensity * 0.45),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: isHighIntensity
                                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, -1))]
                                  : null,
                            ),
                          ),
                        ),
                      if (!isHome && barH > 0)
                        Positioned(
                          top: halfH + 1,
                          left: barWidth * 0.12,
                          right: barWidth * 0.12,
                          height: barH,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withOpacity(0.3 + intensity * 0.4),
                                  color.withOpacity(0.5 + intensity * 0.45),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: isHighIntensity
                                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                          ),
                        ),
                    ]),
                  );
                }),
              ),

              // HT divider
              Positioned(
                left: 45 * barWidth,
                top: 0, bottom: 0,
                child: Container(
                  width: 1,
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
                ),
              ),

              // ── Event markers: Goals ──
              ...goalEvents.map((e) {
                final xPos = (e.minute / 90).clamp(0.0, 1.0) * w;
                return Positioned(
                  left: xPos - 8,
                  top: e.isHomeTeam ? 0 : null,
                  bottom: e.isHomeTeam ? null : 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: e.isHomeTeam ? homeColor : awayColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (e.isHomeTeam ? homeColor : awayColor).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.sports_soccer, size: 8, color: Colors.white),
                    ),
                  ),
                );
              }),

              // ── Event markers: Cards ──
              ...cardEvents.map((e) {
                final xPos = (e.minute / 90).clamp(0.0, 1.0) * w;
                final isRed = e.type == 'redCard';
                return Positioned(
                  left: xPos - 4,
                  top: e.isHomeTeam ? 4 : null,
                  bottom: e.isHomeTeam ? null : 4,
                  child: Container(
                    width: 8, height: 11,
                    decoration: BoxDecoration(
                      color: isRed ? Colors.red : Colors.amber,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isRed ? Colors.red : Colors.amber).withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ]);
          }),
        ),
        const SizedBox(height: 8),

        // ── Time labels ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _momentumTimeLabel("0'", lb, false),
          _momentumTimeLabel("15'", lb, false),
          _momentumTimeLabel("30'", lb, false),
          _momentumTimeLabel("45' · HT", lb, true),
          _momentumTimeLabel("60'", lb, false),
          _momentumTimeLabel("75'", lb, false),
          _momentumTimeLabel("90' · FT", lb, true),
        ]),
        const SizedBox(height: 10),
        // ── Mini-legend: marker types ──
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: lb.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.sports_soccer, size: 6, color: cardBg),
            ),
          ),
          const SizedBox(width: 5),
          Text(S.of(context)!.gol,
              style: TextStyle(fontSize: 9.5, color: lb, fontWeight: FontWeight.w500)),
          const SizedBox(width: 14),
          Container(
            width: 5, height: 8,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 5, height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 5),
          Text(tr(context, 'Cartellini'),
              style: TextStyle(fontSize: 9.5, color: lb, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _momentumLegendDot(Color color, String label, Color textColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _momentumTimeLabel(String text, Color color, bool bold) {
    return Text(text, style: TextStyle(
      fontSize: 9,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
      letterSpacing: bold ? 0.5 : 0,
    ));
  }

  // ── CONTROLS: Filter button + Sort ──
  Widget _buildEventsControls(
      ThemeData theme, bool isDark, List<LocalMatchEvent> allEvents) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? Colors.grey[850]! : Colors.white;
    final accent = theme.primaryColor;
    final isAllKey = _activeEventFilters.length == _keyEventTypes.length &&
        _keyEventTypes.every((t) => _activeEventFilters.contains(t));
    final filterLabel = isAllKey
        ? S.of(context)!.eventiChiave
        : '${_activeEventFilters.length} filtri attivi';
    final filteredCount =
        allEvents.where((e) => _activeEventFilters.contains(e.type)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Filter button
        Expanded(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showEventFilterSheet(isDark),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(children: [
                    Icon(Icons.filter_list_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(filterLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('$filteredCount',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded, size: 18, color: lb),
                  ]),
                ),
              )),
        ),
        // Divider
        Container(
            width: 1,
            height: 28,
            color: isDark ? Colors.grey[700] : Colors.grey[200]),
        // Sort button
        Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() =>
                    _eventsChronologicalOrder = !_eventsChronologicalOrder);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      _eventsChronologicalOrder
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 16,
                      color: lb),
                  const SizedBox(width: 4),
                  Text(_eventsChronologicalOrder ? S.of(context)!.chrono : S.of(context)!.recenti,
                      style: TextStyle(
                          fontSize: 12,
                          color: lb,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
      ]),
    );
  }

  // ── FILTER BOTTOM SHEET ──
  void _showEventFilterSheet(bool isDark) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? Colors.grey[900]! : Colors.white;
    final allTypes = [
      ('goal', '⚽', S.of(context)!.gol),
      ('yellowCard', '🟨', tr(context, 'Cartellini gialli')),
      ('redCard', '🟥', tr(context, 'Cartellini rossi')),
      ('substitution', '🔄', tr(context, 'Sostituzioni')),
      ('shot', '🎯', S.of(context)!.tiriSection),
      ('foul', '⚠️', S.of(context)!.falliLabel),
      ('corner', '🚩', tr(context, 'Corner')),
      ('offside', '🏳️', tr(context, 'Fuorigioco')),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // Title + quick actions
              Row(children: [
                Text(tr(context, 'Filtra eventi'),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setSheetState(() {});
                    setState(() => _activeEventFilters = {
                          'goal',
                          'yellowCard',
                          'redCard',
                          'substitution'
                        });
                    setSheetState(() {});
                  },
                  child: Text(tr(context, 'Solo chiave'),
                      style: TextStyle(fontSize: 12, color: lb)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    setSheetState(() {});
                    setState(() => _activeEventFilters = {
                          'goal',
                          'yellowCard',
                          'redCard',
                          'substitution',
                          'shot',
                          'foul',
                          'corner',
                          'offside'
                        });
                    setSheetState(() {});
                  },
                  child:
                      Text(localizeShotData(context, 'Tutti'), style: TextStyle(fontSize: 12, color: lb)),
                ),
              ]),
              const SizedBox(height: 8),
              // Filter chips
              Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: allTypes.map((t) {
                    final type = t.$1;
                    final emoji = t.$2;
                    final label = t.$3;
                    final isActive = _activeEventFilters.contains(type);
                    final color = _getEventColor(type);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isActive)
                            _activeEventFilters.remove(type);
                          else
                            _activeEventFilters.add(type);
                        });
                        setSheetState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withOpacity(0.15)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isActive ? color : Colors.transparent,
                              width: 2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive ? color : lb,
                              )),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: color),
                          ],
                        ]),
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 16),
            ]),
          );
        },
      ),
    );
  }

  // ── MATCH MARKERS (KO, HT, FT) ──
  Widget _buildMatchMarker(String label, int minute, bool isDark) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[500]!;
    final tx = isDark ? Colors.white : Colors.black87;

    // Icon + accent based on match phase
    IconData icon;
    Color accent;
    if (minute == 0) {
      icon = Icons.play_arrow_rounded;
      accent = const Color(0xFF26A69A); // teal-green: kickoff
    } else if (minute == 45) {
      icon = Icons.pause_circle_outline_rounded;
      accent = const Color(0xFFFFA726); // orange: halftime
    } else {
      icon = Icons.flag_rounded;
      accent = const Color(0xFFEF5350); // red: fulltime
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lb.withOpacity(0.0), lb.withOpacity(0.3)],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(isDark ? 0.18 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tx,
                    letterSpacing: 0.9)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text("${minute}\'",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.3)),
            ),
          ]),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lb.withOpacity(0.3), lb.withOpacity(0.0)],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── CENTRAL TIMELINE EVENT ──
  Widget _buildCentralTimelineEvent(LocalMatchEvent event, List<int> score,
      bool isDark, Color homeColor, Color awayColor) {
    final isHome = event.isHomeTeam;
    final isGoal = event.type == 'goal';
    final isKey = _keyEventTypes.contains(event.type);
    final teamColor = isHome ? homeColor : awayColor;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final timelineColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    Widget minuteBadge = Container(
      width: isGoal ? 44 : (isKey ? 36 : 28),
      height: isGoal ? 44 : (isKey ? 36 : 28),
      decoration: BoxDecoration(
        color: isGoal
            ? teamColor
            : (isKey ? teamColor.withOpacity(0.15) : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(
            color: isGoal
                ? teamColor
                : (isKey ? teamColor.withOpacity(0.5) : timelineColor),
            width: isGoal ? 2.5 : 1.5),
        boxShadow: isGoal
            ? [
                BoxShadow(
                    color: teamColor.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Center(
          child: Text('${event.minute}\'',
              style: TextStyle(
                fontSize: isGoal ? 14 : (isKey ? 12 : 10),
                fontWeight: FontWeight.w800,
                color: isGoal ? Colors.white : (isKey ? teamColor : lb),
              ))),
    );

    Widget eventContent =
        GestureDetector(
        onTap: () => _openPlayerStatsFromEvent(event.playerName, isHome, isDark),
        child: _buildEventContent(event, isHome, isDark, teamColor, score));

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: isGoal ? 6 : (isKey ? 3 : 1), horizontal: 12),
      child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            flex: 5, child: isHome ? eventContent : const SizedBox.shrink()),
        SizedBox(
            width: 52,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [minuteBadge])),
        Expanded(
            flex: 5, child: isHome ? const SizedBox.shrink() : eventContent),
      ])),
    );
  }

  void _openPlayerStatsFromEvent(String playerName, bool isHome, bool isDark) {
    final homeLineup = _generateMockLocalLineup(true);
    final awayLineup = _generateMockLocalLineup(false);
    final lineup = isHome ? homeLineup : awayLineup;
    final player = lineup.cast<LocalLineupPlayer?>().firstWhere(
        (p) => p!.name == playerName, orElse: () => null);
    if (player == null) return;
    const hc = Color(0xFF1565C0);
    const ac = Color(0xFFD32F2F);
    final teamColor = isHome ? hc : ac;
    _showPlayerMatchStats(player, teamColor, isDark,
        allPlayers: [...homeLineup, ...awayLineup, ..._generateMockBench(true), ..._generateMockBench(false)]);
  }


  Widget _buildEventContent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, List<int> score) {
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? Colors.grey[850]! : Colors.white;

    if (event.type == 'goal')
      return _buildGoalEvent(
          event, isHome, isDark, teamColor, cardBg, tx, lb, score);
    if (event.type == 'yellowCard' || event.type == 'redCard')
      return _buildCardEvent(event, isHome, isDark, teamColor, cardBg, tx, lb);
    if (event.type == 'substitution')
      return _buildSubEvent(event, isHome, isDark, teamColor, cardBg, tx, lb);
    return _buildMinorEvent(event, isHome, isDark, teamColor, tx, lb);
  }

  // ── GOL ──
  Widget _buildGoalEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb, List<int> score) {
    final textAlign = isHome ? TextAlign.right : TextAlign.left;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teamColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: teamColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
          crossAxisAlignment:
              isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: teamColor, borderRadius: BorderRadius.circular(8)),
              child: Text('${score[0]} - ${score[1]}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 6),
            Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isHome)
                    Icon(Icons.sports_soccer, size: 18, color: teamColor),
                  if (!isHome) const SizedBox(width: 6),
                  Flexible(
                      child: Text(event.playerName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tx),
                          textAlign: textAlign)),
                  if (isHome) const SizedBox(width: 6),
                  if (isHome)
                    Icon(Icons.sports_soccer, size: 18, color: teamColor),
                ]),
            if (event.detail != null && event.detail!.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_localizeEventDetail(context, event.detail!),
                      style: TextStyle(
                          fontSize: 11, color: lb, fontStyle: FontStyle.italic),
                      textAlign: textAlign)),
          ]),
    );
  }

  // ── CARTELLINO ──
  Widget _buildCardEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb) {
    final isRed = event.type == 'redCard';
    final cardColor = isRed ? const Color(0xFFD32F2F) : const Color(0xFFF9A825);
    final textAlign = isHome ? TextAlign.right : TextAlign.left;

    // ── Enhanced card icon: larger, bordered, with shadow ──
    Widget enhancedCardIcon() => Container(
          width: 16,
          height: 22,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(
              color: cardColor.withOpacity(0.5),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardColor.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) enhancedCardIcon(),
            if (!isHome) const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: isHome
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                  Text(event.playerName,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                      textAlign: textAlign),
                  if (event.detail != null)
                    Text(_localizeEventDetail(context, event.detail!),
                        style: TextStyle(fontSize: 10, color: lb),
                        textAlign: textAlign),
                ])),
            if (isHome) const SizedBox(width: 10),
            if (isHome) enhancedCardIcon(),
          ]),
    );
  }

  Widget _buildCardIcon(Color color) {
    return Container(
        width: 16,
        height: 22,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)
            ]));
  }

  // ── SOSTITUZIONE ──
  Widget _buildSubEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color cardBg, Color tx, Color lb) {
    final greenIn = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final redOut = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);

    // ── Swap icon: prominent, circular badge ──
    Widget swapBadge() => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(isDark ? 0.18 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: teamColor.withOpacity(0.35), width: 1),
          ),
          child: Icon(Icons.swap_vert_rounded,
              size: 16, color: teamColor),
        );

    // ── In/Out rows ──
    Widget inRow() => Row(mainAxisSize: MainAxisSize.min, children: [
          if (isHome)
            Flexible(
                child: Text(_localizeEventDetail(context, event.detail),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: greenIn))),
          if (isHome) const SizedBox(width: 4),
          Icon(Icons.arrow_downward_rounded, size: 12, color: greenIn),
          if (!isHome) const SizedBox(width: 4),
          if (!isHome)
            Flexible(
                child: Text(_localizeEventDetail(context, event.detail),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: greenIn))),
        ]);

    Widget outRow() => Row(mainAxisSize: MainAxisSize.min, children: [
          if (isHome)
            Flexible(
                child: Text(event.playerName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: redOut))),
          if (isHome) const SizedBox(width: 4),
          Icon(Icons.arrow_upward_rounded, size: 12, color: redOut),
          if (!isHome) const SizedBox(width: 4),
          if (!isHome)
            Flexible(
                child: Text(event.playerName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: redOut))),
        ]);

    final hasSubDetail = event.subDetail != null && event.subDetail!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teamColor.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) swapBadge(),
            if (!isHome) const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: isHome
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                  inRow(),
                  outRow(),
                  if (hasSubDetail)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _localizeEventDetail(context, event.subDetail),
                        style: TextStyle(
                            fontSize: 10,
                            color: lb,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ])),
            if (isHome) const SizedBox(width: 10),
            if (isHome) swapBadge(),
          ]),
    );
  }

  Widget _buildSubIcon() {
    return SizedBox(
        width: 20,
        height: 24,
        child: Stack(children: [
          const Positioned(
              top: 0,
              left: 2,
              child: Icon(Icons.arrow_downward_rounded,
                  size: 14, color: Color(0xFF2E7D32))),
          const Positioned(
              bottom: 0,
              right: 2,
              child: Icon(Icons.arrow_upward_rounded,
                  size: 14, color: Color(0xFFD32F2F))),
        ]));
  }

  // ── EVENTI MINORI (falli, tiri, corner, fuorigioco) ──
  Widget _buildMinorEvent(LocalMatchEvent event, bool isHome, bool isDark,
      Color teamColor, Color tx, Color lb) {
    final icon = _getEventIcon(event.type);
    final color = _getEventColor(event.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isHome) Icon(icon, size: 13, color: color.withOpacity(0.7)),
            if (!isHome) const SizedBox(width: 5),
            Flexible(
                child: Text(
              '${event.playerName}${event.detail != null ? " · ${event.detail}" : ""}',
              style: TextStyle(
                  fontSize: 11, color: lb, fontWeight: FontWeight.w400),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            if (isHome) const SizedBox(width: 5),
            if (isHome) Icon(icon, size: 13, color: color.withOpacity(0.7)),
          ]),
    );
  }

  // ── HELPERS ──
  void _navigateToPlayer(LocalMatchEvent event, bool isHome, Color teamColor) {
    if (widget.match.status == 'live') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerMatchStatsScreen(
                  playerName: event.playerName,
                  playerNumber: event.minute,
                  teamName: isHome
                      ? widget.match.homeTeamName
                      : widget.match.awayTeamName,
                  teamColor: teamColor,
                  match: widget.match)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerFinishedMatchScreen(
                  playerName: event.playerName,
                  playerNumber: event.minute,
                  teamName: isHome
                      ? widget.match.homeTeamName
                      : widget.match.awayTeamName,
                  teamColor: teamColor,
                  match: widget.match)));
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return const Color(0xFF4CAF50);
      case 'yellowCard':
        return const Color(0xFFF9A825);
      case 'redCard':
        return const Color(0xFFF44336);
      case 'substitution':
        return const Color(0xFF2E7D32);
      case 'foul':
        return const Color(0xFFFF9800);
      case 'offside':
        return const Color(0xFF2196F3);
      case 'shot':
        return const Color(0xFF9C27B0);
      case 'corner':
        return const Color(0xFF00BCD4);
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellowCard':
        return Icons.rectangle;
      case 'redCard':
        return Icons.rectangle;
      case 'substitution':
        return Icons.swap_horiz;
      case 'foul':
        return Icons.warning_rounded;
      case 'offside':
        return Icons.front_hand;
      case 'shot':
        return Icons.gps_fixed;
      case 'corner':
        return Icons.flag_rounded;
      default:
        return Icons.circle;
    }
  }

  // ✅ EVENTI COERENTI CON TUTTE LE STATISTICHE E MAPPA TIRI:
  // Tiri HOME: 15 (2 goal + 5 on_target + 5 off_target + 3 blocked) = _homeShotsTotal
  // Tiri AWAY: 8 (1 goal + 2 on_target + 3 off_target + 2 blocked) = _awayShotsTotal
  // Corner: 6H / 4A | Gialli: 2H / 3A | Falli: 12H / 15A | Goal: 2H / 1A
  // Sostituzioni: 2H (52' Pedro→Felipe Anderson, 65' Luis Alberto→Marcos Antonio)
  //               2A (75' Giroud→Jovic, 83' Brahim Diaz→Saelemaekers)
  // ✅ Nessun giocatore agisce dopo essere stato sostituito
  // ✅ Tutti i giocatori negli eventi/shot map/difensive sono in formazione o entrati come sostituti
  // ✅ Minuti tiri identici tra eventi e shot map (stessi giocatori, stessi minuti)
  List<LocalMatchEvent> _generateDetailedMockEvents() {
    return [
      // === 1° TEMPO ===
      LocalMatchEvent(
          type: 'corner',
          minute: 5,
          playerName: 'Zaccagni',
          detail: 'CORNER_LEFT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 7,
          playerName: 'Tonali',
          detail: 'FOUL_ON:Zaccagni',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 8,
          playerName: 'Pedro',
          detail: 'Tiro parato',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 10,
          playerName: 'Tomori',
          detail: 'FOUL_ON:Zaccagni',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 11,
          playerName: 'Romagnoli',
          detail: 'FOUL_ON:Giroud',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'goal',
          minute: 12,
          playerName: 'Immobile',
          detail: 'Assist: Zaccagni',
          subDetail: 'Destro da area',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 15,
          playerName: 'Cataldi',
          detail: 'FOUL_ON:Leao',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 18,
          playerName: 'Leao',
          detail: 'Tiro parato',
          subDetail: 'Sinistro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 19,
          playerName: 'Theo Hernandez',
          detail: 'CORNER_LEFT',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 20,
          playerName: 'Guendouzi',
          detail: 'FOUL_ON:Bennacer',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 15,
          playerName: 'Zaccagni',
          detail: 'Tiro fuori',
          subDetail: 'Sinistro',
          isHomeTeam: true,
          playerPhoto: null),
      // ✅ FIX: era Pellegrini (non in formazione) → Patric
      LocalMatchEvent(
          type: 'yellowCard',
          minute: 23,
          playerName: 'Patric',
          detail: S.of(context)!.falloTattico,
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 25,
          playerName: 'Zaccagni',
          detail: 'CORNER_RIGHT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 26,
          playerName: 'Calabria',
          detail: 'FOUL_ON:Zaccagni',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 41,
          playerName: 'Pedro',
          detail: 'Tiro fuori',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 29,
          playerName: 'Lazzari',
          detail: 'FOUL_ON:Leao',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 35,
          playerName: 'Leao',
          detail: 'Tiro fuori',
          subDetail: 'Sinistro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 31,
          playerName: 'Bennacer',
          detail: 'FOUL_ON:Luis Alberto',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 32,
          playerName: 'Luis Alberto',
          detail: 'CORNER_LEFT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 33,
          playerName: 'Zaccagni',
          detail: 'Tiro parato',
          subDetail: 'Sinistro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'yellowCard',
          minute: 34,
          playerName: 'Theo Hernandez',
          detail: 'FOUL_ON:Immobile',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 36,
          playerName: 'Marusic',
          detail: 'FOUL_ON:Pulisic',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 37,
          playerName: 'Zaccagni',
          detail: 'CORNER_RIGHT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 37,
          playerName: 'Bennacer',
          detail: 'FOUL_ON:Pedro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 38,
          playerName: 'Luis Alberto',
          detail: 'Tiro fuori',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 39,
          playerName: 'Tomori',
          detail: 'FOUL_ON:Pedro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 40,
          playerName: 'Theo Hernandez',
          detail: 'CORNER_RIGHT',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'offside',
          minute: 41,
          playerName: 'Giroud',
          detail: 'OFFSIDE_ACTIVE',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'offside',
          minute: 28,
          playerName: 'Immobile',
          detail: 'OFFSIDE_PASSIVE',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'offside',
          minute: 58,
          playerName: 'Leao',
          detail: 'OFFSIDE_ACTIVE',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'offside',
          minute: 70,
          playerName: 'Felipe Anderson',
          detail: 'OFFSIDE_ACTIVE',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'offside',
          minute: 82,
          playerName: 'Immobile',
          detail: 'OFFSIDE_PASSIVE',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 42,
          playerName: 'Theo Hernandez',
          detail: 'Tiro fuori',
          subDetail: 'Sinistro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 44,
          playerName: 'Romagnoli',
          detail: 'FOUL_ON:Giroud',
          isHomeTeam: true,
          playerPhoto: null),
      // === 2° TEMPO ===
      LocalMatchEvent(
          type: 'shot',
          minute: 48,
          playerName: 'Pedro',
          detail: 'Tiro bloccato',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 49,
          playerName: 'Kjaer',
          detail: 'FOUL_ON:Immobile',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 50,
          playerName: 'Bennacer',
          detail: 'Tiro bloccato',
          subDetail: 'Destro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 52,
          playerName: 'Pedro',
          detail: 'Felipe Anderson',
          subDetail: 'Cambio',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 52,
          playerName: 'Luis Alberto',
          detail: 'Tiro parato',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 53,
          playerName: 'Zaccagni',
          detail: 'CORNER_RIGHT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 54,
          playerName: 'Patric',
          detail: 'FOUL_ON:Brahim Diaz',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 55,
          playerName: 'Felipe Anderson',
          detail: 'Tiro fuori',
          subDetail: 'Sinistro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'goal',
          minute: 56,
          playerName: 'Giroud',
          detail: 'Assist: Leao',
          subDetail: 'Colpo di testa',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 57,
          playerName: 'Lazzari',
          detail: 'FOUL_ON:Theo',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 58,
          playerName: 'Calabria',
          detail: 'FOUL_ON:Felipe Anderson',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 59,
          playerName: 'Zaccagni',
          detail: 'CORNER_LEFT',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 60,
          playerName: 'Cataldi',
          detail: 'Tiro parato',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'yellowCard',
          minute: 61,
          playerName: 'Bennacer',
          detail: S.of(context)!.falloTattico,
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 63,
          playerName: 'Pulisic',
          detail: 'Tiro fuori',
          subDetail: 'Destro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 64,
          playerName: 'Calabria',
          detail: 'FOUL_ON:Marusic',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 65,
          playerName: 'Luis Alberto',
          detail: 'Marcos Antonio',
          subDetail: 'Cambio',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 66,
          playerName: 'Tonali',
          detail: 'FOUL_ON:Cataldi',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 67,
          playerName: 'Immobile',
          detail: 'Tiro bloccato',
          subDetail: 'Colpo di testa',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 68,
          playerName: 'Cataldi',
          detail: 'Vecino',
          subDetail: 'Cambio',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 69,
          playerName: 'Vecino',
          detail: 'FOUL_ON:Brahim Diaz',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 71,
          playerName: 'Immobile',
          detail: 'Tiro parato',
          subDetail: 'Colpo di testa',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 71,
          playerName: 'Theo Hernandez',
          detail: 'CORNER_RIGHT',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 72,
          playerName: 'Brahim Diaz',
          detail: 'FOUL_ON:Guendouzi',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 72,
          playerName: 'Tonali',
          detail: 'Adli',
          subDetail: 'Cambio',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 73,
          playerName: 'Guendouzi',
          detail: 'Tiro bloccato',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 74,
          playerName: 'Guendouzi',
          detail: 'FOUL_ON:Tonali',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 75,
          playerName: 'Giroud',
          detail: 'Jovic',
          subDetail: 'Cambio',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 71,
          playerName: 'Pulisic',
          detail: 'Tiro bloccato',
          subDetail: 'Destro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'corner',
          minute: 76,
          playerName: 'Theo Hernandez',
          detail: 'CORNER_LEFT',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'goal',
          minute: 78,
          playerName: 'Felipe Anderson',
          detail: 'Assist: Immobile',
          subDetail: 'Sinistro da area',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 79,
          playerName: 'Kjaer',
          detail: 'FOUL_ON:Immobile',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 80,
          playerName: 'Brahim Diaz',
          detail: 'Tiro parato',
          subDetail: 'Destro',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 81,
          playerName: 'Tomori',
          detail: 'FOUL_ON:Immobile',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 83,
          playerName: 'Marusic',
          detail: 'FOUL_ON:Leao',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'substitution',
          minute: 83,
          playerName: 'Brahim Diaz',
          detail: 'Saelemaekers',
          subDetail: 'Cambio',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'shot',
          minute: 85,
          playerName: 'Guendouzi',
          detail: 'Tiro fuori',
          subDetail: 'Destro',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'yellowCard',
          minute: 85,
          playerName: 'Tomori',
          detail: 'FOUL_ON:Felipe Anderson',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 86,
          playerName: 'Pulisic',
          detail: 'FOUL_ON:Marusic',
          isHomeTeam: false,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'yellowCard',
          minute: 88,
          playerName: 'Guendouzi',
          detail: S.of(context)!.proteste,
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 89,
          playerName: 'Patric',
          detail: 'FOUL_ON:Leao',
          isHomeTeam: true,
          playerPhoto: null),
      LocalMatchEvent(
          type: 'foul',
          minute: 90,
          playerName: 'Leao',
          detail: 'FOUL_ON:Lazzari',
          isHomeTeam: false,
          playerPhoto: null),
    ];
  }

  // ============================================================================
  // TAB 4: LINEUPS
  // ============================================================================
  Widget _buildLineupsTab(ThemeData theme, bool isDark) {
    List<LocalLineupPlayer> homeLineup = [];
    List<LocalLineupPlayer> awayLineup = [];
    if (_matchData != null) {
      homeLineup = _matchData!.homeLineup
          .map((p) => LocalLineupPlayer(
              number: p.number,
              name: p.name,
              position: p.position,
              rating: p.rating,
              goals: p.goals,
              assists: p.assists,
              shots: p.shots,
              shotsOnTarget: p.shotsOnTarget,
              passes: p.passes,
              passesCompleted: p.passesCompleted,
              tackles: p.tackles,
              interceptions: p.interceptions,
              fouls: p.fouls,
              yellowCards: p.yellowCards,
              redCards: p.redCards))
          .toList();
      awayLineup = _matchData!.awayLineup
          .map((p) => LocalLineupPlayer(
              number: p.number,
              name: p.name,
              position: p.position,
              rating: p.rating,
              goals: p.goals,
              assists: p.assists,
              shots: p.shots,
              shotsOnTarget: p.shotsOnTarget,
              passes: p.passes,
              passesCompleted: p.passesCompleted,
              tackles: p.tackles,
              interceptions: p.interceptions,
              fouls: p.fouls,
              yellowCards: p.yellowCards,
              redCards: p.redCards))
          .toList();
    }
    if (homeLineup.isEmpty) homeLineup = _generateMockLocalLineup(true);
    if (awayLineup.isEmpty) awayLineup = _generateMockLocalLineup(false);

    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final homeFormation = '4-3-3';
    final awayFormation = '4-2-3-1';
    final homeBench = _generateMockBench(true);
    final awayBench = _generateMockBench(false);
    final homeCoach = 'Maurizio Sarri';
    final awayCoach = 'Stefano Pioli';

    final lineup = _showHomeLineup ? homeLineup : awayLineup;
    final formation = _showHomeLineup ? homeFormation : awayFormation;
    final bench = _showHomeLineup ? homeBench : awayBench;
    final coach = _showHomeLineup ? homeCoach : awayCoach;
    final teamColor =
        _showHomeLineup ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
    final allPlayers = [...lineup, ...bench];

    // Average rating
    final avgRating = lineup
            .where((p) => p.rating > 0)
            .fold(0.0, (sum, p) => sum + p.rating) /
        lineup.where((p) => p.rating > 0).length;
    Color avgRatingBg;
    if (avgRating >= 8.0)
      avgRatingBg = const Color(0xFF1B5E20);
    else if (avgRating >= 7.0)
      avgRatingBg = const Color(0xFF388E3C);
    else if (avgRating >= 6.5)
      avgRatingBg = const Color(0xFFF9A825);
    else if (avgRating >= 6.0)
      avgRatingBg = const Color(0xFFEF6C00);
    else
      avgRatingBg = const Color(0xFFD32F2F);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),
      child: Column(children: [
        // Team selector — same style as other sections
        _buildTeamSelector3(_showHomeLineup,
            (val) => setState(() => _showHomeLineup = val!), isDark,
            showTutti: false),

        // Visual pitch + bench + coach
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [
            // ── VISUAL PITCH ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(children: [
                  // Team header bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: const Color(0xFF1B5E20),
                    child: Row(children: [
                      // Team shield
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: Icon(Icons.shield, color: teamColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          _showHomeLineup
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(width: 10),
                      // Avg rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: avgRatingBg,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(avgRating.toStringAsFixed(2),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      const Spacer(),
                      // Formation label
                      Text(formation,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1)),
                    ]),
                  ),
                  // Pitch — responsive: max 420px height, wider on desktop
                  LayoutBuilder(builder: (context, outerConstraints) {
                    final maxH = 460.0;
                    // On narrow screens (mobile) use 0.75, on wide (desktop) use 0.85
                    final ratio = outerConstraints.maxWidth > 600 ? 0.85 : 0.75;
                    final calcH = outerConstraints.maxWidth / ratio;
                    final pitchH = calcH > maxH ? maxH : calcH;
                    return SizedBox(
                      height: pitchH,
                      child: CustomPaint(
                        painter: FormationPitchPainter(isDark: isDark),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final positions = _getFormationPositions(formation);

                          return Stack(clipBehavior: Clip.none, children: [
                            for (int i = 0;
                                i < lineup.length && i < positions.length;
                                i++)
                              _buildPitchPlayer(
                                lineup[i],
                                positions[i],
                                w,
                                h,
                                teamColor,
                                isDark,
                                allPlayers: allPlayers,
                              ),
                          ]);
                        }),
                      ),
                    );
                  }),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── COACH ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: GestureDetector(
                onTap: () => _showCoachProfile(coach, _showHomeLineup, teamColor, isDark),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_outline_rounded,
                        color: teamColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(localizeShotData(context, localizeShotData(context, 'Allenatore')),
                          style: TextStyle(
                              fontSize: 11,
                              color: lb,
                              fontWeight: FontWeight.w500)),
                      Text(coach,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tx)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: lb, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── PANCHINA ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(localizeShotData(context, 'Panchina'),
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: tx)),
            ),
            const SizedBox(height: 10),
            ...bench.map((p) => _buildBenchPlayerItem(
                p, teamColor, isDark, tx, lb, cardBg,
                allPlayers: allPlayers)),
            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }

  // Formation position mapping (x, y normalized 0..1)
  // y=0 = bottom (own goal), y=1 = top (attack)
  List<Offset> _getFormationPositions(String formation) {
    switch (formation) {
      case '4-3-3':
        return const [
          Offset(0.50, 0.12), // GK
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28), // DEF
          Offset(0.28, 0.48), Offset(0.72, 0.48), Offset(0.50, 0.56), // MID
          Offset(0.15, 0.76), Offset(0.50, 0.85), Offset(0.85, 0.76), // ATK
        ];
      case '4-2-3-1':
        return const [
          Offset(0.50, 0.12), // GK
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28), // DEF
          Offset(0.33, 0.46), Offset(0.67, 0.46), // DM
          Offset(0.15, 0.64), Offset(0.50, 0.64), Offset(0.85, 0.64), // AM
          Offset(0.50, 0.84), // ST
        ];
      default:
        return const [
          Offset(0.50, 0.12),
          Offset(0.12, 0.28), Offset(0.37, 0.28), Offset(0.63, 0.28),
          Offset(0.88, 0.28),
          Offset(0.25, 0.48), Offset(0.50, 0.48), Offset(0.75, 0.48),
          Offset(0.18, 0.72), Offset(0.50, 0.82), Offset(0.82, 0.72),
        ];
    }
  }




































  // ── PLAYER MATCH STATS BOTTOM SHEET — SofaScore style ──
  // ============================================================================
  // COACH PROFILE BOTTOM SHEET
  // ============================================================================
  void _showCoachProfile(String coachName, bool isHome, Color teamColor, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final sectionBg = isDark ? const Color(0xFF16162A) : const Color(0xFFF8F9FA);

    // Dati coach (demo realistici 2022-23)
    final Map<String, Map<String, dynamic>> coachData = {
      'Maurizio Sarri': {
        'nationality': '🇮🇹 Italiano',
        'age': 64,
        'born': '10 gennaio 1959',
        'formation': '4-3-3',
        'teamFull': 'S.S. Lazio',
        'seasonW': 14, 'seasonD': 7, 'seasonL': 6,
        'seasonGoalsFor': 42, 'seasonGoalsAgainst': 28,
        'style': 'Possesso palla, pressing alto, gioco verticale rapido',
        'philosophy': 'Il "Sarrismo" si basa su un calcio offensivo e spettacolare, con movimenti sincronizzati e transizioni veloci.',
        'career': [
          {'team': 'Lazio', 'period': '2021-2023', 'trophy': ''},
          {'team': 'Juventus', 'period': '2019-2020', 'trophy': '🏆 Serie A'},
          {'team': 'Chelsea', 'period': '2018-2019', 'trophy': '🏆 Europa League'},
          {'team': 'Napoli', 'period': '2015-2018', 'trophy': ''},
          {'team': 'Empoli', 'period': '2012-2015', 'trophy': ''},
        ],
        'stats': {'matches': 27, 'winRate': 52, 'avgGoals': 1.56, 'cleanSheets': 8, 'avgPoints': 1.81},
      },
      'Stefano Pioli': {
        'nationality': '🇮🇹 Italiano',
        'age': 57,
        'born': '20 ottobre 1965',
        'formation': '4-2-3-1',
        'teamFull': 'A.C. Milan',
        'seasonW': 16, 'seasonD': 5, 'seasonL': 6,
        'seasonGoalsFor': 48, 'seasonGoalsAgainst': 26,
        'style': 'Transizioni rapide, pressing coordinato, gioco sulle fasce',
        'philosophy': 'Calcio pragmatico e moderno, con enfasi sulle ripartenze veloci e la solidità difensiva.',
        'career': [
          {'team': 'Milan', 'period': '2019-2024', 'trophy': '🏆 Scudetto 2022'},
          {'team': 'Fiorentina', 'period': '2017-2019', 'trophy': ''},
          {'team': 'Inter', 'period': '2016-2017', 'trophy': ''},
          {'team': 'Lazio', 'period': '2014-2016', 'trophy': ''},
          {'team': 'Bologna', 'period': '2011-2014', 'trophy': ''},
        ],
        'stats': {'matches': 27, 'winRate': 59, 'avgGoals': 1.78, 'cleanSheets': 10, 'avgPoints': 1.96},
      },
    };

    final data = coachData[coachName];
    if (data == null) return;

    final career = data['career'] as List<Map<String, String>>;
    final stats = data['stats'] as Map<String, dynamic>;
    final totalGames = data['seasonW'] + data['seasonD'] + data['seasonL'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header con iniziali + nome ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(children: [
                  // Avatar con iniziali
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [teamColor, teamColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: teamColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        coachName.split(' ').map((w) => w[0]).take(2).join(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coachName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tx)),
                      const SizedBox(height: 4),
                      Text('${tr(context, 'Allenatore')} · ${data['teamFull']}',
                          style: TextStyle(fontSize: 13, color: lb)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(tr(context, data['nationality'] as String? ?? ''), style: TextStyle(fontSize: 12, color: lb)),
                        const SizedBox(width: 12),
                        Text('${data['age']} ${tr(context, 'anni')}', style: TextStyle(fontSize: 12, color: lb)),
                      ]),
                    ],
                  )),
                ]),
              ),

              // ── Modulo ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.dashboard_rounded, size: 20, color: teamColor),
                  const SizedBox(width: 12),
                  Text(S.of(context)!.modulo, style: TextStyle(fontSize: 13, color: lb, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: teamColor.withOpacity(0.3)),
                    ),
                    child: Text('${data['formation']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: teamColor)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Record Stagionale ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(children: [
                      Icon(Icons.emoji_events_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(tr(context, 'RECORD STAGIONALE'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 1.5)),
                    ]),
                  ),
                  // W / D / L row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      _coachStatBox('V', '${data['seasonW']}', const Color(0xFF4CAF50), isDark),
                      const SizedBox(width: 8),
                      _coachStatBox('P', '${data['seasonD']}', Colors.amber, isDark),
                      const SizedBox(width: 8),
                      _coachStatBox('S', '${data['seasonL']}', const Color(0xFFE53935), isDark),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar V/P/S
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Row(children: [
                          Expanded(flex: data['seasonW'], child: Container(color: const Color(0xFF4CAF50))),
                          Expanded(flex: data['seasonD'], child: Container(color: Colors.amber)),
                          Expanded(flex: data['seasonL'], child: Container(color: const Color(0xFFE53935))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Gol fatti/subiti
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(children: [
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol Fatti'), '${data['seasonGoalsFor']}', tx, lb, isDark)),
                      Container(width: 1, height: 30, color: divider),
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol Subiti'), '${data['seasonGoalsAgainst']}', tx, lb, isDark)),
                      Container(width: 1, height: 30, color: divider),
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Clean Sheet'), '${stats['cleanSheets']}', tx, lb, isDark)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Statistiche Stagionali ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(children: [
                      Icon(Icons.bar_chart_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(tr(context, 'STATISTICHE'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 1.5)),
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(children: [
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Partite'), '${stats['matches']}', tx, lb, isDark)),
                      Container(width: 1, height: 30, color: divider),
                      Expanded(child: _coachInfoTile(localizeShotData(context, '% Vittorie'), '${stats['winRate']}%', tx, lb, isDark)),
                      Container(width: 1, height: 30, color: divider),
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Gol/Partita'), '${stats['avgGoals']}', tx, lb, isDark)),
                      Container(width: 1, height: 30, color: divider),
                      Expanded(child: _coachInfoTile(localizeShotData(context, 'Punti/Partita'), '${stats['avgPoints']}', tx, lb, isDark)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Vedi profilo completo ──
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CoachProfileScreen(
                        coachName: coachName,
                        teamName: isHome ? widget.match.homeTeamName : widget.match.awayTeamName,
                        teamColor: teamColor,
                        data: data,
                      ),
                    ));
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: sectionBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: teamColor.withOpacity(0.15)),
                  ),
                  child: Row(children: [
                    Icon(Icons.person_search_rounded, size: 18, color: teamColor),
                    SizedBox(width: 12),
                    Text(localizeShotData(context, 'Vedi profilo completo'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teamColor)),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, size: 20, color: teamColor.withOpacity(0.6)),
                  ]),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coachStatBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
        ]),
      ),
    );
  }

  Widget _coachInfoTile(String label, String value, Color tx, Color lb, bool isDark) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: lb, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _coachDetailChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.white60 : Colors.grey[600],
        fontWeight: FontWeight.w500,
      )),
    );
  }

  // ── PLAYER COMPARISON ──
  void _showPlayerComparisonPicker(LocalLineupPlayer player1, Color teamColor, bool isDark, List<LocalLineupPlayer> allPlayers) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final others = allPlayers.where((p) => p.number != player1.number).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('${tr(context, 'Confronta')} ${player1.name} ${tr(context, 'con...')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
          ),
          Expanded(child: ListView.builder(
            itemCount: others.length,
            itemBuilder: (ctx, i) {
              final p2 = others[i];
              final teamName = i < allPlayers.length ~/ 2
                  ? widget.match.homeTeamName : widget.match.awayTeamName;
              final pColor = i < allPlayers.length ~/ 2
                  ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
              return ListTile(
                leading: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.12), shape: BoxShape.circle,
                    border: Border.all(color: pColor.withOpacity(0.3)),
                  ),
                  child: Center(child: Text('${p2.number}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pColor))),
                ),
                title: Text(p2.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx)),
                subtitle: Text('${p2.position} · ${p2.rating.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 12, color: lb)),
                trailing: Icon(Icons.chevron_right_rounded, color: lb, size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MatchPlayerComparisonScreen(
                        initialPlayers: [player1, p2],
                        allPlayers: allPlayers,
                        homeTeamName: widget.match.homeTeamName,
                        awayTeamName: widget.match.awayTeamName,
                        homeShotsData: _homeShotsData,
                        awayShotsData: _awayShotsData,
                        homeDefensiveActions: _homeDefensiveActions,
                        awayDefensiveActions: _awayDefensiveActions,
                      ),
                    ));
                  });
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  // ── NOTIFICHE GIOCATORE PER SINGOLA PARTITA ──
  Future<void> _showMatchPlayerNotifDialog(LocalLineupPlayer player, Color teamColor, bool isDark) async {
    final svc = context.read<PlayerNotificationPreferencesService>();
    await svc.loadSettings();
    final matchId = widget.match.id;
    var settings = svc.getSettingsForPlayer(player.number, player.name, matchId: matchId);
    // Se nessuna notifica attiva, attiva preset essential
    if (!settings.hasActiveNotifications) {
      settings = PlayerNotificationSettings.essentialOnly(
        player.number, player.name, matchId: matchId,
      );
      await svc.saveSettingsForPlayer(settings);
      // Sync globale
      final global = PlayerNotificationSettings.essentialOnly(
        player.number, player.name,
      );
      await svc.saveSettingsForPlayer(global);
      // Sync per nome
      await svc.updateAllSettingsForPlayerByName(player.name, global);
    }
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    // Notification types for match context
    final categories = {
      'Gol & Tiri': {
        'goals': [S.of(context)!.gol, 'Notifica quando segna', Icons.sports_soccer],
        'shotsOnTarget': [localizeShotData(context, 'Tiri in porta'), tr(context, 'Notifica tiri in porta'), Icons.gps_fixed],
        'shotsOffTarget': [localizeShotData(context, 'Tiri totali'), tr(context, 'Notifica tutti i tiri'), Icons.gps_not_fixed],
      },
      S.of(context)!.disciplinaLabel: {
        'yellowCard': ['Cartellino giallo', 'Notifica ammonizione', Icons.square],
        'redCard': ['Cartellino rosso', 'Notifica espulsione', Icons.square],
        'foulCommitted': ['Fallo commesso', 'Notifica falli commessi', Icons.front_hand],
        'foulSuffered': ['Fallo subito', 'Notifica falli subiti', Icons.personal_injury],
      },
      'Gioco': {
        'keyPasses': [S.of(context)!.passaggiChiave, 'Notifica passaggi decisivi', Icons.swap_calls],
        'dribblesSuccessful': [tr(context, 'Dribbling riusciti'), tr(context, 'Notifica dribbling'), Icons.directions_run],
        'offsides': [tr(context, 'Fuorigioco'), 'Notifica fuorigioco', Icons.flag],
      },
    };

    Map<String, bool> getPrefs() => {
      'goals': settings.notifyGoals,
      'assists': settings.notifyAssists,
      'shotsOnTarget': settings.notifyShotsOnTarget,
      'keyPasses': settings.notifyKeyPasses,
      'dribblesSuccessful': settings.notifyDribblesSuccessful,
      'offsides': settings.notifyOffsides,
      'yellowCard': settings.notifyYellowCard,
      'redCard': settings.notifyRedCard,
      'foulCommitted': settings.notifyFoulCommitted,
      'foulSuffered': settings.notifyFoulSuffered,
      'substitutionOn': settings.notifySubstitutionOn,
    };

    void updatePref(String key, bool val) {
      switch (key) {
        case 'goals': settings = settings.copyWith(notifyGoals: val, enabled: true); break;
        case 'assists': settings = settings.copyWith(notifyAssists: val, enabled: true); break;
        case 'shotsOnTarget': settings = settings.copyWith(notifyShotsOnTarget: val, enabled: true); break;
        case 'keyPasses': settings = settings.copyWith(notifyKeyPasses: val, enabled: true); break;
        case 'dribblesSuccessful': settings = settings.copyWith(notifyDribblesSuccessful: val, enabled: true); break;
        case 'offsides': settings = settings.copyWith(notifyOffsides: val, enabled: true); break;
        case 'yellowCard': settings = settings.copyWith(notifyYellowCard: val, enabled: true); break;
        case 'redCard': settings = settings.copyWith(notifyRedCard: val, enabled: true); break;
        case 'foulCommitted': settings = settings.copyWith(notifyFoulCommitted: val, enabled: true); break;
        case 'foulSuffered': settings = settings.copyWith(notifyFoulSuffered: val, enabled: true); break;
        case 'substitutionOn': settings = settings.copyWith(notifySubstitutionOn: val, enabled: true); break;
      }
      svc.saveSettingsForPlayer(settings);
      // Sync to global (no matchId) so favorites screen sees it
      final globalSettings = PlayerNotificationSettings(
        playerId: settings.playerId,
        playerName: settings.playerName,
        enabled: settings.enabled,
        notifyGoals: settings.notifyGoals,
        notifyAssists: settings.notifyAssists,
        notifyShotsOnTarget: settings.notifyShotsOnTarget,
        notifyShotsOffTarget: settings.notifyShotsOffTarget,
        notifyYellowCard: settings.notifyYellowCard,
        notifyRedCard: settings.notifyRedCard,
        notifyFoulCommitted: settings.notifyFoulCommitted,
        notifyFoulSuffered: settings.notifyFoulSuffered,
        notifyKeyPasses: settings.notifyKeyPasses,
        notifyDribblesSuccessful: settings.notifyDribblesSuccessful,
        notifyOffsides: settings.notifyOffsides,
      );
      svc.saveSettingsForPlayer(globalSettings);
      svc.updateAllSettingsForPlayerByName(settings.playerName, globalSettings);
    }

    void setAll(bool val) {
      settings = settings.copyWith(
        enabled: val,
        notifyGoals: val, notifyAssists: val, notifyShotsOnTarget: val,
        notifyKeyPasses: val, notifyDribblesSuccessful: val, notifyOffsides: val,
        notifyYellowCard: val, notifyRedCard: val, notifyFoulCommitted: val,
        notifyFoulSuffered: val, notifySubstitutionOn: val,
      );
      svc.saveSettingsForPlayer(settings);
      // Sync to global
      final globalAll = PlayerNotificationSettings(
        playerId: settings.playerId,
        playerName: settings.playerName,
        enabled: settings.enabled,
        notifyGoals: settings.notifyGoals,
        notifyAssists: settings.notifyAssists,
        notifyShotsOnTarget: settings.notifyShotsOnTarget,
        notifyShotsOffTarget: settings.notifyShotsOffTarget,
        notifyYellowCard: settings.notifyYellowCard,
        notifyRedCard: settings.notifyRedCard,
        notifyFoulCommitted: settings.notifyFoulCommitted,
        notifyFoulSuffered: settings.notifyFoulSuffered,
        notifyKeyPasses: settings.notifyKeyPasses,
        notifyDribblesSuccessful: settings.notifyDribblesSuccessful,
        notifyOffsides: settings.notifyOffsides,
      );
      svc.saveSettingsForPlayer(globalAll);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final prefs = getPrefs();
          final allOn = prefs.values.every((v) => v);
          final anyOn = prefs.values.any((v) => v);
          final activeCount = prefs.values.where((v) => v).length;

          // Color per category
          Color _catColor(String key) {
            switch(key) {
              case 'goals': return const Color(0xFF4CAF50);
              case 'assists': return const Color(0xFF2196F3);
              case 'shotsOnTarget': return const Color(0xFFFF7043);
              case 'keyPasses': return const Color(0xFF26A69A);
              case 'dribblesSuccessful': return const Color(0xFF66BB6A);
              case 'offsides': return const Color(0xFF7E57C2);
              case 'yellowCard': return const Color(0xFFFFCA28);
              case 'redCard': return const Color(0xFFE53935);
              case 'foulCommitted': return const Color(0xFF8D6E63);
              case 'foulSuffered': return const Color(0xFF5C6BC0);
              case 'substitutionOn': return const Color(0xFF42A5F5);
              default: return teamColor;
            }
          }

          Widget _tile(String key, IconData icon, String label, String desc, bool isOn) {
            final color = _catColor(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(color: Colors.transparent, child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () { _haptic.lightImpact(); setSheetState(() { updatePref(key, !isOn); }); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOn ? color.withOpacity(isDark ? 0.12 : 0.06) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isOn ? color.withOpacity(isDark ? 0.3 : 0.2) : isDark ? Colors.white10 : Colors.grey[200]!, width: isOn ? 1.5 : 1)),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(
                        color: color.withOpacity(isOn ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
                      child: key == 'yellowCard'
                        ? Center(child: Container(width: 14, height: 18, decoration: BoxDecoration(
                            color: const Color(0xFFFDD835), borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 4)])))
                        : key == 'redCard'
                          ? Center(child: Container(width: 14, height: 18, decoration: BoxDecoration(
                              color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2),
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4)])))
                          : Icon(icon, size: 20, color: isOn ? color : isDark ? Colors.white30 : Colors.grey[400])),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: isOn ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.grey[500]))),
                      const SizedBox(height: 2),
                      Text(desc, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400])),
                    ])),
                    AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 26,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                          color: isOn ? color : isDark ? Colors.white12 : Colors.grey[300]),
                      child: AnimatedAlign(duration: const Duration(milliseconds: 200),
                        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(margin: const EdgeInsets.all(3), width: 20, height: 20,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)])))),
                  ]),
                ),
              )),
            );
          }

          Widget _header(String t, IconData ic) => Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(children: [
              Icon(ic, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
              const SizedBox(width: 8),
              Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                  color: isDark ? Colors.white38 : Colors.grey[500])),
            ]),
          );

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle + Back + Close
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 0, left: 12, right: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: () { Navigator.of(context).pop(); _showPlayerMatchStats(player, teamColor, isDark); },
                    child: Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey[600]))),
                  const Spacer(),
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey[600]))),
                ])),
              // Header
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: teamColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teamColor.withOpacity(0.3))),
                  child: Center(child: Text('${player.number}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: teamColor)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(player.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                  const SizedBox(height: 2),
                  Text(anyOn ? '$activeCount/${prefs.length} ${tr(context, 'notifiche attive')}' : tr(context, 'Nessuna notifica attiva'),
                      style: TextStyle(fontSize: 13, color: lb)),
                ])),
                GestureDetector(onTap: () { _haptic.lightImpact(); setSheetState(() { setAll(!allOn); }); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: allOn ? teamColor : isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: allOn ? teamColor : isDark ? Colors.white24 : Colors.grey[300]!)),
                    child: Text(allOn ? S.of(context)!.deactivate : S.of(context)!.activateAll,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: allOn ? Colors.white : isDark ? Colors.white70 : Colors.grey[700])))),
              ])),
              // Badge scope
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(S.of(context)!.onlyForThisMatch,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                  ]))),
              Divider(color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
              // Notification tiles
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _header(S.of(context)!.offensive, Icons.sports_soccer),
                  _tile('goals', Icons.sports_soccer, S.of(context)!.goalNotif, S.of(context)!.goalDesc, prefs['goals'] ?? false),
                  _tile('assists', Icons.assistant_rounded, S.of(context)!.assistNotif, S.of(context)!.assistDesc, prefs['assists'] ?? false),
                  _tile('shotsOnTarget', Icons.gps_not_fixed, S.of(context)!.shotsOnTargetNotif, S.of(context)!.shotsOnTargetDesc, prefs['shotsOnTarget'] ?? false),
                  _tile('keyPasses', Icons.trending_up, S.of(context)!.keyPassesNotif, S.of(context)!.keyPassesDesc, prefs['keyPasses'] ?? false),
                  _tile('dribblesSuccessful', Icons.directions_run, S.of(context)!.dribblesNotif, S.of(context)!.dribblesDesc, prefs['dribblesSuccessful'] ?? false),
                  _tile('offsides', Icons.front_hand, S.of(context)!.offsidesNotif, S.of(context)!.offsidesDesc, prefs['offsides'] ?? false),
                  const SizedBox(height: 16),
                  _header(S.of(context)!.discipline, Icons.style),
                  _tile('yellowCard', Icons.square_rounded, S.of(context)!.yellowCardNotif, S.of(context)!.yellowCardDesc, prefs['yellowCard'] ?? false),
                  _tile('redCard', Icons.square_rounded, S.of(context)!.redCardNotif, S.of(context)!.redCardDesc, prefs['redCard'] ?? false),
                  _tile('foulCommitted', Icons.warning_amber, S.of(context)!.foulsCommittedNotif, S.of(context)!.foulsCommittedDesc, prefs['foulCommitted'] ?? false),
                  _tile('foulSuffered', Icons.personal_injury, S.of(context)!.foulsSufferedNotif, S.of(context)!.foulsSufferedDesc, prefs['foulSuffered'] ?? false),
                  const SizedBox(height: 16),
                  _header(tr(context, 'Altro'), Icons.swap_horiz),
                  _tile('substitutionOn', Icons.swap_horiz, S.of(context)!.substitutionNotif, S.of(context)!.substitutionDesc, prefs['substitutionOn'] ?? false),
                ]),
              )),
            ]),
          );
        });
      },
    );
  }

  void _showPlayerMatchStats(
      LocalLineupPlayer player, Color teamColor, bool isDark,
      {List<LocalLineupPlayer> allPlayers = const []}) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    _visualTab = -1;
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final divider = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final sectionBg =
        isDark ? const Color(0xFF222222) : const Color(0xFFF8F8F8);

    Color ratingBg;
    if (player.rating >= 8.0)
      ratingBg = const Color(0xFF1B5E20);
    else if (player.rating >= 7.0)
      ratingBg = const Color(0xFF388E3C);
    else if (player.rating >= 6.5)
      ratingBg = const Color(0xFFF9A825);
    else if (player.rating >= 6.0)
      ratingBg = const Color(0xFFEF6C00);
    else
      ratingBg = const Color(0xFFD32F2F);

    final passAcc = player.passes > 0
        ? ((player.passesCompleted / player.passes) * 100).round()
        : 0;

    // Find substitution info from events
    final events = _generateDetailedMockEvents();
    LocalMatchEvent? subEvent;
    LocalLineupPlayer? linkedPlayer;
    bool wasSubbedOut = false;
    bool wasSubbedIn = false;

    // Check if this player was subbed OUT (starter replaced)
    for (final e in events) {
      if (e.type == 'substitution' && e.playerName == player.name) {
        subEvent = e;
        wasSubbedOut = true;
        // Find the player who came IN (detail = incoming player name)
        if (e.detail != null) {
          final matches = allPlayers.where((p) => p.name == e.detail);
          if (matches.isNotEmpty) linkedPlayer = matches.first;
        }
        break;
      }
    }
    // Check if this player was subbed IN (substitute entering)
    if (!wasSubbedOut) {
      for (final e in events) {
        if (e.type == 'substitution' && e.detail == player.name) {
          subEvent = e;
          wasSubbedIn = true;
          // Find the player who went OUT (playerName = outgoing player)
          final matches = allPlayers.where((p) => p.name == e.playerName);
          if (matches.isNotEmpty) linkedPlayer = matches.first;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(children: [
          // Handle + Close button row
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6, right: 12),
            child: Row(
              children: [
                const Spacer(),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2))),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Player header — fixed
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: teamColor, width: 2.5),
                ),
                child: Center(
                    child: Text('${player.number}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: teamColor))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(player.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tx)),
                    Row(children: [
                      Text(player.position,
                          style: TextStyle(fontSize: 13, color: lb)),
                      const SizedBox(width: 8),
                      Text('${player.minutesPlayed}\'',
                          style: TextStyle(
                              fontSize: 13,
                              color: lb,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: ratingBg, borderRadius: BorderRadius.circular(10)),
                child: Text(player.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              const SizedBox(width: 10),
              // Cuore + Campanella (Builder unificato)
              StatefulBuilder(builder: (ctx, setSheetState) {
                final favSvc = ctx.read<FavoritesService>();
                final notifSvc = ctx.read<PlayerNotificationPreferencesService>();
                final playerId = player.name.hashCode.abs();
                final isFav = favSvc.isPlayerFavorite(playerId);
                final mSet = notifSvc.getSettingsForPlayer(
                  player.number, player.name, matchId: widget.match.id,
                );
                final mOn = mSet.hasActiveNotifications;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  // Cuore preferiti
                  GestureDetector(
                    onTap: () async {
                      HapticService().lightImpact();
                      final seasonData = getPlayerSeasonData(player.name);
                      final teamName = _showHomeLineup ? widget.match.homeTeamName : widget.match.awayTeamName;
                      favSvc.togglePlayerFavorite(playerId);
                      if (!isFav) {
                        favSvc.storePlayerMeta(playerId, {
                          'name': player.name,
                          'position': player.position,
                          'number': player.number,
                          'rating': seasonData?['avgRating'] ?? player.rating,
                          'goals': seasonData?['goals'] ?? 0,
                          'assists': seasonData?['assists'] ?? 0,
                          'appearances': seasonData?['appearances'] ?? 0,
                          'yellowCards': seasonData?['yellowCards'] ?? 0,
                          'redCards': seasonData?['redCards'] ?? 0,
                          'nationality': seasonData?['nationality'] ?? '',
                          'age': seasonData?['age'] ?? 0,
                          'team': teamName,
                          'teamId': _showHomeLineup ? widget.match.homeTeamId : widget.match.awayTeamId,
                        });
                        // Attiva notifiche base — salva con entrambi gli ID
                        final preset = PlayerNotificationSettings.essentialOnly(player.number, player.name);
                        await notifSvc.saveSettingsForPlayer(preset);
                        final matchPreset = PlayerNotificationSettings.essentialOnly(
                          player.number, player.name, matchId: widget.match.id,
                        );
                        await notifSvc.saveSettingsForPlayer(matchPreset);
                        // Sync per nome a tutte le entries
                        await notifSvc.updateAllSettingsForPlayerByName(player.name, preset);
                      } else {
                        // Rimuovi TUTTE le notifiche per questo giocatore
                        await notifSvc.removeAllSettingsForPlayerByName(player.name);
                      }
                      setSheetState(() {});
                    },
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isFav
                            ? Colors.red.withOpacity(0.15)
                            : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFav
                              ? Colors.red.withOpacity(0.4)
                              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                        ),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: isFav ? Colors.red : lb,
                      ),
                    ),
                  ),
                  // Campanella notifiche
                  GestureDetector(
                    onTap: () async {
                      if (!mOn) {
                        final preset = PlayerNotificationSettings.essentialOnly(
                          player.number, player.name, matchId: widget.match.id,
                        );
                        await notifSvc.saveSettingsForPlayer(preset);
                        final global = PlayerNotificationSettings.essentialOnly(
                          player.number, player.name,
                        );
                        await notifSvc.saveSettingsForPlayer(global);
                      }
                      // Navigator.pop(context); // Keep sheet open
                      {
                        await _showMatchPlayerNotifDialog(player, teamColor, isDark);
                        setSheetState(() {});
                      }
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: mOn
                            ? teamColor.withOpacity(0.15)
                            : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: mOn
                              ? teamColor.withOpacity(0.4)
                              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                        ),
                      ),
                      child: Icon(
                        mOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        size: 20,
                        color: mOn ? teamColor : lb,
                      ),
                    ),
                  ),
                ]);
              }),
            ]),
          ),
          Container(height: 1, color: divider),

          // "Vedi profilo completo" + "Confronta giocatore"
          Row(children: [
            // Profilo completo
            Expanded(child: GestureDetector(
              onTap: () {
                final nav = Navigator.of(context); nav.pop(); Future.delayed(const Duration(milliseconds: 300), () { nav.push(MaterialPageRoute(builder: (_) => MatchPlayerProfileScreen(player: player, teamName: _showHomeLineup ? widget.match.homeTeamName : widget.match.awayTeamName, teamColor: teamColor))); });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: divider))),
                child: Row(children: [
                  Icon(Icons.person_outline_rounded, color: teamColor, size: 18),
                  const SizedBox(width: 8),
                  Text(S.of(context)!.profile,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: teamColor)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: teamColor, size: 20),
                ]),
              ),
            )),
            Container(width: 1, height: 40, color: divider),
            // Confronta
            Expanded(child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showPlayerComparisonPicker(player, teamColor, isDark, allPlayers);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: divider))),
                child: Row(children: [
                  Icon(Icons.compare_arrows_rounded, color: lb, size: 18),
                  const SizedBox(width: 8),
                  Text(S.of(context)!.compare,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: lb, size: 20),
                ]),
              ),
            )),
          ]),

          // Substitution info (if applicable)
          if (subEvent != null) ...[
            GestureDetector(
              onTap: linkedPlayer != null
                  ? () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 250), () {
                        _showPlayerMatchStats(linkedPlayer!, teamColor, isDark,
                            allPlayers: allPlayers);
                      });
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: divider))),
                child: Row(children: [
                  // Sub icon
                  Icon(
                    wasSubbedOut
                        ? Icons.subdirectory_arrow_right_rounded
                        : Icons.subdirectory_arrow_left_rounded,
                    color: wasSubbedOut
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF66BB6A),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  // Minute
                  Text('${subEvent!.minute}\'',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: wasSubbedOut
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF66BB6A))),
                  const SizedBox(width: 12),
                  // Label + player name
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            wasSubbedOut ? tr(context, 'Sostituito da:') : tr(context, 'Sostituito per:'),
                            style: TextStyle(fontSize: 11, color: lb)),
                        Text(
                            linkedPlayer?.name ??
                                (wasSubbedOut
                                    ? subEvent!.detail ?? ''
                                    : subEvent!.playerName),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tx)),
                      ])),
                  // Linked player badge
                  if (linkedPlayer != null) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: teamColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Center(
                          child: Text('${linkedPlayer!.number}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: teamColor))),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, color: lb, size: 20),
                  ],
                ]),
              ),
            ),
          ],

          // Minutes played row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: divider))),
            child: Row(children: [
              Icon(Icons.access_time_rounded, color: lb, size: 18),
              const SizedBox(width: 10),
              Text(S.of(context)!.minutesPlayedLabel, style: TextStyle(fontSize: 14, color: lb)),
              const Spacer(),
              Text('${player.minutesPlayed}\'',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
            ]),
          ),

          // Scrollable stats with visual mini-menu
          Expanded(
            child: StatefulBuilder(
              builder: (context, setTabState) {
                return Column(children: [
                  // ── MINI-MENU TABS ──
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      _buildVisualTab(S.of(context)!.tiriSection, Icons.gps_fixed_rounded, _visualTab == 0, () {
                        setTabState(() => _visualTab = _visualTab == 0 ? -1 : 0);
                      }, isDark),
                      _buildVisualTab(S.of(context)!.passaggiRLabel, Icons.swap_calls_rounded, _visualTab == 1, () {
                        setTabState(() => _visualTab = _visualTab == 1 ? -1 : 1);
                      }, isDark),
                      _buildVisualTab(S.of(context)!.dribLabel, Icons.directions_run_rounded, _visualTab == 2, () {
                        setTabState(() => _visualTab = _visualTab == 2 ? -1 : 2);
                      }, isDark),
                      _buildVisualTab(S.of(context)!.difLabel, Icons.shield_outlined, _visualTab == 3, () {
                        setTabState(() => _visualTab = _visualTab == 3 ? -1 : 3);
                      }, isDark),
                    ]),
                  ),

                  // ── CONTENT BASED ON TAB ──
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        // ── HEATMAP (solo in home, nessuna tab selezionata) ──
                        if (_visualTab == -1)
                          PlayerHeatmapCard(
                            playerName: player.name,
                            position: player.position,
                            touches: player.touches,
                            teamColor: teamColor,
                            isDark: isDark,
                          ),
                        // ════════════════════════════
                        //  TAB 0: TIRI
                        // ════════════════════════════
                        if (_visualTab == 0) ...[
                          PlayerShotMapCard(
                            shots: (_showHomeLineup ? _homeShotsData : _awayShotsData)
                                .where((s) => s.playerName == player.name)
                                .toList(),
                            teamColor: teamColor,
                            isDark: isDark,
                          ),
                          _buildStatSectionHeader(S.of(context)!.attaccoSection, Icons.sports_soccer,
                              const Color(0xFF2E7D32), sectionBg),
                          if (player.goals > 0)
                            _buildStatRow(S.of(context)!.gol, '${player.goals}', tx, lb, divider,
                                highlight: true),
                          if (player.xG > 0)
                            _buildStatRow(tr(context, 'Goal attesi (xG)'),
                                player.xG.toStringAsFixed(2), tx, lb, divider),
                          if (player.assists > 0)
                            _buildStatRow(tr(context, 'Assist'), '${player.assists}', tx, lb, divider,
                                highlight: true),
                          if (player.xA > 0)
                            _buildStatRow(tr(context, 'Assist previsti (xA)'),
                                player.xA.toStringAsFixed(2), tx, lb, divider),
                          _buildStatRow(
                              localizeShotData(context, 'Tiri totali'), '${player.shots}', tx, lb, divider),
                          _buildStatRow(localizeShotData(context, 'Tiri in porta'), '${player.shotsOnTarget}', tx,
                              lb, divider),
                          if (player.keyPasses > 0)
                            _buildStatRow(S.of(context)!.passaggiChiave, '${player.keyPasses}', tx,
                                lb, divider),
                          if (player.offsides > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Fuorigioco'), '${player.offsides}', tx, lb, divider),
                        ],

                        // ════════════════════════════
                        //  TAB 1: PASSAGGI
                        // ════════════════════════════
                        if (_visualTab == 1) ...[
                          PlayerPassMapCard(
                            playerName: player.name,
                            position: player.position,
                            passes: player.passes,
                            passesCompleted: player.passesCompleted,
                            keyPasses: player.keyPasses,
                            crosses: player.crosses,
                            crossesCompleted: player.crossesCompleted,
                            teamColor: teamColor,
                            isDark: isDark,
                          ),
                          _buildStatSectionHeader(
                              S.of(context)!.possessoSection,
                              Icons.compare_arrows_rounded,
                              const Color(0xFF1565C0),
                              sectionBg),
                          _buildStatRow(S.of(context)!.tocchi, '${player.touches}', tx, lb, divider),
                          _buildStatRow(
                              S.of(context)!.passaggiPrecisilabel,
                              '${player.passesCompleted}/${player.passes} ($passAcc%)',
                              tx, lb, divider),
                          if (player.crosses > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Cross (precisi)'),
                                '${player.crosses} (${player.crossesCompleted})',
                                tx, lb, divider),
                          if (player.keyPasses > 0)
                            _buildStatRow(S.of(context)!.passaggiChiave, '${player.keyPasses}', tx,
                                lb, divider),
                          if (player.ballsLost > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Palla persa'), '${player.ballsLost}', tx, lb, divider),
                        ],

                        // ════════════════════════════
                        //  TAB 2: DRIBBLING
                        // ════════════════════════════
                        if (_visualTab == 2) ...[
                          _buildStatSectionHeader(
                              S.of(context)!.dribblingLabel,
                              Icons.directions_run_rounded,
                              const Color(0xFF7B1FA2),
                              sectionBg),
                          if (player.dribbles > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Dribbling (riusciti)'),
                                '${player.dribbles} (${player.dribblesSuccessful})',
                                tx, lb, divider),
                          _buildStatRow(S.of(context)!.tocchi, '${player.touches}', tx, lb, divider),
                          if (player.foulsWon > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Falli subiti'), '${player.foulsWon}', tx, lb, divider),
                          if (player.ballsLost > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Palla persa'), '${player.ballsLost}', tx, lb, divider),
                          if (player.offsides > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Fuorigioco'), '${player.offsides}', tx, lb, divider),
                        ],

                        // ════════════════════════════
                        //  TAB 3: DIFESA + DISCIPLINA
                        // ════════════════════════════
                        if (_visualTab == 3) ...[
                          PlayerDefensiveMapCard(
                            actions: (_showHomeLineup ? _homeDefensiveActions : _awayDefensiveActions)
                                .where((a) => a.playerName == player.name)
                                .toList(),
                            teamColor: teamColor,
                            isDark: isDark,
                          ),
                          _buildStatSectionHeader(S.of(context)!.difesaSection, Icons.shield_outlined,
                              Color(0xFFE65100), sectionBg),
                          if (player.tackles > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Contrasti vinti'),
                                '${player.tackles} (${player.tacklesWon})',
                                tx, lb, divider),
                          if (player.interceptions > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Intercetti'), '${player.interceptions}', tx, lb, divider),
                          if (player.clearances > 0)
                            _buildStatRow(localizeShotData(context, 'Chiusure difensive'), '${player.clearances}',
                                tx, lb, divider),
                          if (player.recoveries > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Recuperi'), '${player.recoveries}', tx, lb, divider),
                          if (player.duelsTotal > 0)
                            _buildStatRow(
                                'Duelli a terra (vinti)',
                                '${player.duelsTotal} (${player.duelsWon})',
                                tx, lb, divider),
                          if (player.aerialTotal > 0)
                            _buildStatRow(
                                'Duelli aerei (vinti)',
                                '${player.aerialTotal} (${player.aerialWon})',
                                tx, lb, divider),
                          _buildStatSectionHeader(S.of(context)!.disciplinaLabel, Icons.style_rounded,
                              const Color(0xFFF9A825), sectionBg),
                          if (player.fouls > 0)
                            _buildStatRow(
                                tr(context, 'Falli commessi'), '${player.fouls}', tx, lb, divider),
                          if (player.foulsWon > 0)
                            _buildStatRow(
                                localizeShotData(context, 'Falli subiti'), '${player.foulsWon}', tx, lb, divider),
                          if (player.yellowCards > 0)
                            _buildStatRow(
                                S.of(context)!.ammonizioni, '${player.yellowCards}', tx, lb, divider,
                                valueColor: const Color(0xFFF9A825)),
                          if (player.redCards > 0)
                            _buildStatRow(
                                'Espulsioni', '${player.redCards}', tx, lb, divider,
                                valueColor: const Color(0xFFD32F2F)),
                        ],
                      ],
                    ),
                  ),
                ]);
              },
            ),
          ),

        ]),
      ),
    );
  }


  Widget _buildVisualTab(String label, IconData icon, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white.withOpacity(0.12) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                    : null,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                    : (isDark ? Colors.grey[500] : Colors.grey[400])),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                        : (isDark ? Colors.grey[500] : Colors.grey[400]))),
              ]),
            ),
            if (isSelected)
              Positioned(
                top: 2, right: 4,
                child: Icon(Icons.close_rounded, size: 12,
                    color: isDark ? Colors.white30 : Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSectionHeader(
      String title, IconData icon, Color color, Color sectionBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(top: 4),
      color: sectionBg,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _buildStatRow(
      String label, String value, Color tx, Color lb, Color divider,
      {bool highlight = false, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: divider, width: 0.5))),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: highlight ? tx : lb,
                    fontWeight:
                        highlight ? FontWeight.w700 : FontWeight.w400))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? tx)),
      ]),
    );
  }

  Widget _buildPitchPlayer(LocalLineupPlayer player, Offset pos, double pitchW,
      double pitchH, Color teamColor, bool isDark,
      {List<LocalLineupPlayer> allPlayers = const []}) {
    final x = pos.dx * pitchW;
    final y = (1.0 - pos.dy) * pitchH;
    // Responsive dot size: BIG — min 46, max 58
    final dotSize = (pitchH * 0.12).clamp(46.0, 58.0);

    // Rating color
    Color ratingBg;
    if (player.rating >= 8.0)
      ratingBg = const Color(0xFF1B5E20);
    else if (player.rating >= 7.0)
      ratingBg = const Color(0xFF388E3C);
    else if (player.rating >= 6.5)
      ratingBg = const Color(0xFFF9A825);
    else if (player.rating >= 6.0)
      ratingBg = const Color(0xFFEF6C00);
    else
      ratingBg = const Color(0xFFD32F2F);

    // Event badges
    final hasYellow = player.yellowCards > 0;
    final hasRed = player.redCards > 0;
    // Substituted = starter who played less than 90 minutes
    final wasSubbed = player.minutesPlayed < 90 && player.minutesPlayed > 0;

    final fontSize = (dotSize * 0.36).clamp(14.0, 20.0);
    final nameFontSize = (dotSize * 0.20).clamp(9.0, 11.0);
    final ratingFontSize = (dotSize * 0.22).clamp(10.0, 13.0);
    final badgeSize = dotSize * 0.38;

    return Positioned(
      left: x - dotSize / 2 - 16,
      top: y - dotSize / 2 - 4,
      child: GestureDetector(
        onTap: () => _showPlayerMatchStats(player, teamColor, isDark,
            allPlayers: allPlayers),
        child: SizedBox(
          width: dotSize + 32,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Player circle with event badges
            SizedBox(
              width: dotSize + 12,
              height: dotSize + 12,
              child: Stack(clipBehavior: Clip.none, children: [
                // Main circle — white with team color border
                Center(
                    child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: teamColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Center(
                      child: Text(
                    '${player.number}',
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        height: 1),
                  )),
                )),
                // Yellow/Red card badge — top right
                if (hasYellow || hasRed)
                  Positioned(
                    top: -2,
                    right: 2,
                    child: Container(
                      width: dotSize * 0.28,
                      height: dotSize * 0.38,
                      decoration: BoxDecoration(
                        color: hasRed
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFF9A825),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 3)
                        ],
                      ),
                    ),
                  ),
                // Substitution badge — top left (red arrow out)
                if (wasSubbed)
                  Positioned(
                    top: -3,
                    left: 0,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 3)
                        ],
                      ),
                      child: Icon(Icons.swap_horiz_rounded,
                          size: badgeSize * 0.65,
                          color: const Color(0xFFEF5350)),
                    ),
                  ),
              ]),
            ),
            // Rating badge — overlaps circle bottom
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: ratingBg,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 4)
                  ],
                ),
                child: Text(
                  player.rating.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: ratingFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2),
                ),
              ),
            ),
            // Player name: "27 N. Semedo"
            Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                '${player.number} ${_shortName(player.name)}',
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.9), blurRadius: 4)
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return name;
    if (name.length <= 10) return name;
    // "Luis Alberto" → "L. Alberto", "Theo Hernandez" → "T. Hernandez"
    return '${parts.first[0]}. ${parts.last}';
  }

  Widget _buildBenchPlayerItem(LocalLineupPlayer player, Color teamColor,
      bool isDark, Color tx, Color lb, Color cardBg,
      {List<LocalLineupPlayer> allPlayers = const []}) {
    Color ratingBg;
    if (player.rating >= 8.0)
      ratingBg = const Color(0xFF1B5E20);
    else if (player.rating >= 7.0)
      ratingBg = const Color(0xFF388E3C);
    else if (player.rating >= 6.5)
      ratingBg = const Color(0xFFF9A825);
    else if (player.rating >= 6.0)
      ratingBg = const Color(0xFFEF6C00);
    else
      ratingBg = const Color(0xFFD32F2F);

    return GestureDetector(
        onTap: () {
          if (player.minutesPlayed > 0) {
            _showPlayerMatchStats(player, teamColor, isDark, allPlayers: allPlayers);
          } else {
            final teamName = _showHomeLineup ? widget.match.homeTeamName : widget.match.awayTeamName;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchPlayerProfileScreen(player: player, teamName: teamName, teamColor: teamColor)));
          }
        },




        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text('${player.number}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: teamColor))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(player.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tx)),
                  Text(player.position,
                      style: TextStyle(fontSize: 11, color: lb)),
                ])),
            if (player.rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: ratingBg, borderRadius: BorderRadius.circular(6)),
                child: Text(player.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('-',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
          ]),
        ));
  }

  List<LocalLineupPlayer> _generateMockBench(bool isHome) {
    if (isHome) {
      return [
        LocalLineupPlayer(
            number: 22,
            name: 'Maximiano',
            position: 'GK',
            rating: 0.0,
            minutesPlayed: 0),
        LocalLineupPlayer(
            number: 5,
            name: 'Vecino',
            position: 'CM',
            rating: 6.2,
            passes: 12,
            passesCompleted: 10,
            touches: 18,
            minutesPlayed: 22,
            tackles: 1,
            tacklesWon: 1,
            fouls: 1,
            duelsTotal: 3,
            duelsWon: 2),
        LocalLineupPlayer(
            number: 11,
            name: 'Felipe Anderson',
            position: 'RW',
            rating: 7.4,
            passes: 14,
            passesCompleted: 10,
            touches: 24,
            shots: 2,
            shotsOnTarget: 1,
            goals: 1,
            xG: 0.48,
            dribbles: 3,
            dribblesSuccessful: 2,
            ballsLost: 2,
            offsides: 1,
            minutesPlayed: 38,
            duelsTotal: 5,
            duelsWon: 3),
        LocalLineupPlayer(
            number: 6,
            name: 'Marcos Antonio',
            position: 'CM',
            rating: 0.0,
            minutesPlayed: 25),
        LocalLineupPlayer(
            number: 14,
            name: 'Hysaj',
            position: 'RB',
            rating: 0.0,
            minutesPlayed: 0),
      ];
    } else {
      return [
        LocalLineupPlayer(
            number: 83,
            name: 'Mirante',
            position: 'GK',
            rating: 0.0,
            minutesPlayed: 0),
        LocalLineupPlayer(
            number: 7,
            name: 'Adli',
            position: 'CM',
            rating: 6.0,
            passes: 8,
            passesCompleted: 6,
            touches: 14,
            minutesPlayed: 18,
            duelsTotal: 2,
            duelsWon: 1),
        LocalLineupPlayer(
            number: 33,
            name: 'Krunic',
            position: 'CM',
            rating: 0.0,
            minutesPlayed: 0),
        LocalLineupPlayer(
            number: 91,
            name: 'Jovic',
            position: 'ST',
            rating: 0.0,
            minutesPlayed: 15),
        LocalLineupPlayer(
            number: 46,
            name: 'Gabbia',
            position: 'CB',
            rating: 0.0,
            minutesPlayed: 0),
        LocalLineupPlayer(
            number: 56,
            name: 'Saelemaekers',
            position: 'RW',
            rating: 0.0,
            minutesPlayed: 7),
      ];
    }
  }

  // ============================================================================
  // TAB 5: INFO
  // ============================================================================
  // ══════════════════════════════════════════════════════════════════



  // ══════════════════════════════════════════════════════════════════
  // PRE-MATCH TABS
  // ══════════════════════════════════════════════════════════════════

  Widget _buildPreMatchInfoTab(ThemeData theme, bool isDark) {
    return PreMatchInfoTab(
      homeTeamName: widget.match.homeTeamName,
      awayTeamName: widget.match.awayTeamName,
      homeColor: _getTeamColor(widget.match.homeTeamName),
      awayColor: _getTeamColor(widget.match.awayTeamName),
      leagueName: widget.match.leagueName,
      date: widget.match.date,
      time: widget.match.time,
      venue: widget.match.venue,
      round: widget.match.round,
      referee: widget.match.referee,
    );
  }





  // ── Probable Lineups Tab ──



  // ── Form Tab (Recent 5 matches) ──
  Widget _buildProbableLineupsTab(ThemeData theme, bool isDark) {
    return ProbableLineupsTab(
      homeName: widget.match.homeTeamName,
      awayName: widget.match.awayTeamName,
      homeColor: _getTeamColor(widget.match.homeTeamName),
      awayColor: _getTeamColor(widget.match.awayTeamName),
      onPlayerTap: (info) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MatchPlayerProfileScreen(
            player: info.player,
            teamName: info.teamName,
            teamColor: info.teamColor,
          ),
        ));
      },
    );
  }

  Widget _buildFormTab(ThemeData theme, bool isDark) {
    final homeName = widget.match.homeTeamName;
    final awayName = widget.match.awayTeamName;
    return MatchFormTab(
      homeName: homeName,
      awayName: awayName,
      homeColor: _getTeamColor(homeName),
      awayColor: _getTeamColor(awayName),
      homeLogoUrl: _getTeamLogoUrl(homeName),
      awayLogoUrl: _getTeamLogoUrl(awayName),
      homeForm: _getTeamForm(homeName),
      awayForm: _getTeamForm(awayName),
      opponentLogoUrl: _getTeamLogoUrl,
      opponentColor: _getTeamColor,
      onMatchTap: (m) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
        );
      },
    );
  }



  // ── Standings Comparison Tab ──
  Widget _buildStandingsComparisonTab(ThemeData theme, bool isDark) {
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final homeName = widget.match.homeTeamName;
    final awayName = widget.match.awayTeamName;

    // Full Serie A standings
    final standings = [
      {'pos': 1, 'team': 'Inter', 'pts': 83, 'p': 35, 'w': 26, 'd': 5, 'l': 4, 'gf': 78, 'ga': 25, 'gd': '+53', 'form': 'WWDWW'},
      {'pos': 2, 'team': 'Milan', 'pts': 72, 'p': 35, 'w': 22, 'd': 6, 'l': 7, 'gf': 65, 'ga': 38, 'gd': '+27', 'form': 'WLWWD'},
      {'pos': 3, 'team': 'Juventus', 'pts': 68, 'p': 35, 'w': 20, 'd': 8, 'l': 7, 'gf': 55, 'ga': 30, 'gd': '+25', 'form': 'DDWWL'},
      {'pos': 4, 'team': 'Atalanta', 'pts': 65, 'p': 35, 'w': 19, 'd': 8, 'l': 8, 'gf': 64, 'ga': 38, 'gd': '+26', 'form': 'WWWLW'},
      {'pos': 5, 'team': 'Bologna', 'pts': 62, 'p': 35, 'w': 18, 'd': 8, 'l': 9, 'gf': 49, 'ga': 32, 'gd': '+17', 'form': 'DWWLD'},
      {'pos': 6, 'team': 'Roma', 'pts': 58, 'p': 35, 'w': 17, 'd': 7, 'l': 11, 'gf': 52, 'ga': 42, 'gd': '+10', 'form': 'WLDWL'},
      {'pos': 7, 'team': 'Lazio', 'pts': 55, 'p': 35, 'w': 16, 'd': 7, 'l': 12, 'gf': 48, 'ga': 38, 'gd': '+10', 'form': 'LWWDL'},
      {'pos': 8, 'team': 'Fiorentina', 'pts': 51, 'p': 35, 'w': 14, 'd': 9, 'l': 12, 'gf': 44, 'ga': 40, 'gd': '+4', 'form': 'DLWLW'},
      {'pos': 9, 'team': 'Torino', 'pts': 49, 'p': 35, 'w': 13, 'd': 10, 'l': 12, 'gf': 36, 'ga': 36, 'gd': '0', 'form': 'DDLWD'},
      {'pos': 10, 'team': 'Napoli', 'pts': 49, 'p': 35, 'w': 14, 'd': 7, 'l': 14, 'gf': 52, 'ga': 48, 'gd': '+4', 'form': 'LWDLW'},
      {'pos': 11, 'team': 'Monza', 'pts': 45, 'p': 35, 'w': 12, 'd': 9, 'l': 14, 'gf': 38, 'ga': 44, 'gd': '-6', 'form': 'DLLWD'},
      {'pos': 12, 'team': 'Genoa', 'pts': 42, 'p': 35, 'w': 11, 'd': 9, 'l': 15, 'gf': 35, 'ga': 42, 'gd': '-7', 'form': 'LDWDL'},
      {'pos': 13, 'team': 'Lecce', 'pts': 38, 'p': 35, 'w': 9, 'd': 11, 'l': 15, 'gf': 30, 'ga': 44, 'gd': '-14', 'form': 'DLDLL'},
      {'pos': 14, 'team': 'Verona', 'pts': 37, 'p': 35, 'w': 9, 'd': 10, 'l': 16, 'gf': 32, 'ga': 48, 'gd': '-16', 'form': 'LLWDL'},
      {'pos': 15, 'team': 'Udinese', 'pts': 36, 'p': 35, 'w': 9, 'd': 9, 'l': 17, 'gf': 34, 'ga': 50, 'gd': '-16', 'form': 'DLLDW'},
      {'pos': 16, 'team': 'Empoli', 'pts': 34, 'p': 35, 'w': 8, 'd': 10, 'l': 17, 'gf': 28, 'ga': 44, 'gd': '-16', 'form': 'LDDLL'},
      {'pos': 17, 'team': 'Cagliari', 'pts': 33, 'p': 35, 'w': 8, 'd': 9, 'l': 18, 'gf': 32, 'ga': 52, 'gd': '-20', 'form': 'LDLWL'},
      {'pos': 18, 'team': 'Frosinone', 'pts': 28, 'p': 35, 'w': 6, 'd': 10, 'l': 19, 'gf': 36, 'ga': 58, 'gd': '-22', 'form': 'LLLDD'},
      {'pos': 19, 'team': 'Sassuolo', 'pts': 22, 'p': 35, 'w': 4, 'd': 10, 'l': 21, 'gf': 28, 'ga': 64, 'gd': '-36', 'form': 'LLDLL'},
      {'pos': 20, 'team': 'Salernitana', 'pts': 16, 'p': 35, 'w': 3, 'd': 7, 'l': 25, 'gf': 22, 'ga': 68, 'gd': '-46', 'form': 'LLLLL'},
    ];

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        // Filters row (flat, like main standings)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _standingsFilterChip(tr(context, 'Totale'), true, theme),
            const SizedBox(width: 6),
            _standingsFilterChip(tr(context, 'Casa'), false, theme),
            const SizedBox(width: 6),
            _standingsFilterChip(tr(context, 'Trasferta'), false, theme),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 14, color: theme.primaryColor),
                const SizedBox(width: 4),
                Text(tr(context, 'Rendimento'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor)),
              ]),
            ),
          ]),
        ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
            border: Border(left: BorderSide(width: 3, color: Colors.transparent), bottom: BorderSide(width: 0.5, color: divider)),
          ),
          child: Row(children: [
            SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: Text(tr(context, 'Squadra'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb))),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'G'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'V'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'P'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'S'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'GF'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'GS'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 30, child: Text(standingsAbbr(context, 'DR'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 30, child: Text(standingsAbbr(context, 'Pt'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.primaryColor), textAlign: TextAlign.center)),
            SizedBox(width: 80, child: Text(tr(context, 'Forma'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb), textAlign: TextAlign.center)),
          ]),
        ),
        // Rows
        Container(
          color: cardBg,
          child: Column(children: [
            ...standings.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final teamName = s['team'] as String;
              final isMatch = teamName == homeName || teamName == awayName;
              final teamColor = _getTeamColor(teamName);
              final pos = s['pos'] as int;
              final isLast = i == standings.length - 1;

              // Zone colors
              Color? zoneBg;
              Color? zoneBar;
              if (pos <= 4) { zoneBar = const Color(0xFF4CAF50); }
              else if (pos == 5 || pos == 6) { zoneBar = const Color(0xFF2196F3); }
              else if (pos == 7) { zoneBar = const Color(0xFFFFA726); }
              else if (pos >= 18) { zoneBar = const Color(0xFFE53935); }

              final abbr = teamName.length > 3 ? teamName.substring(0, 3).toUpperCase() : teamName.toUpperCase();

              return GestureDetector(
                onTap: () => _navigateToTeamDetail(0, teamName, null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMatch ? (teamColor.withOpacity(isDark ? 0.15 : 0.08)) : null,
                    border: Border(
                      left: BorderSide(width: 3, color: zoneBar ?? Colors.transparent),
                      bottom: isLast ? BorderSide.none : BorderSide(width: 0.5, color: divider),
                    ),
                    borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
                  ),
                  child: Row(children: [
                    // Position
                    SizedBox(width: 24, child: Center(child: Text('$pos', style: TextStyle(fontSize: 13, fontWeight: isMatch ? FontWeight.w900 : FontWeight.w600, color: tx)))),
                    const SizedBox(width: 8),
                    // Team logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: _getTeamLogoUrl(teamName),
                        width: 24, height: 24,
                        errorWidget: (_, __, ___) => Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text(abbr, style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: teamColor))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 4, child: Text(teamName,
                        style: TextStyle(fontSize: 13, fontWeight: isMatch ? FontWeight.w800 : FontWeight.w500, color: isMatch ? teamColor : tx),
                        overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 26, child: Text('${s['p']}', style: TextStyle(fontSize: 11, color: lb), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['w']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['d'] ?? s['dd'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['l']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['gf']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['ga']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 30, child: Text('${s['gd']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb), textAlign: TextAlign.center)),
                    SizedBox(width: 30, child: Text('${s['pts']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.primaryColor), textAlign: TextAlign.center)),
                    SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (int fi = 0; fi < (s['form'] as String? ?? 'DDDDD').split('').length; fi++) ...[
                        Builder(builder: (ctx) {
                          final f = (s['form'] as String? ?? 'DDDDD').split('')[fi];
                          final c = f == 'W' ? const Color(0xFF4CAF50) : f == 'D' ? const Color(0xFFF9A825) : const Color(0xFFE53935);
                          final label = f == 'W' ? 'V' : f == 'D' ? 'P' : 'S';
                          final resultText = f == 'W' ? 'Vittoria' : f == 'D' ? 'Pareggio' : 'Sconfitta';
                          return Tooltip(
                            message: '$resultText\nGiornata ${35 - fi}',
                            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Container(
                              width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                              child: Center(child: Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white))),
                            ),
                          );
                        }),
                      ],
                    ])),
                  ]),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 12),
        // Legend
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Regolamento'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
            const SizedBox(height: 10),
            _legendItem(const Color(0xFF4CAF50), 'Champions League'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFF2196F3), 'UEFA Europa League'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFFFFA726), 'Conference League Qualification'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFFE53935), tr(context, 'Retrocessione')),
            const SizedBox(height: 14),
            Divider(height: 1, color: divider),
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: [
              _legendAbbr('G', tr(context, 'Partite giocate'), lb),
              _legendAbbr('V', tr(context, 'Vittorie'), lb),
              _legendAbbr('P', tr(context, 'Pareggi'), lb),
              _legendAbbr('S', tr(context, 'Sconfitte'), lb),
              _legendAbbr('GF', tr(context, 'Gol fatti'), lb),
              _legendAbbr('GS', tr(context, 'Gol subiti'), lb),
              _legendAbbr('DR', tr(context, 'Differenza reti'), lb),
              _legendAbbr(standingsAbbr(context, 'Pt'), tr(context, 'Punti'), lb),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _getTeamLogoUrl(String teamName) {
    const logos = {
      'Inter': 'https://media.api-sports.io/football/teams/505.png',
      'Milan': 'https://media.api-sports.io/football/teams/489.png',
      'Juventus': 'https://media.api-sports.io/football/teams/496.png',
      'Atalanta': 'https://media.api-sports.io/football/teams/499.png',
      'Bologna': 'https://media.api-sports.io/football/teams/500.png',
      'Roma': 'https://media.api-sports.io/football/teams/497.png',
      'Lazio': 'https://media.api-sports.io/football/teams/487.png',
      'Fiorentina': 'https://media.api-sports.io/football/teams/502.png',
      'Torino': 'https://media.api-sports.io/football/teams/503.png',
      'Napoli': 'https://media.api-sports.io/football/teams/492.png',
      'Monza': 'https://media.api-sports.io/football/teams/1579.png',
      'Genoa': 'https://media.api-sports.io/football/teams/495.png',
      'Lecce': 'https://media.api-sports.io/football/teams/867.png',
      'Verona': 'https://media.api-sports.io/football/teams/504.png',
      'Udinese': 'https://media.api-sports.io/football/teams/494.png',
      'Empoli': 'https://media.api-sports.io/football/teams/511.png',
      'Cagliari': 'https://media.api-sports.io/football/teams/490.png',
      'Frosinone': 'https://media.api-sports.io/football/teams/512.png',
      'Sassuolo': 'https://media.api-sports.io/football/teams/488.png',
      'Salernitana': 'https://media.api-sports.io/football/teams/514.png',
    };
    return logos[teamName] ?? '';
  }



  String _formTooltipText(String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    String score;
    if (result == 'W') { score = isHome ? '2:0' : '0:1'; }
    else if (result == 'D') { score = '1:1'; }
    else { score = isHome ? '0:2' : '1:3'; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    final day = 28 - index * 7;
    final month = day > 0 ? '03' : '02';
    final d = day > 0 ? day : day + 28;
    return '$score ($home - $away)\n${d.toString().padLeft(2, "0")}.$month.2024';
  }

  void _navigateToFormMatch(BuildContext context, String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    int hs, as_;
    if (result == 'W') { hs = isHome ? 2 : 0; as_ = isHome ? 0 : 1; }
    else if (result == 'D') { hs = 1; as_ = 1; }
    else { hs = isHome ? 0 : 1; as_ = isHome ? 2 : 3; }
    if (!isHome) { final tmp = hs; hs = as_; as_ = tmp; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchDetailScreen(
      match: SoccerMatch(id: (teamName + actual + index.toString()).hashCode.abs(),
        date: DateTime.now(), time: '20:45', status: 'FT', venue: '',
        homeTeamId: 0, awayTeamId: 0, homeTeamName: home, awayTeamName: away,
        homeScore: hs, awayScore: as_, leagueName: 'Serie A', season: 2023, round: 'Giornata ${35 - index}'),
    )));
  }

  Widget _standingsFilterChip(String label, bool active, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? theme.primaryColor : Colors.grey.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? Colors.white : Colors.grey[500],
      )),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
    ]);
  }

  Widget _legendAbbr(String abbr, String label, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(abbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: lb)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]);
  }

  // ── Pre-match data helpers ──

  Color _getTeamColor(String teamName) {
    const colors = <String, Color>{
      'Roma': Color(0xFFAD1A1A),
      'Lazio': Color(0xFF87CEEB),
      'Inter': Color(0xFF003DA5),
      'Milan': Color(0xFFE3001B),
      'Juventus': Color(0xFF000000),
      'Napoli': Color(0xFF009FE3),
      'Atalanta': Color(0xFF1A1A6C),
      'Bologna': Color(0xFF1A2B6D),
      'Fiorentina': Color(0xFF6F2DA8),
      'Torino': Color(0xFF8B1A1A),
      'Verona': Color(0xFF003DA5),
      'Monza': Color(0xFFCE0120),
    };
    return colors[teamName] ?? const Color(0xFF1565C0);
  }


  List<Map<String, String>> _getCoachCareer(String coachName) {
    const careers = {
      'José Mourinho': [
        {'team': 'Roma', 'period': '2021-2024', 'trophy': '🏆 Conference League', 'role': 'Allenatore'},
        {'team': 'Tottenham', 'period': '2019-2021', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Manchester United', 'period': '2016-2018', 'trophy': '🏆 Europa League', 'role': 'Allenatore'},
        {'team': 'Chelsea', 'period': '2013-2015', 'trophy': '🏆 Premier League', 'role': 'Allenatore'},
        {'team': 'Real Madrid', 'period': '2010-2013', 'trophy': '🏆 Liga', 'role': 'Allenatore'},
        {'team': 'Inter', 'period': '2008-2010', 'trophy': '🏆 Triplete', 'role': 'Allenatore'},
        {'team': 'Chelsea', 'period': '2004-2007', 'trophy': '🏆🏆 Premier League', 'role': 'Allenatore'},
        {'team': 'Porto', 'period': '2002-2004', 'trophy': '🏆 Champions League', 'role': 'Allenatore'},
      ],
      'Thiago Motta': [
        {'team': 'Bologna', 'period': '2022-2024', 'trophy': '🏆 Qualificazione UCL', 'role': 'Allenatore'},
        {'team': 'Spezia', 'period': '2021-2022', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Genoa U19', 'period': '2019-2021', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'PSG', 'period': '2012-2018', 'trophy': '🏆🏆 Ligue 1', 'role': 'Giocatore'},
        {'team': 'Inter', 'period': '2009-2012', 'trophy': '🏆 Triplete', 'role': 'Giocatore'},
        {'team': 'Genoa', 'period': '2008-2009', 'trophy': '', 'role': 'Giocatore'},
        {'team': 'Atletico Madrid', 'period': '2007-2008', 'trophy': '', 'role': 'Giocatore'},
        {'team': 'Barcelona', 'period': '1999-2007', 'trophy': '🏆🏆 Liga', 'role': 'Giocatore'},
      ],
      'Simone Inzaghi': [
        {'team': 'Inter', 'period': '2021-oggi', 'trophy': '🏆 Scudetto 2024', 'role': 'Allenatore'},
        {'team': 'Lazio', 'period': '2016-2021', 'trophy': '🏆 Coppa Italia', 'role': 'Allenatore'},
        {'team': 'Lazio Primavera', 'period': '2014-2016', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Lazio', 'period': '1999-2010', 'trophy': '🏆 Coppa Italia', 'role': 'Giocatore'},
      ],
      'Stefano Pioli': [
        {'team': 'Milan', 'period': '2019-2024', 'trophy': '🏆 Scudetto 2022', 'role': 'Allenatore'},
        {'team': 'Fiorentina', 'period': '2017-2019', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Inter', 'period': '2016-2017', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Lazio', 'period': '2014-2016', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Bologna', 'period': '2011-2014', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Massimiliano Allegri': [
        {'team': 'Juventus', 'period': '2021-2024', 'trophy': '🏆 Coppa Italia', 'role': 'Allenatore'},
        {'team': 'Juventus', 'period': '2014-2019', 'trophy': '🏆🏆🏆🏆🏆 Scudetti', 'role': 'Allenatore'},
        {'team': 'Milan', 'period': '2010-2014', 'trophy': '🏆 Scudetto 2011', 'role': 'Allenatore'},
        {'team': 'Cagliari', 'period': '2008-2010', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Luciano Spalletti': [
        {'team': 'Napoli', 'period': '2021-2023', 'trophy': '🏆 Scudetto 2023', 'role': 'Allenatore'},
        {'team': 'Inter', 'period': '2017-2019', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Roma', 'period': '2005-2009', 'trophy': '🏆 Coppa Italia', 'role': 'Allenatore'},
        {'team': 'Udinese', 'period': '2002-2005', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Maurizio Sarri': [
        {'team': 'Lazio', 'period': '2021-2024', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Juventus', 'period': '2019-2020', 'trophy': '🏆 Scudetto', 'role': 'Allenatore'},
        {'team': 'Chelsea', 'period': '2018-2019', 'trophy': '🏆 Europa League', 'role': 'Allenatore'},
        {'team': 'Napoli', 'period': '2015-2018', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Empoli', 'period': '2012-2015', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Gian Piero Gasperini': [
        {'team': 'Atalanta', 'period': '2016-oggi', 'trophy': '🏆 Europa League 2024', 'role': 'Allenatore'},
        {'team': 'Inter', 'period': '2011', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Genoa', 'period': '2006-2011', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Vincenzo Italiano': [
        {'team': 'Fiorentina', 'period': '2021-2024', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Spezia', 'period': '2019-2021', 'trophy': '🏆 Promozione Serie A', 'role': 'Allenatore'},
        {'team': 'Trapani', 'period': '2018-2019', 'trophy': '', 'role': 'Allenatore'},
      ],
      'Ivan Juric': [
        {'team': 'Torino', 'period': '2021-2024', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Verona', 'period': '2019-2021', 'trophy': '', 'role': 'Allenatore'},
        {'team': 'Genoa', 'period': '2016-2019', 'trophy': '', 'role': 'Allenatore'},
      ],
    };
    return (careers[coachName] ?? [
      {'team': 'Squadra attuale', 'period': '2023-oggi', 'trophy': '', 'role': 'Allenatore'},
    ]).map((e) => Map<String, String>.from(e)).toList();
  }






  List<Map<String, dynamic>> _getTeamForm(String teamName) {

    final forms = <String, List<Map<String, dynamic>>>{
      'Inter': [
        {'opponent': 'Torino', 'score': '2-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/03'},
        {'opponent': 'Juventus', 'score': '1-0', 'result': 'W', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '23/02'},
        {'opponent': 'Fiorentina', 'score': '0-1', 'result': 'L', 'venue': 'Casa', 'comp': 'Serie A', 'date': '16/02'},
        {'opponent': 'Napoli', 'score': '1-1', 'result': 'D', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '09/02'},
        {'opponent': 'Roma', 'score': '4-2', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/02'},
      ],
      'Milan': [
        {'opponent': 'Lazio', 'score': '1-2', 'result': 'L', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '02/03'},
        {'opponent': 'Bologna', 'score': '2-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '23/02'},
        {'opponent': 'Atalanta', 'score': '2-2', 'result': 'D', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '16/02'},
        {'opponent': 'Napoli', 'score': '1-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '09/02'},
        {'opponent': 'Roma', 'score': '3-1', 'result': 'W', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '02/02'},
      ],
      'Roma': [
        {'opponent': 'Napoli', 'score': '2-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/03'},
        {'opponent': 'Inter', 'score': '0-2', 'result': 'L', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '23/02'},
        {'opponent': 'Fiorentina', 'score': '1-1', 'result': 'D', 'venue': 'Casa', 'comp': 'Serie A', 'date': '16/02'},
        {'opponent': 'Juventus', 'score': '1-0', 'result': 'W', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '09/02'},
        {'opponent': 'Lazio', 'score': '0-1', 'result': 'L', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/02'},
      ],
      'Bologna': [
        {'opponent': 'Atalanta', 'score': '1-1', 'result': 'D', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/03'},
        {'opponent': 'Milan', 'score': '2-1', 'result': 'W', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '23/02'},
        {'opponent': 'Torino', 'score': '3-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '16/02'},
        {'opponent': 'Lazio', 'score': '0-2', 'result': 'L', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '09/02'},
        {'opponent': 'Napoli', 'score': '2-2', 'result': 'D', 'venue': 'Casa', 'comp': 'Serie A', 'date': '02/02'},
      ],
      'Napoli': [
        {'opponent': 'Roma', 'score': '0-2', 'result': 'L', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '02/03'},
        {'opponent': 'Atalanta', 'score': '3-1', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A', 'date': '23/02'},
        {'opponent': 'Juventus', 'score': '1-1', 'result': 'D', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '16/02'},
        {'opponent': 'Bologna', 'score': '2-2', 'result': 'D', 'venue': 'Casa', 'comp': 'Serie A', 'date': '09/02'},
        {'opponent': 'Torino', 'score': '2-0', 'result': 'W', 'venue': 'Trasferta', 'comp': 'Serie A', 'date': '02/02'},
      ],
    };
    return forms[teamName] ?? [
      {'opponent': 'Team A', 'score': '1-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A'},
      {'opponent': 'Team B', 'score': '0-0', 'result': 'D', 'venue': 'Trasferta', 'comp': 'Serie A'},
      {'opponent': 'Team C', 'score': '2-1', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A'},
      {'opponent': 'Team D', 'score': '0-2', 'result': 'L', 'venue': 'Trasferta', 'comp': 'Serie A'},
      {'opponent': 'Team E', 'score': '3-0', 'result': 'W', 'venue': 'Casa', 'comp': 'Serie A'},
    ];
  }

  Map<String, dynamic> _getTeamSeasonStats(String teamName) {
    final stats = <String, Map<String, dynamic>>{
      'Inter': {'position': 1, 'points': 83, 'played': 35, 'wins': 26, 'draws': 5, 'losses': 4, 'goalsFor': 78, 'goalsAgainst': 25, 'gd': '+53'},
      'Milan': {'position': 2, 'points': 72, 'played': 35, 'wins': 22, 'draws': 6, 'losses': 7, 'goalsFor': 65, 'goalsAgainst': 38, 'gd': '+27'},
      'Juventus': {'position': 3, 'points': 68, 'played': 35, 'wins': 20, 'draws': 8, 'losses': 7, 'goalsFor': 55, 'goalsAgainst': 30, 'gd': '+25'},
      'Napoli': {'position': 10, 'points': 49, 'played': 35, 'wins': 14, 'draws': 7, 'losses': 14, 'goalsFor': 52, 'goalsAgainst': 48, 'gd': '+4'},
      'Atalanta': {'position': 4, 'points': 65, 'played': 35, 'wins': 19, 'draws': 8, 'losses': 8, 'goalsFor': 64, 'goalsAgainst': 38, 'gd': '+26'},
      'Roma': {'position': 6, 'points': 58, 'played': 35, 'wins': 17, 'draws': 7, 'losses': 11, 'goalsFor': 52, 'goalsAgainst': 42, 'gd': '+10'},
      'Lazio': {'position': 7, 'points': 55, 'played': 35, 'wins': 16, 'draws': 7, 'losses': 12, 'goalsFor': 48, 'goalsAgainst': 38, 'gd': '+10'},
      'Bologna': {'position': 5, 'points': 62, 'played': 35, 'wins': 18, 'draws': 8, 'losses': 9, 'goalsFor': 49, 'goalsAgainst': 32, 'gd': '+17'},
      'Fiorentina': {'position': 8, 'points': 52, 'played': 35, 'wins': 15, 'draws': 7, 'losses': 13, 'goalsFor': 48, 'goalsAgainst': 42, 'gd': '+6'},
      'Torino': {'position': 9, 'points': 50, 'played': 35, 'wins': 14, 'draws': 8, 'losses': 13, 'goalsFor': 38, 'goalsAgainst': 40, 'gd': '-2'},
      'Verona': {'position': 15, 'points': 35, 'played': 35, 'wins': 9, 'draws': 8, 'losses': 18, 'goalsFor': 32, 'goalsAgainst': 52, 'gd': '-20'},
    };
    return stats[teamName] ?? {'position': 10, 'points': 45, 'played': 35, 'wins': 12, 'draws': 9, 'losses': 14, 'goalsFor': 40, 'goalsAgainst': 45, 'gd': '-5'};
  }

  // H2H TAB — Scontri diretti
  // ══════════════════════════════════════════════════════════════════

  Widget _buildH2HTab(ThemeData theme, bool isDark) {
    return H2HTab(
      homeName: widget.match.homeTeamName,
      awayName: widget.match.awayTeamName,
      homeColor: _getTeamColor(widget.match.homeTeamName),
      awayColor: _getTeamColor(widget.match.awayTeamName),
      onMatchTap: (m) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
        );
      },
    );
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark) {
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);
    final homeColor = const Color(0xFF1565C0);
    final awayColor = const Color(0xFFD32F2F);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // ── Dettagli Partita ──
        _infoSection(
          icon: Icons.sports_soccer_rounded,
          title: localizeShotData(context, localizeShotData(context, 'DETTAGLI PARTITA')),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            _infoRow(localizeShotData(context, 'Competizione'), widget.match.leagueName ?? 'Serie A', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Giornata'), widget.match.round ?? 'Giornata 27', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Data'), widget.match.date.toString().substring(0, 10), tx, lb, divider),
            _infoRow(localizeShotData(context, 'Orario'), widget.match.time, tx, lb, divider),
            _infoRow(localizeShotData(context, 'Stato'), localizeShotData(context, 'Terminata (FT)'), tx, lb, null),
          ],
        ),
        const SizedBox(height: 14),
        // ── Sede ──
        _infoSection(
          icon: Icons.stadium_rounded,
          title: localizeShotData(context, localizeShotData(context, 'SEDE')),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            _infoRow(localizeShotData(context, 'Stadio'), widget.match.venue.isNotEmpty ? widget.match.venue : 'Stadio Olimpico', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Città'), 'Roma', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Capienza'), '72,698', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Spettatori'), '58,420', tx, lb, divider),
            _infoRow(tr(context, 'Superficie'), tr(context, 'Erba naturale'), tx, lb, null),
          ],
        ),
        const SizedBox(height: 14),
        // ── Arbitro ──
        _infoSection(
          icon: Icons.sports_rounded,
          title: localizeShotData(context, localizeShotData(context, 'ARBITRO')),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            _infoRow(localizeShotData(context, 'Arbitro'), widget.match.referee ?? 'Daniele Orsato', tx, lb, divider),
            _infoRow(tr(context, 'Assistente 1'), 'Carbone', tx, lb, divider),
            _infoRow(tr(context, 'Assistente 2'), 'Giallatini', tx, lb, divider),
            _infoRow(tr(context, 'IV Uomo'), 'Rapuano', tx, lb, divider),
            _infoRow('VAR', 'Di Paolo', tx, lb, null),
          ],
        ),
        const SizedBox(height: 14),
        // ── Meteo ──
        _infoSection(
          icon: Icons.cloud_rounded,
          title: tr(context, 'CONDIZIONI'),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            _infoRow(tr(context, 'Meteo'), tr(context, '☀️ Sereno'), tx, lb, divider),
            _infoRow(tr(context, 'Temperatura'), '18°C', tx, lb, divider),
            _infoRow(tr(context, 'Umidità'), '55%', tx, lb, divider),
            _infoRow(tr(context, 'Vento'), '12 km/h', tx, lb, null),
          ],
        ),
        const SizedBox(height: 14),
        // ── Forma recente ──
        _infoSection(
          icon: Icons.trending_up_rounded,
          title: tr(context, 'FORMA RECENTE (5 PARTITE)'),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(child: Column(children: [
                  Text(widget.match.homeTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final r in ['V', 'V', 'P', 'V', 'S'])
                      Container(
                        width: 28, height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: r == 'V' ? const Color(0xFF4CAF50) : r == 'P' ? Colors.amber : const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                  ]),
                ])),
                Container(width: 1, height: 50, color: divider),
                Expanded(child: Column(children: [
                  Text(widget.match.awayTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final r in ['V', 'S', 'V', 'V', 'P'])
                      Container(
                        width: 28, height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: r == 'V' ? const Color(0xFF4CAF50) : r == 'P' ? Colors.amber : const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                  ]),
                ])),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _infoSection({
    required IconData icon, required String title, required bool isDark,
    required Color cardBg, required Color tx, required Color lb, required Color divider,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(icon, size: 15, color: lb),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: lb, letterSpacing: 1.2)),
          ]),
        ),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value, Color tx, Color lb, Color? divider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: divider != null ? Border(bottom: BorderSide(color: divider)) : null,
      ),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 13, color: lb)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
      ]),
    );
  }



  // ============================================================================
  // MISC
  // ============================================================================
  // [FAV-D2c] match detail sheet unificato
  Future<void> _showMatchNotificationDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final s = _matchNotifSettings;
            final en = s.enabled;

            final allOn = s.notifyHomeGoals &&
                s.notifyAwayGoals &&
                s.notifyPenalties &&
                s.notifyVarDecisions &&
                s.notifyMatchStart &&
                s.notifyHalfTime &&
                s.notifyMatchEnd &&
                s.notifyYellowCards &&
                s.notifyRedCards &&
                s.notifySubstitutions &&
                s.notifyCorners &&
                s.notifyOffsides &&
                s.notifyShotsOnTarget &&
                s.notifyFouls;

            final activeCount = s.activeNotificationsCount;

            void refresh() {
              setSheetState(() {});
              setState(() {});
            }

            void toggle(String key, bool value) {
              _haptic.lightImpact();
              _updateMatchNotifFromKey(key, value);
              refresh();
            }

            void toggleAll() {
              _haptic.lightImpact();
              _setAllMatchNotif(!allOn);
              refresh();
            }

            void applyPreset(String name) {
              _haptic.mediumImpact();
              switch (name) {
                case 'goals':
                  _matchNotifSettings =
                      MatchNotificationSettings.goalsOnly(widget.match.id);
                  break;
                case 'minimal':
                  _matchNotifSettings =
                      MatchNotificationSettings.minimal(widget.match.id);
                  break;
                case 'complete':
                  _matchNotifSettings =
                      MatchNotificationSettings.complete(widget.match.id);
                  break;
                case 'disabled':
                  _matchNotifSettings =
                      MatchNotificationSettings.disabled(widget.match.id);
                  break;
              }
              _matchNotifService.saveSettingsForMatch(_matchNotifSettings);
              refresh();
            }

            void setMaster(bool value) {
              _haptic.lightImpact();
              _matchNotifSettings = s.copyWith(enabled: value);
              _matchNotifService.saveSettingsForMatch(_matchNotifSettings);
              refresh();
            }

            return NotifSheetContainer(
              children: [
                NotifSheetHeader(
                  title: tr(context, 'Notifiche Partita'),
                  subtitle:
                      '${widget.match.homeTeamName} vs ${widget.match.awayTeamName}',
                  allOn: allOn,
                  onToggleAll: toggleAll,
                  onClose: () {
                    _haptic.lightImpact();
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NotifPresetChips(
                          presets: [
                            NotifPresetChipData(
                              label: tr(context, 'Solo Goal'),
                              icon: Icons.sports_soccer,
                              onTap: () => applyPreset('goals'),
                            ),
                            NotifPresetChipData(
                              label: tr(context, 'Predefinito'),
                              icon: Icons.notifications_none,
                              onTap: () => applyPreset('minimal'),
                            ),
                            NotifPresetChipData(
                              label: tr(context, 'Completo'),
                              icon: Icons.notifications_active,
                              onTap: () => applyPreset('complete'),
                            ),
                            NotifPresetChipData(
                              label: tr(context, 'Disattiva tutto'),
                              icon: Icons.notifications_off,
                              onTap: () => applyPreset('disabled'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        NotifMasterSwitch(
                          title: tr(context, 'Notifiche Partita'),
                          subtitle: en
                              ? '$activeCount ${tr(context, 'eventi attivi')}'
                              : tr(context, 'Disattivate'),
                          value: en,
                          onChanged: setMaster,
                        ),
                        const SizedBox(height: 4),

                        NotifSectionHeader(
                          title: tr(context, 'Risultato'),
                          icon: Icons.flag_rounded,
                        ),
                        NotifSwitchRow(
                          icon: Icons.sports_soccer,
                          color: const Color(0xFF4CAF50),
                          title: tr(context, 'Goal'),
                          subtitle:
                              tr(context, 'Notifica con marcatore e minuto'),
                          value: s.notifyHomeGoals,
                          enabled: en,
                          onChanged: (v) => toggle('goals', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.gps_fixed_rounded,
                          color: const Color(0xFFE91E63),
                          title: tr(context, 'Rigori'),
                          subtitle: tr(context,
                              'Rigori assegnati, segnati e sbagliati'),
                          value: s.notifyPenalties,
                          enabled: en,
                          onChanged: (v) => toggle('penalties', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.videocam_rounded,
                          color: const Color(0xFF2196F3),
                          title: tr(context, 'Decisioni VAR'),
                          subtitle: tr(context,
                              'Revisioni e decisioni arbitrali al VAR'),
                          value: s.notifyVarDecisions,
                          enabled: en,
                          onChanged: (v) => toggle('var', v),
                        ),

                        NotifSectionHeader(
                          title: tr(context, 'Tempi di gioco'),
                          icon: Icons.timer_rounded,
                        ),
                        NotifSwitchRow(
                          icon: Icons.play_circle_outline_rounded,
                          color: const Color(0xFF66BB6A),
                          title: tr(context, 'Inizio tempo'),
                          subtitle:
                              tr(context, 'Calcio d\'inizio 1° e 2° tempo'),
                          value: s.notifyMatchStart,
                          enabled: en,
                          onChanged: (v) => toggle('kickoff', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.pause_circle_outline_rounded,
                          color: const Color(0xFFFFA726),
                          title: tr(context, 'Fine primo tempo'),
                          subtitle: tr(context,
                              'Risultato parziale all\'intervallo'),
                          value: s.notifyHalfTime,
                          enabled: en,
                          onChanged: (v) => toggle('halftime', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.stop_circle_outlined,
                          color: const Color(0xFFEF5350),
                          title: tr(context, 'Fischio finale'),
                          subtitle:
                              tr(context, 'Risultato finale della partita'),
                          value: s.notifyMatchEnd,
                          enabled: en,
                          onChanged: (v) => toggle('fulltime', v),
                        ),

                        NotifSectionHeader(
                          title: tr(context, 'Disciplina'),
                          icon: Icons.shield_rounded,
                        ),
                        NotifSwitchRow(
                          icon: Icons.square_rounded,
                          color: const Color(0xFFFFCA28),
                          title: tr(context, 'Cartellini gialli'),
                          subtitle: tr(context, 'Ammonizioni e doppi gialli'),
                          value: s.notifyYellowCards,
                          enabled: en,
                          onChanged: (v) => toggle('yellowCards', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.square_rounded,
                          color: const Color(0xFFE53935),
                          title: tr(context, 'Cartellini rossi'),
                          subtitle: tr(context,
                              'Espulsioni dirette e per doppio giallo'),
                          value: s.notifyRedCards,
                          enabled: en,
                          onChanged: (v) => toggle('redCards', v),
                        ),

                        NotifSectionHeader(
                          title: tr(context, 'Eventi di gioco'),
                          icon: Icons.sports_rounded,
                        ),
                        NotifSwitchRow(
                          icon: Icons.swap_horiz_rounded,
                          color: const Color(0xFF42A5F5),
                          title: tr(context, 'Sostituzioni'),
                          subtitle: tr(context,
                              'Cambi effettuati da entrambe le squadre'),
                          value: s.notifySubstitutions,
                          enabled: en,
                          onChanged: (v) => toggle('substitutions', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.flag_outlined,
                          color: const Color(0xFF26A69A),
                          title: tr(context, 'Calci d\'angolo'),
                          subtitle: tr(context,
                              'Corner battuti da entrambe le squadre'),
                          value: s.notifyCorners,
                          enabled: en,
                          onChanged: (v) => toggle('corners', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.front_hand_rounded,
                          color: const Color(0xFF7E57C2),
                          title: tr(context, 'Fuorigioco'),
                          subtitle:
                              tr(context, 'Posizioni di offside segnalate'),
                          value: s.notifyOffsides,
                          enabled: en,
                          onChanged: (v) => toggle('offsides', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.gps_fixed,
                          color: const Color(0xFFFF7043),
                          title: tr(context, 'Tiri in porta'),
                          subtitle: tr(context,
                              'Tiri nello specchio della porta'),
                          value: s.notifyShotsOnTarget,
                          enabled: en,
                          onChanged: (v) => toggle('shotsOnTarget', v),
                        ),
                        NotifSwitchRow(
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFF8D6E63),
                          title: tr(context, 'Falli'),
                          subtitle: tr(context, 'Falli commessi in campo'),
                          value: s.notifyFouls,
                          enabled: en,
                          onChanged: (v) => toggle('fouls', v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // [FAV-cleanup2b] helper notifiche rimossi

  // ============================================================================
  // ✅ FORMAZIONI CON DATI COERENTI — SOMMA GIOCATORI = TOTALE SQUADRA
  //
  // HOME TITOLARI (11):
  //   passes: 30+38+44+34+36+50+54+48+36+26+24 = 420 ✅ = _homePassesTotal
  //   completed: 25+32+38+28+30+42+45+40+28+18+20 = 346 ✅ = _homePassesCompleted
  //   shots: 0+0+0+0+0+1+2+2+2+3+3 = 13 (+ Felipe Anderson sub 2 = 15) ✅
  //   onTarget: 0+0+0+0+0+1+0+1+1+2+1 = 6 (+ Felipe Anderson sub 1 = 7) ✅
  //   fouls: 0+2+2+2+2+2+2+0+0+0+0 = 12 ✅ = _homeFouls
  //   yellows: 0+1+0+0+0+0+1+0+0+0+0 = 2 ✅ = _homeYellowCards
  //
  // AWAY TITOLARI (11):
  //   passes: 28+26+28+24+32+38+36+28+16+12+12 = 280 ✅ = _awayPassesTotal
  //   completed: 22+20+22+18+25+30+28+22+12+8+10 = 217 ✅ = _awayPassesCompleted
  //   shots: 0+0+0+0+1+0+1+1+2+1+2 = 8 ✅ = _awayShotsTotal
  //   onTarget: 0+0+0+0+0+0+0+1+1+1+0 = 3 ✅ = _awayShotsOnTarget
  //   fouls: 0+3+2+3+0+2+2+1+1+0+1 = 15 ✅ = _awayFouls
  //   yellows: 0+1+0+0+1+0+1+0+0+0+0 = 3 ✅ = _awayYellowCards
  // ============================================================================
  List<LocalLineupPlayer> _generateMockLocalLineup(bool isHome) {
    if (isHome) {
      return [
        LocalLineupPlayer(
            number: 1,
            name: 'Provedel',
            position: 'GK',
            rating: 6.5,
            passes: 30,
            passesCompleted: 25,
            touches: 38,
            minutesPlayed: 90,
            duelsTotal: 1,
            duelsWon: 1,
            recoveries: 1),
        LocalLineupPlayer(
            number: 4,
            name: 'Patric',
            position: 'CB',
            rating: 6.8,
            passes: 38,
            passesCompleted: 32,
            touches: 48,
            fouls: 2,
            yellowCards: 1,
            tackles: 3,
            tacklesWon: 2,
            interceptions: 2,
            clearances: 4,
            recoveries: 3,
            duelsTotal: 8,
            duelsWon: 5,
            aerialTotal: 4,
            aerialWon: 3,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 13,
            name: 'Romagnoli',
            position: 'CB',
            rating: 7.2,
            passes: 44,
            passesCompleted: 38,
            touches: 56,
            fouls: 2,
            tackles: 4,
            tacklesWon: 3,
            interceptions: 3,
            clearances: 5,
            recoveries: 4,
            duelsTotal: 10,
            duelsWon: 7,
            aerialTotal: 6,
            aerialWon: 5,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 3,
            name: 'Lazzari',
            position: 'RB',
            rating: 6.7,
            passes: 34,
            passesCompleted: 28,
            touches: 52,
            fouls: 2,
            crosses: 5,
            crossesCompleted: 2,
            dribbles: 3,
            dribblesSuccessful: 1,
            tackles: 2,
            tacklesWon: 1,
            interceptions: 1,
            recoveries: 2,
            duelsTotal: 7,
            duelsWon: 3,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 77,
            name: 'Marusic',
            position: 'LB',
            rating: 6.6,
            passes: 36,
            passesCompleted: 30,
            touches: 50,
            fouls: 2,
            crosses: 4,
            crossesCompleted: 1,
            dribbles: 2,
            dribblesSuccessful: 1,
            tackles: 2,
            tacklesWon: 2,
            interceptions: 1,
            recoveries: 2,
            duelsTotal: 6,
            duelsWon: 3,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 32,
            name: 'Cataldi',
            position: 'CM',
            rating: 6.9,
            passes: 50,
            passesCompleted: 42,
            touches: 62,
            shots: 1,
            shotsOnTarget: 1,
            xG: 0.08,
            keyPasses: 2,
            dribbles: 1,
            dribblesSuccessful: 1,
            ballsLost: 5,
            fouls: 1,
            tackles: 3,
            tacklesWon: 2,
            interceptions: 2,
            recoveries: 4,
            duelsTotal: 8,
            duelsWon: 4,
            minutesPlayed: 68),
        LocalLineupPlayer(
            number: 8,
            name: 'Guendouzi',
            position: 'CM',
            rating: 7.0,
            passes: 54,
            passesCompleted: 45,
            touches: 68,
            shots: 2,
            fouls: 2,
            yellowCards: 1,
            xG: 0.10,
            keyPasses: 1,
            dribbles: 3,
            dribblesSuccessful: 2,
            ballsLost: 7,
            tackles: 4,
            tacklesWon: 3,
            interceptions: 1,
            recoveries: 3,
            duelsTotal: 12,
            duelsWon: 7,
            aerialTotal: 3,
            aerialWon: 1,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 10,
            name: 'Luis Alberto',
            position: 'CAM',
            rating: 7.5,
            passes: 48,
            passesCompleted: 40,
            touches: 72,
            shots: 2,
            shotsOnTarget: 1,
            xG: 0.17,
            xA: 0.22,
            keyPasses: 4,
            dribbles: 4,
            dribblesSuccessful: 3,
            ballsLost: 8,
            crosses: 3,
            crossesCompleted: 2,
            foulsWon: 3,
            duelsTotal: 9,
            duelsWon: 5,
            minutesPlayed: 65),
        LocalLineupPlayer(
            number: 20,
            name: 'Zaccagni',
            position: 'LW',
            rating: 7.8,
            passes: 36,
            passesCompleted: 28,
            touches: 58,
            shots: 2,
            shotsOnTarget: 1,
            assists: 1,
            xG: 0.24,
            xA: 0.31,
            keyPasses: 3,
            dribbles: 6,
            dribblesSuccessful: 4,
            ballsLost: 6,
            crosses: 4,
            crossesCompleted: 2,
            foulsWon: 2,
            duelsTotal: 10,
            duelsWon: 6,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 17,
            name: 'Immobile',
            position: 'ST',
            rating: 8.2,
            passes: 26,
            passesCompleted: 18,
            touches: 42,
            shots: 3,
            shotsOnTarget: 2,
            goals: 1,
            assists: 1,
            xG: 0.99,
            xA: 0.12,
            keyPasses: 2,
            dribbles: 2,
            dribblesSuccessful: 1,
            ballsLost: 4,
            foulsWon: 3,
            offsides: 2,
            duelsTotal: 11,
            duelsWon: 5,
            aerialTotal: 5,
            aerialWon: 3,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 7,
            name: 'Pedro',
            position: 'RW',
            rating: 8.0,
            passes: 24,
            passesCompleted: 20,
            touches: 46,
            shots: 3,
            shotsOnTarget: 1,
            xG: 0.37,
            xA: 0.15,
            keyPasses: 2,
            dribbles: 5,
            dribblesSuccessful: 3,
            ballsLost: 5,
            crosses: 3,
            crossesCompleted: 1,
            foulsWon: 2,
            tackles: 1,
            tacklesWon: 1,
            recoveries: 2,
            duelsTotal: 8,
            duelsWon: 5,
            minutesPlayed: 52),
      ];
    } else {
      return [
        LocalLineupPlayer(
            number: 16,
            name: 'Maignan',
            position: 'GK',
            rating: 6.8,
            passes: 28,
            passesCompleted: 22,
            touches: 36,
            minutesPlayed: 90,
            duelsTotal: 1,
            duelsWon: 0,
            recoveries: 1),
        LocalLineupPlayer(
            number: 23,
            name: 'Tomori',
            position: 'CB',
            rating: 6.5,
            passes: 26,
            passesCompleted: 20,
            touches: 42,
            fouls: 3,
            yellowCards: 1,
            tackles: 3,
            tacklesWon: 1,
            interceptions: 1,
            clearances: 3,
            recoveries: 2,
            duelsTotal: 10,
            duelsWon: 4,
            aerialTotal: 5,
            aerialWon: 2,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 24,
            name: 'Kjaer',
            position: 'CB',
            rating: 6.6,
            passes: 28,
            passesCompleted: 22,
            touches: 44,
            fouls: 2,
            tackles: 2,
            tacklesWon: 2,
            interceptions: 2,
            clearances: 6,
            recoveries: 3,
            duelsTotal: 9,
            duelsWon: 5,
            aerialTotal: 7,
            aerialWon: 4,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 2,
            name: 'Calabria',
            position: 'RB',
            rating: 6.3,
            passes: 24,
            passesCompleted: 18,
            touches: 40,
            fouls: 3,
            crosses: 3,
            crossesCompleted: 0,
            dribbles: 2,
            dribblesSuccessful: 0,
            ballsLost: 5,
            tackles: 2,
            tacklesWon: 1,
            interceptions: 1,
            recoveries: 1,
            duelsTotal: 8,
            duelsWon: 3,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 19,
            name: 'Theo Hernandez',
            position: 'LB',
            rating: 7.3,
            passes: 32,
            passesCompleted: 25,
            touches: 54,
            shots: 1,
            yellowCards: 1,
            xG: 0.05,
            crosses: 6,
            crossesCompleted: 3,
            dribbles: 4,
            dribblesSuccessful: 3,
            ballsLost: 4,
            keyPasses: 2,
            foulsWon: 1,
            tackles: 2,
            tacklesWon: 2,
            interceptions: 1,
            recoveries: 3,
            duelsTotal: 9,
            duelsWon: 6,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 8,
            name: 'Tonali',
            position: 'CM',
            rating: 6.7,
            passes: 38,
            passesCompleted: 30,
            touches: 55,
            fouls: 2,
            keyPasses: 1,
            dribbles: 2,
            dribblesSuccessful: 1,
            ballsLost: 6,
            tackles: 4,
            tacklesWon: 3,
            interceptions: 2,
            recoveries: 5,
            duelsTotal: 11,
            duelsWon: 6,
            aerialTotal: 2,
            aerialWon: 1,
            minutesPlayed: 72),
        LocalLineupPlayer(
            number: 4,
            name: 'Bennacer',
            position: 'CM',
            rating: 6.7,
            passes: 36,
            passesCompleted: 28,
            touches: 52,
            shots: 1,
            fouls: 2,
            yellowCards: 1,
            xG: 0.07,
            keyPasses: 1,
            dribbles: 1,
            dribblesSuccessful: 0,
            ballsLost: 5,
            tackles: 3,
            tacklesWon: 2,
            interceptions: 1,
            recoveries: 3,
            duelsTotal: 10,
            duelsWon: 5,
            aerialTotal: 3,
            aerialWon: 1,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 10,
            name: 'Brahim Diaz',
            position: 'CAM',
            rating: 6.9,
            passes: 28,
            passesCompleted: 22,
            touches: 48,
            shots: 1,
            shotsOnTarget: 1,
            fouls: 1,
            xG: 0.10,
            xA: 0.08,
            keyPasses: 2,
            dribbles: 5,
            dribblesSuccessful: 3,
            ballsLost: 7,
            foulsWon: 2,
            duelsTotal: 8,
            duelsWon: 4,
            minutesPlayed: 83),
        LocalLineupPlayer(
            number: 17,
            name: 'Leao',
            position: 'LW',
            rating: 7.9,
            passes: 16,
            passesCompleted: 12,
            touches: 44,
            shots: 2,
            shotsOnTarget: 1,
            assists: 1,
            xG: 0.40,
            xA: 0.35,
            keyPasses: 3,
            dribbles: 8,
            dribblesSuccessful: 5,
            ballsLost: 6,
            crosses: 3,
            crossesCompleted: 1,
            fouls: 1,
            foulsWon: 3,
            offsides: 1,
            duelsTotal: 12,
            duelsWon: 7,
            minutesPlayed: 90),
        LocalLineupPlayer(
            number: 9,
            name: 'Giroud',
            position: 'ST',
            rating: 6.8,
            passes: 12,
            passesCompleted: 8,
            touches: 28,
            shots: 1,
            shotsOnTarget: 1,
            goals: 1,
            xG: 0.38,
            keyPasses: 1,
            dribbles: 1,
            dribblesSuccessful: 0,
            ballsLost: 3,
            foulsWon: 2,
            offsides: 1,
            duelsTotal: 14,
            duelsWon: 6,
            aerialTotal: 8,
            aerialWon: 5,
            minutesPlayed: 75),
        LocalLineupPlayer(
            number: 21,
            name: 'Pulisic',
            position: 'RW',
            rating: 6.6,
            passes: 12,
            passesCompleted: 10,
            touches: 32,
            shots: 2,
            fouls: 1,
            xG: 0.24,
            keyPasses: 1,
            dribbles: 4,
            dribblesSuccessful: 2,
            ballsLost: 4,
            crosses: 2,
            crossesCompleted: 1,
            tackles: 1,
            tacklesWon: 0,
            recoveries: 1,
            duelsTotal: 7,
            duelsWon: 3,
            minutesPlayed: 90),
      ];
    }
  }
}

// ============================================================================
// PAINTERS: CAMPO PASSAGGI PREMIUM + FRECCE FLUSSO + DONUT CHART + FORMATION
// ============================================================================

// Formation pitch painter — green field with correct proportions

// Linee campo raffinato con supporto dark mode

// Segmento per donut chart

// Donut chart per distribuzione lunghezza passaggi

// ============================================================================
// HEATMAP ENGINE v4 — ClipRRect + rosso visibile + contrasto forte
//
// Fix critici:
// ① clipRRect per contenere heatmap dentro i bordi del campo
// ② Scala colori: rosso da 0.65 (non 0.84) → zone calde ROSSE per davvero
// ③ S-curve k=14 centrata su 0.40 → contrasto brutale
// ④ Sigma narrow 0.16 (non 0.12) → meno banding verticale
// ⑤ Opacity boost per single team (0.92)
// ============================================================================


/// S-curve moderata: k=8, centro 0.50
/// Preserva variazione: zone fredde restano verdi/gialle, zone calde rosse

/// Sub-sorgenti con jitter per aspetto organico

/// Interpolazione multi-scala

/// Rendering con clipRRect + doppio blur


// ─── Vista combinata ───

// ─── Vista singola squadra ───

// ============================================================================
// CLASSI LOCALI
// ============================================================================

// ── PITCH HEATMAP PAINTER (concentration of play for selected team) ──

// ═══════════════════════════════════════════════════════════════════════════════
// PLAYER PROFILE SCREEN — Season stats + Career history
// ═══════════════════════════════════════════════════════════════════════════════

// Helper globale per dati stagionali giocatore
Map<String, dynamic>? getPlayerSeasonData(String name) {
  final db = <String, Map<String, dynamic>>{
    'Immobile': {'appearances': 31, 'goals': 12, 'assists': 3, 'yellowCards': 4, 'redCards': 0, 'avgRating': 7.12, 'nationality': 'Italia', 'age': 33},
    'Milinkovic-Savic': {'appearances': 34, 'goals': 10, 'assists': 7, 'yellowCards': 5, 'redCards': 0, 'avgRating': 7.18, 'nationality': 'Serbia', 'age': 28},
    'Provedel': {'appearances': 32, 'goals': 1, 'assists': 0, 'yellowCards': 1, 'redCards': 0, 'avgRating': 6.45, 'nationality': 'Italia', 'age': 29},
    'Leao': {'appearances': 34, 'goals': 15, 'assists': 9, 'yellowCards': 3, 'redCards': 0, 'avgRating': 7.35, 'nationality': 'Portogallo', 'age': 24},
    'Theo Hernandez': {'appearances': 33, 'goals': 5, 'assists': 8, 'yellowCards': 8, 'redCards': 1, 'avgRating': 6.95, 'nationality': 'Francia', 'age': 26},
    'Maignan': {'appearances': 28, 'goals': 0, 'assists': 0, 'yellowCards': 2, 'redCards': 0, 'avgRating': 6.75, 'nationality': 'Francia', 'age': 28},
    'Giroud': {'appearances': 31, 'goals': 10, 'assists': 4, 'yellowCards': 3, 'redCards': 0, 'avgRating': 6.85, 'nationality': 'Francia', 'age': 36},
    'Pulisic': {'appearances': 33, 'goals': 7, 'assists': 5, 'yellowCards': 2, 'redCards': 0, 'avgRating': 7.05, 'nationality': 'USA', 'age': 24},
    'Lautaro': {'appearances': 33, 'goals': 24, 'assists': 5, 'yellowCards': 6, 'redCards': 0, 'avgRating': 7.80, 'nationality': 'Argentina', 'age': 26},
    'Barella': {'appearances': 33, 'goals': 5, 'assists': 9, 'yellowCards': 9, 'redCards': 0, 'avgRating': 7.50, 'nationality': 'Italia', 'age': 27},
    'Calhanoglu': {'appearances': 35, 'goals': 8, 'assists': 10, 'yellowCards': 10, 'redCards': 0, 'avgRating': 7.40, 'nationality': 'Turchia', 'age': 30},
    'Dybala': {'appearances': 29, 'goals': 13, 'assists': 7, 'yellowCards': 3, 'redCards': 0, 'avgRating': 7.30, 'nationality': 'Argentina', 'age': 30},
    'Vlahovic': {'appearances': 33, 'goals': 16, 'assists': 0, 'yellowCards': 5, 'redCards': 0, 'avgRating': 7.10, 'nationality': 'Serbia', 'age': 24},
    'Chiesa': {'appearances': 22, 'goals': 9, 'assists': 3, 'yellowCards': 2, 'redCards': 0, 'avgRating': 6.80, 'nationality': 'Italia', 'age': 26},
    'Osimhen': {'appearances': 25, 'goals': 15, 'assists': 3, 'yellowCards': 7, 'redCards': 1, 'avgRating': 7.60, 'nationality': 'Nigeria', 'age': 25},
    'Kvaratskhelia': {'appearances': 34, 'goals': 7, 'assists': 8, 'yellowCards': 4, 'redCards': 0, 'avgRating': 7.20, 'nationality': 'Georgia', 'age': 23},
    'Lookman': {'appearances': 35, 'goals': 11, 'assists': 6, 'yellowCards': 3, 'redCards': 0, 'avgRating': 7.20, 'nationality': 'Nigeria', 'age': 26},
    'Pellegrini': {'appearances': 34, 'goals': 4, 'assists': 5, 'yellowCards': 12, 'redCards': 1, 'avgRating': 6.90, 'nationality': 'Italia', 'age': 27},
    'Thuram': {'appearances': 34, 'goals': 13, 'assists': 4, 'yellowCards': 5, 'redCards': 0, 'avgRating': 7.10, 'nationality': 'Francia', 'age': 26},
    'Higuain': {'appearances': 31, 'goals': 12, 'assists': 3, 'yellowCards': 4, 'redCards': 0, 'avgRating': 7.00, 'nationality': 'Argentina', 'age': 35},
    'Simeone': {'appearances': 28, 'goals': 6, 'assists': 2, 'yellowCards': 3, 'redCards': 0, 'avgRating': 6.50, 'nationality': 'Argentina', 'age': 28},
    'Benassi': {'appearances': 25, 'goals': 2, 'assists': 3, 'yellowCards': 5, 'redCards': 0, 'avgRating': 6.40, 'nationality': 'Italia', 'age': 29},
    'Cuadrado': {'appearances': 28, 'goals': 3, 'assists': 5, 'yellowCards': 7, 'redCards': 0, 'avgRating': 6.60, 'nationality': 'Colombia', 'age': 35},
    'Mattuidi': {'appearances': 26, 'goals': 1, 'assists': 2, 'yellowCards': 6, 'redCards': 0, 'avgRating': 6.30, 'nationality': 'Francia', 'age': 36},
  };
  if (db.containsKey(name)) return db[name];
  // Normalizza accenti per confronto
  String normalize(String s) => s
      .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
      .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n')
      .replaceAll('ü', 'u').replaceAll('ç', 'c').replaceAll('ö', 'o')
      .replaceAll('ä', 'a').replaceAll('ë', 'e').replaceAll('ï', 'i')
      .replaceAll('š', 's').replaceAll('ć', 'c').replaceAll('ž', 'z')
      .replaceAll('đ', 'd').replaceAll('Á', 'A').replaceAll('É', 'E')
      .replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
      .toLowerCase();
  final normName = normalize(name);
  for (final key in db.keys) {
    final normKey = normalize(key);
    if (normName.contains(normKey) || normKey.contains(normName)) return db[key];
  }
  final lastName = name.split(' ').last;
  final normLast = normalize(lastName);
  for (final key in db.keys) {
    if (normalize(key) == normLast) return db[key];
  }
  return null;
}


// [FAV-extract3] classe estratta in match_player_profile_screen.dart
