// lib/widgets/tabs/info_tab.dart
//
// Tab "Info" della partita: dettagli partita, sede, arbitro, meteo,
// forma recente. Estratta da match_detail_screen.dart.
//
// I valori sono attualmente mock hardcoded (capienza, spettatori, meteo,
// forma recente). Quando l-API sara attiva, il wrapper passera i dati
// dal repository.
//
// // [FAV-info-tab]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';

class InfoTab extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final String? leagueName;
  final String? round;
  final DateTime date;
  final String time;
  final String venue;
  final String? referee;

  const InfoTab({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.date,
    required this.time,
    required this.venue,
    this.leagueName,
    this.round,
    this.referee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildInfoTab(context, theme, isDark);
  }

  Widget _buildInfoTab(BuildContext context, ThemeData theme, bool isDark) {
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // ── Dettagli Partita ──
        _infoSection(
          icon: Icons.sports_soccer_rounded,
          title: localizeShotData(context, localizeShotData(context, 'DETTAGLI PARTITA')),
          isDark: isDark, cardBg: cardBg, tx: tx, lb: lb, divider: divider,
          children: [
            _infoRow(localizeShotData(context, 'Competizione'), leagueName ?? 'Serie A', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Giornata'), round ?? 'Giornata 27', tx, lb, divider),
            _infoRow(localizeShotData(context, 'Data'), date.toString().substring(0, 10), tx, lb, divider),
            _infoRow(localizeShotData(context, 'Orario'), time, tx, lb, divider),
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
            _infoRow(localizeShotData(context, 'Stadio'), venue.isNotEmpty ? venue : 'Stadio Olimpico', tx, lb, divider),
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
            _infoRow(localizeShotData(context, 'Arbitro'), referee ?? 'Daniele Orsato', tx, lb, divider),
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
                  Text(homeTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
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
                  Text(awayTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
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
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
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
}
