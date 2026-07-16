// lib/services/fanta_roster_service.dart
// Servizio per la gestione delle ROSE FANTA dell'utente (multi-squadra).
//
// L'utente puo' avere fino a MAX_SQUADS squadre (rose), ognuna con nome,
// ordine e propri giocatori. Utile per chi gioca in piu' leghe Fantacalcio.
// Indipendente dai preferiti. Persiste su SharedPreferences.
//
// Retrocompatibilita': i metodi "classici" (toggleRoster, isInRoster,
// count, rosterByRole, ...) operano sulla SQUADRA ATTIVA, cosi' le UI
// esistenti continuano a funzionare senza modifiche.
//
// Migrazione: se esiste la vecchia rosa singola (chiave legacy) ma non
// il nuovo formato, viene convertita nella squadra "La mia rosa".
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

/// Una squadra Fanta: nome + lista di giocatori.
class FantaSquad {
  final String id;
  String name;
  final List<Player> players;

  FantaSquad({
    required this.id,
    required this.name,
    List<Player>? players,
  }) : players = players ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory FantaSquad.fromJson(Map<String, dynamic> json) {
    final list = (json['players'] as List<dynamic>?) ?? [];
    final players = <Player>[];
    for (final item in list) {
      try {
        players.add(Player.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // salta elemento corrotto
      }
    }
    return FantaSquad(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'La mia rosa',
      players: players,
    );
  }
}

class FantaRosterService extends ChangeNotifier {
  // Chiave nuovo formato (multi-squadra).
  static const String _squadsKey = 'fanta_squads';
  static const String _activeKey = 'fanta_active_squad';
  // Chiave legacy (rosa singola) - per migrazione.
  static const String _legacyKey = 'fanta_roster_players';

  /// Numero massimo di squadre consentite.
  static const int maxSquads = 5;

  final List<FantaSquad> _squads = [];
  String? _activeSquadId;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ── Getters squadre ──
  List<FantaSquad> get squads => List.unmodifiable(_squads);
  int get squadCount => _squads.length;
  bool get canAddSquad => _squads.length < maxSquads;

  /// La squadra attualmente attiva (visualizzata). Se nessuna, la prima.
  FantaSquad? get activeSquad {
    if (_squads.isEmpty) return null;
    final found = _squads.where((s) => s.id == _activeSquadId);
    if (found.isNotEmpty) return found.first;
    return _squads.first;
  }

  String? get activeSquadId => activeSquad?.id;

  /// Imposta la squadra attiva per id.
  void setActiveSquad(String squadId) {
    if (_squads.any((s) => s.id == squadId)) {
      _activeSquadId = squadId;
      _saveActive();
      notifyListeners();
    }
  }

  // ── Getters "classici" (operano sulla SQUADRA ATTIVA) ──
  List<Player> get rosterPlayers =>
      List.unmodifiable(activeSquad?.players ?? const []);
  int get count => activeSquad?.players.length ?? 0;
  bool get isEmpty => (activeSquad?.players.isEmpty ?? true);

  /// Verifica se un giocatore e' nella squadra ATTIVA (per la stella).
  bool isInRoster(int playerId) =>
      activeSquad?.players.any((p) => p.id == playerId) ?? false;

  // ── Prevenzione doppioni (per nome) ──

  String _normName(String name) {
    var s = name.toLowerCase().trim();
    const fromCh = 'àáâãäèéêëìíîïòóôõöùúûüñç';
    const toCh = 'aaaaaeeeeiiiiooooouuuunc';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = fromCh.indexOf(ch);
      buf.write(i >= 0 ? toCh[i] : ch);
    }
    s = buf.toString().replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

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

  /// Cerca un duplicato per nome DENTRO una squadra specifica.
  Player? _findDuplicateInSquad(FantaSquad squad, String name) {
    for (final p in squad.players) {
      if (_sameName(p.name, name)) return p;
    }
    return null;
  }

