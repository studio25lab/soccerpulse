// lib/widgets/fanta_squad_picker.dart
// Helper condiviso per aggiungere un giocatore alla Rosa Fanta,
// gestendo il caso multi-squadra.
//
// - 1 squadra  -> toggle diretto sulla squadra attiva
// - piu' squadre -> bottom sheet "In quale squadra?" con checkbox
//   (il giocatore puo' stare in piu' squadre diverse)
//
// Usato da tutte le stelle (scheda, ricerca, preferiti, top giocatori).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../services/fanta_roster_service.dart';
import '../services/haptic_service.dart';
import '../utils/l10n_helper.dart';

final HapticService _pickerHaptic = HapticService();

/// Gestisce il tap sulla stella per un giocatore.
/// Con 1 squadra fa il toggle diretto; con piu' squadre apre il picker.
void handleStarTap(BuildContext context, Player player) {
  final roster = context.read<FantaRosterService>();
  if (roster.squadCount <= 1) {
    // comportamento classico: toggle sulla squadra attiva
    final wasIn = roster.isInRosterByName(player.name);
    roster.toggleRoster(player);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasIn
            ? '${player.name} ${tr(context, 'rimosso dalla rosa')}'
            : '${player.name} ${tr(context, 'aggiunto alla rosa')}'),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    _showSquadPicker(context, player);
  }
}

void _showSquadPicker(BuildContext context, Player player) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
  final tx = isDark ? Colors.white : const Color(0xFF1A1A2E);
  final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
  const purple = Color(0xFF9C27B0);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer<FantaRosterService>(
        builder: (ctx, roster, _) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: purple, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'In quale squadra?'),
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: tx),
                            ),
                            Text(
                              player.name,
                              style: TextStyle(fontSize: 13, color: lb),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // lista squadre con checkbox
                ...roster.squads.map((sq) {
                  final inSquad = roster.isInSquadByName(sq.id, player.name);
                  return ListTile(
                    onTap: () {
                      _pickerHaptic.lightImpact();
                      if (inSquad) {
                        // rimuovi (trova il duplicato e togli per id)
                        final dup = sq.players.where((p) =>
                            _sameNameLoose(p.name, player.name));
                        if (dup.isNotEmpty) {
                          roster.removeFromSquad(sq.id, dup.first.id);
                        }
                      } else {
                        roster.addToSquad(sq.id, player);
                      }
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: inSquad
                            ? purple.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: inSquad ? purple : lb,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      sq.name,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: tx),
                    ),
                    subtitle: Text(
                      '${sq.players.length} ${tr(context, 'giocatori')}',
                      style: TextStyle(fontSize: 12, color: lb),
                    ),
                    trailing: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: inSquad ? purple : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: inSquad ? purple : lb,
                          width: 2,
                        ),
                      ),
                      child: inSquad
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        tr(context, 'Fatto'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
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

// Confronto nomi "loose" (per trovare il duplicato da rimuovere).
// Deve combaciare con la logica del servizio.
bool _sameNameLoose(String a, String b) {
  String norm(String s) {
    var r = s.toLowerCase().trim();
    const fromCh = 'àáâãäèéêëìíîïòóôõöùúûüñç';
    const toCh = 'aaaaaeeeeiiiiooooouuuunc';
    final buf = StringBuffer();
    for (final ch in r.split('')) {
      final i = fromCh.indexOf(ch);
      buf.write(i >= 0 ? toCh[i] : ch);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  final na = norm(a);
  final nb = norm(b);
  if (na == nb) return true;
  if (na.isEmpty || nb.isEmpty) return false;
  if (na.contains(nb) || nb.contains(na)) return true;
  final lastA = na.split(' ').last;
  final lastB = nb.split(' ').last;
  if (lastA.length >= 4 && lastA == lastB) return true;
  return false;
}
