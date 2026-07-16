// lib/services/fanta_roster_service.dart
// Servizio per la gestione della Rosa Fanta dell'utente.
// Indipendente dai preferiti: un giocatore puo' stare in una, nell'altra
// o entrambe. Persiste su SharedPreferences.
//
// I giocatori sono divisi nei 4 ruoli classici del fantacalcio:
// Portieri, Difensori, Centrocampisti, Attaccanti.
//
// NB: i voti/statistiche mostrati saranno reali con le API (FASE 5).
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

/// I 4 ruoli classici del fantacalcio.
enum FantaRole { portiere, difensore, centrocampista, attaccante }

extension FantaRoleLabel on FantaRole {
  /// Etichetta italiana plurale (per le intestazioni di sezione).
  String get labelPlural {
    switch (this) {
      case FantaRole.portiere:
        return 'Portieri';
      case FantaRole.difensore:
        return 'Difensori';
      case FantaRole.centrocampista:
        return 'Centrocampisti';
      case FantaRole.attaccante:
        return 'Attaccanti';
    }
  }

  /// Sigla breve (P, D, C, A).
  String get shortCode {
    switch (this) {
      case FantaRole.portiere:
        return 'P';
      case FantaRole.difensore:
        return 'D';
      case FantaRole.centrocampista:
        return 'C';
      case FantaRole.attaccante:
        return 'A';
    }
  }

  /// Ordine di visualizzazione (P -> D -> C -> A).
  int get order => index;
}

class FantaRosterService extends ChangeNotifier {
  static const String _prefsKey = 'fanta_roster_players';

  // Giocatori nella rosa (oggetti completi, per mostrare voti/statistiche).
  final List<Player> _rosterPlayers = [];
  // Set di ID per verifiche rapide (isInRoster).
  final Set<int> _rosterIds = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ── Getters ──
  List<Player> get rosterPlayers => List.unmodifiable(_rosterPlayers);
  Set<int> get rosterIds => Set.unmodifiable(_rosterIds);
  int get count => _rosterPlayers.length;
  bool get isEmpty => _rosterPlayers.isEmpty;

  /// Verifica se un giocatore e' nella rosa (per la stella).
  bool isInRoster(int playerId) => _rosterIds.contains(playerId);

  // [ANTI-DOPPIONI] ─────────────────────────────────────────────
  // Prevenzione doppioni: due nomi come "Provedel" e "Ivan Provedel"
  // (stesso giocatore, nomi diversi tra schermate mock) vanno trattati
  // come lo stesso. Soluzione provvisoria in attesa degli ID veri (API).