  /// isInRoster per nome, sulla squadra ATTIVA (per coerenza stelle).
  bool isInRosterByName(String name) {
    final sq = activeSquad;
    if (sq == null) return false;
    return _findDuplicateInSquad(sq, name) != null;
  }

  /// Verifica se un giocatore (per nome) e' in una squadra SPECIFICA.
  bool isInSquadByName(String squadId, String name) {
    final found = _squads.where((s) => s.id == squadId);
    if (found.isEmpty) return false;
    return _findDuplicateInSquad(found.first, name) != null;
  }

  // ── Mappatura ruolo (invariata) ──
  static FantaRole roleOf(String position) {
    final p = position.toLowerCase();
    if (p.contains('portiere') ||
        p.contains('gk') ||
        p.contains('goalkeeper') ||
        p == 'g' ||
        p.contains('por')) {
      return FantaRole.portiere;
    }
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
    return FantaRole.centrocampista;
  }

  /// Giocatori della squadra ATTIVA raggruppati per ruolo.
  Map<FantaRole, List<Player>> rosterByRole() => rosterByRoleFor(activeSquad);

  /// Giocatori di una squadra specifica raggruppati per ruolo.
  Map<FantaRole, List<Player>> rosterByRoleFor(FantaSquad? squad) {
    final map = <FantaRole, List<Player>>{};
    if (squad == null) return map;
    for (final role in FantaRole.values) {
      final players =
          squad.players.where((p) => roleOf(p.position) == role).toList();
      if (players.isNotEmpty) {
        players.sort((a, b) => a.name.compareTo(b.name));
        map[role] = players;
      }
    }
    return map;
  }

  /// Conta i giocatori per un ruolo nella squadra ATTIVA.
  int countForRole(FantaRole role) =>
      activeSquad?.players.where((p) => roleOf(p.position) == role).length ?? 0;

  // ── Aggiungi / Rimuovi (sulla SQUADRA ATTIVA) ──

  /// Toggle sulla squadra attiva (retrocompatibile con le stelle).
  void toggleRoster(Player player) {
    final sq = activeSquad;
    if (sq == null) return;
    toggleInSquad(sq.id, player);
  }

  void addToRoster(Player player) {
    final sq = activeSquad;
    if (sq == null) return;
    addToSquad(sq.id, player);
  }

  void removeFromRoster(int playerId) {
    final sq = activeSquad;
    if (sq == null) return;
    removeFromSquad(sq.id, playerId);
  }

  // ── Aggiungi / Rimuovi su squadra SPECIFICA ──

  void toggleInSquad(String squadId, Player player) {
    final found = _squads.where((s) => s.id == squadId);
    if (found.isEmpty) return;
    final sq = found.first;
    final dup = _findDuplicateInSquad(sq, player.name);
    if (sq.players.any((p) => p.id == player.id)) {
      removeFromSquad(squadId, player.id);
    } else if (dup != null) {
      removeFromSquad(squadId, dup.id);
    } else {
      addToSquad(squadId, player);
    }
  }

  void addToSquad(String squadId, Player player) {
    final found = _squads.where((s) => s.id == squadId);
    if (found.isEmpty) return;
    final sq = found.first;
    if (sq.players.any((p) => p.id == player.id)) return;
    // no doppioni per nome DENTRO la stessa squadra
    if (_findDuplicateInSquad(sq, player.name) != null) return;
    sq.players.add(player);
    _saveSquads();
    notifyListeners();
  }

  void removeFromSquad(String squadId, int playerId) {
    final found = _squads.where((s) => s.id == squadId);
    if (found.isEmpty) return;
    final sq = found.first;
    sq.players.removeWhere((p) => p.id == playerId);
    _saveSquads();
    notifyListeners();
  }

  /// Svuota la squadra attiva.
  void clearRoster() {
    final sq = activeSquad;
    if (sq == null) return;
    sq.players.clear();
    _saveSquads();
    notifyListeners();
  }

  // ── Gestione squadre (crea / rinomina / elimina / riordina) ──

  /// Crea una nuova squadra. Ritorna l'id, o null se raggiunto il massimo.
  String? createSquad(String name) {
    if (_squads.length >= maxSquads) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final cleanName = name.trim().isEmpty ? 'Nuova squadra' : name.trim();
    _squads.add(FantaSquad(id: id, name: cleanName));
    _activeSquadId = id; // la nuova diventa attiva
    _saveSquads();
    _saveActive();
    notifyListeners();
    return id;
  }

  void renameSquad(String squadId, String newName) {
    final found = _squads.where((s) => s.id == squadId);
    if (found.isEmpty) return;
    final clean = newName.trim();
    if (clean.isEmpty) return;
    found.first.name = clean;
    _saveSquads();
    notifyListeners();
  }

  /// Elimina una squadra. Non permette di scendere sotto 1 squadra.
  void deleteSquad(String squadId) {
    if (_squads.length <= 1) return; // deve restare almeno una squadra
    _squads.removeWhere((s) => s.id == squadId);
    if (_activeSquadId == squadId) {
      _activeSquadId = _squads.isNotEmpty ? _squads.first.id : null;
      _saveActive();
    }
    _saveSquads();
    notifyListeners();
  }

  /// Riordina le squadre (drag & drop).
  void reorderSquads(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _squads.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= _squads.length) target = _squads.length - 1;
    final item = _squads.removeAt(oldIndex);
    _squads.insert(target, item);
    _saveSquads();
    notifyListeners();
  }

  // ── Persistenza ──

  Future<void> loadRoster() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawSquads = prefs.getString(_squadsKey);

      if (rawSquads != null && rawSquads.isNotEmpty) {
        // Nuovo formato presente
        final list = jsonDecode(rawSquads) as List<dynamic>;
        _squads.clear();
        for (final item in list) {
          try {
            _squads.add(FantaSquad.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
        _activeSquadId = prefs.getString(_activeKey);
      } else {
        // Nessun nuovo formato: prova migrazione dalla rosa singola legacy
        await _migrateFromLegacy(prefs);
      }

      // Garantisci sempre almeno una squadra
      if (_squads.isEmpty) {
        _squads.add(FantaSquad(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'La mia rosa',
        ));
        await _saveSquads();
      }
      // Attiva valida
      if (_activeSquadId == null ||
          !_squads.any((s) => s.id == _activeSquadId)) {
        _activeSquadId = _squads.first.id;
        await _saveActive();
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('FantaRosterService: errore load: $e');
      // fallback: una squadra vuota
      if (_squads.isEmpty) {
        _squads.add(FantaSquad(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'La mia rosa',
        ));
        _activeSquadId = _squads.first.id;
      }
      _initialized = true;
    }
  }

  /// Converte la vecchia rosa singola (se esiste) nella squadra "La mia rosa".
  Future<void> _migrateFromLegacy(SharedPreferences prefs) async {
    final rawLegacy = prefs.getString(_legacyKey);
    final players = <Player>[];
    if (rawLegacy != null && rawLegacy.isNotEmpty) {
      try {
        final list = jsonDecode(rawLegacy) as List<dynamic>;
        for (final item in list) {
          try {
            players.add(Player.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      } catch (_) {}
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _squads
      ..clear()
      ..add(FantaSquad(id: id, name: 'La mia rosa', players: players));
    _activeSquadId = id;
    await _saveSquads();
    await _saveActive();
    // manteniamo la vecchia chiave per sicurezza (non la cancelliamo)
  }

  Future<void> _saveSquads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _squads.map((s) => s.toJson()).toList();
      await prefs.setString(_squadsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('FantaRosterService: errore save squads: $e');
    }
  }

  Future<void> _saveActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeSquadId != null) {
        await prefs.setString(_activeKey, _activeSquadId!);
      }
    } catch (e) {
      debugPrint('FantaRosterService: errore save active: $e');
    }
  }
}