  /// Normalizza un nome: minuscolo, senza accenti, spazi singoli, trim.
  String _normName(String name) {
    var s = name.toLowerCase().trim();
    const from = 'àáâãäèéêëìíîïòóôõöùúûüñç';
    const to   = 'aaaaaeeeeiiiiooooouuuunc';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    s = buf.toString();
    // collassa spazi multipli
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// Due nomi sono lo "stesso giocatore" se, normalizzati:
  /// - sono uguali, oppure
  /// - uno e' contenuto nell'altro (es. "provedel" in "ivan provedel"), oppure
  /// - condividono il cognome (ultima parola) se lunga >= 4 lettere.
  bool _sameName(String a, String b) {
    final na = _normName(a);
    final nb = _normName(b);
    if (na == nb) return true;
    if (na.isEmpty || nb.isEmpty) return false;
    if (na.contains(nb) || nb.contains(na)) return true;
    final lastA = na.split(' ').last;
    final lastB = nb.split(' ').last;
    if (lastA.length >= 4 && lastA == lastB) return true;
    return false;
  }

  /// Cerca in rosa un giocatore con nome equivalente. null se non c'e'.
  Player? _findDuplicate(String name) {
    for (final p in _rosterPlayers) {
      if (_sameName(p.name, name)) return p;
    }
    return null;
  }

  /// Come isInRoster ma per nome (usato dalle stelle per coerenza visiva):
  /// la stella di "Provedel" risulta piena se "Ivan Provedel" e' in rosa.
  bool isInRosterByName(String name) => _findDuplicate(name) != null;
  // ───────────────────────────────────────────────────────────────

  // ── Mappatura ruolo: da 'position' (stringa) al ruolo fanta classico ──
  // Gestisce sia codici brevi (GK/CB/CM/ST) sia nomi estesi italiani
  // ("Portiere", "Terzino Sinistro", "Ala Destra", ecc.).
  static FantaRole roleOf(String position) {
    final p = position.toLowerCase();
    // Portiere
    if (p.contains('portiere') ||
        p.contains('gk') ||
        p.contains('goalkeeper') ||
        p == 'g' ||
        p.contains('por')) {
      return FantaRole.portiere;
    }
    // Attaccante (incluse Ali e Punte: nel classic le ali sono attaccanti)
    if (p.contains('attaccante') ||
        p.contains('ala') ||
        p.contains('punta') ||
        p.contains('centravanti') ||
        p.contains('attacker') ||
        p.contains('forward') ||
        p.contains('striker') ||
        p.contains('att') ||
        p == 'st' ||
        p == 'cf' ||
        p == 'lw' ||
        p == 'rw' ||
        p == 'fw' ||
        p == 'f') {
      return FantaRole.attaccante;
    }
    // Centrocampista (mediano, regista, trequartista, mezzala...)
    if (p.contains('centrocampista') ||
        p.contains('mediano') ||
        p.contains('regista') ||
        p.contains('trequartista') ||
        p.contains('mezzala') ||
        p.contains('mezz') ||
        p.contains('midfielder') ||
        p.contains('cen') ||
        p == 'cm' ||
        p == 'dm' ||
        p == 'am' ||
        p == 'lm' ||
        p == 'rm' ||
        p == 'mf' ||
        p == 'm') {
      return FantaRole.centrocampista;
    }
    // Difensore (centrale, terzino...)
    if (p.contains('difensore') ||
        p.contains('terzino') ||
        p.contains('centrale') ||
        p.contains('defender') ||
        p.contains('back') ||
        p.contains('dif') ||
        p == 'cb' ||
        p == 'lb' ||
        p == 'rb' ||
        p == 'df' ||
        p == 'd') {
      return FantaRole.difensore;
    }
    // Default: se non riconosciuto, lo mettiamo tra i centrocampisti
    // (scelta neutra; l'utente potra' comunque vederlo e gestirlo).
    return FantaRole.centrocampista;
  }

  /// Restituisce i giocatori della rosa raggruppati per ruolo,
  /// ordinati P -> D -> C -> A. Include solo i ruoli con giocatori.
  Map<FantaRole, List<Player>> rosterByRole() {
    final map = <FantaRole, List<Player>>{};
    for (final role in FantaRole.values) {
      final players =
          _rosterPlayers.where((p) => roleOf(p.position) == role).toList();
      if (players.isNotEmpty) {
        // ordina per nome dentro ogni ruolo
        players.sort((a, b) => a.name.compareTo(b.name));
        map[role] = players;
      }
    }
    return map;
  }

  /// Conta i giocatori per un ruolo specifico.
  int countForRole(FantaRole role) =>
      _rosterPlayers.where((p) => roleOf(p.position) == role).length;

  // ── Aggiungi / Rimuovi ──

  /// Aggiunge o rimuove un giocatore dalla rosa (toggle).
  void toggleRoster(Player player) {
    // [ANTI-DOPPIONI] se esiste gia' un equivalente per nome, rimuovilo
    final dup = _findDuplicate(player.name);
    if (_rosterIds.contains(player.id)) {
      removeFromRoster(player.id);
    } else if (dup != null) {
      removeFromRoster(dup.id);
    } else {
      addToRoster(player);
    }
  }

  void addToRoster(Player player) {
    if (_rosterIds.contains(player.id)) return;
    // [ANTI-DOPPIONI] evita doppioni con nome equivalente (es. Provedel / Ivan Provedel)
    if (_findDuplicate(player.name) != null) return;
    _rosterIds.add(player.id);
    _rosterPlayers.add(player);
    _save();
    notifyListeners();
  }

  void removeFromRoster(int playerId) {
    if (!_rosterIds.contains(playerId)) return;
    _rosterIds.remove(playerId);
    _rosterPlayers.removeWhere((p) => p.id == playerId);
    _save();
    notifyListeners();
  }

  /// Svuota tutta la rosa.
  void clearRoster() {
    _rosterIds.clear();
    _rosterPlayers.clear();
    _save();
    notifyListeners();
  }

  // ── Persistenza ──

  Future<void> loadRoster() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _rosterPlayers.clear();
        _rosterIds.clear();
        for (final item in list) {
          try {
            final player = Player.fromJson(item as Map<String, dynamic>);
            _rosterPlayers.add(player);
            _rosterIds.add(player.id);
          } catch (_) {
            // salta un elemento corrotto senza rompere il caricamento
          }
        }
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('FantaRosterService: errore load: $e');
      _initialized = true;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _rosterPlayers.map((p) => p.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('FantaRosterService: errore save: $e');
    }
  }
}
