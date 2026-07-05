// lib/pages/coach_profile_screen.dart
//
// Schermata profilo allenatore.
// Mostra info anagrafiche, statistiche di carriera, esperienza.
// Estratta da match_detail_screen.dart.
//
// // [FAV-coach-extract]

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';

class CoachProfileScreen extends StatelessWidget {
  final String coachName;
  final String teamName;
  final Color teamColor;
  final Map<String, dynamic> data;

  const CoachProfileScreen({
    super.key,
    required this.coachName,
    required this.teamName,
    required this.teamColor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F2F5);
    final tx = isDark ? Colors.white : Colors.black87;
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);
    final sectionBg = isDark ? const Color(0xFF16162A) : const Color(0xFFF8F9FA);
    final career = data['career'] as List<Map<String, String>>;
    final stats = data['stats'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar con header ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D0D1A) : teamColor,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      teamColor.withValues(alpha: 0.9),
                      teamColor.withValues(alpha: 0.6),
                      scaffoldBg,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            coachName.split(' ').map((w) => w[0]).take(2).join(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(coachName,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${tr(context, 'Allenatore')} · ${data['teamFull']}',
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _chip(tr(context, data['nationality'] as String? ?? '')),
                        const SizedBox(width: 8),
                        _chip('${data['age']} ${tr(context, 'anni')}'),
                        const SizedBox(width: 8),
                        _chip(tr(context, data['born'] as String? ?? '')),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Modulo e Stile ──
                _section(
                  isDark: isDark,
                  sectionBg: sectionBg,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionHeader(Icons.dashboard_rounded, tr(context, 'MODULO E STILE'), isDark),
                    const SizedBox(height: 14),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [teamColor.withValues(alpha: 0.2), teamColor.withValues(alpha: 0.08)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: teamColor.withValues(alpha: 0.3)),
                        ),
                        child: Text('${data['formation']}',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: teamColor, letterSpacing: 3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (data['style'] as String).split(', ').map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: teamColor.withValues(alpha: 0.25)),
                        ),
                        child: Text(tr(context, tag), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: teamColor)),
                      )).toList(),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Filosofia Tattica ──
                _section(
                  isDark: isDark,
                  sectionBg: sectionBg,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionHeader(Icons.psychology_rounded, tr(context, 'FILOSOFIA TATTICA'), isDark),
                    const SizedBox(height: 12),
                    Text(tr(context, data['philosophy'] as String? ?? ''),
                        style: TextStyle(fontSize: 14, color: tx, height: 1.7)),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Record Stagionale ──
                _section(
                  isDark: isDark,
                  sectionBg: sectionBg,
                  child: Column(children: [
                    _sectionHeader(Icons.emoji_events_rounded, tr(context, 'RECORD STAGIONALE'), isDark),
                    const SizedBox(height: 14),
                    Row(children: [
                      _statBox(formInitial(context, 'W'), '${data['seasonW']}', const Color(0xFF4CAF50), isDark),
                      const SizedBox(width: 8),
                      _statBox(formInitial(context, 'D'), '${data['seasonD']}', Colors.amber, isDark),
                      const SizedBox(width: 8),
                      _statBox(formInitial(context, 'L'), '${data['seasonL']}', const Color(0xFFE53935), isDark),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Row(children: [
                          Expanded(flex: data['seasonW'] as int, child: Container(color: const Color(0xFF4CAF50))),
                          Expanded(flex: data['seasonD'] as int, child: Container(color: Colors.amber)),
                          Expanded(flex: data['seasonL'] as int, child: Container(color: const Color(0xFFE53935))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      _infoTile(localizeShotData(context, 'Gol Fatti'), '${data['seasonGoalsFor']}', tx, lb),
                      Container(width: 1, height: 30, color: divider),
                      _infoTile(localizeShotData(context, 'Gol Subiti'), '${data['seasonGoalsAgainst']}', tx, lb),
                      Container(width: 1, height: 30, color: divider),
                      _infoTile(localizeShotData(context, 'Clean Sheet'), '${stats['cleanSheets']}', tx, lb),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Statistiche ──
                _section(
                  isDark: isDark,
                  sectionBg: sectionBg,
                  child: Column(children: [
                    _sectionHeader(Icons.bar_chart_rounded, tr(context, 'STATISTICHE'), isDark),
                    const SizedBox(height: 14),
                    Row(children: [
                      _infoTile(localizeShotData(context, 'Partite'), '${stats['matches']}', tx, lb),
                      Container(width: 1, height: 30, color: divider),
                      _infoTile(localizeShotData(context, '% Vittorie'), '${stats['winRate']}%', tx, lb),
                      Container(width: 1, height: 30, color: divider),
                      _infoTile(localizeShotData(context, 'Gol/Partita'), '${stats['avgGoals']}', tx, lb),
                      Container(width: 1, height: 30, color: divider),
                      _infoTile(localizeShotData(context, 'Punti/Partita'), '${stats['avgPoints']}', tx, lb),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Carriera ──
                _section(
                  isDark: isDark,
                  sectionBg: sectionBg,
                  child: Column(children: [
                    _sectionHeader(Icons.timeline_rounded, tr(context, 'CARRIERA'), isDark),
                    const SizedBox(height: 8),
                    ...career.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      final isFirst = i == 0;
                      final isLast = i == career.length - 1;
                      final role = c['role'] ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: divider)),
                        ),
                        child: Row(children: [
                          // Timeline
                          SizedBox(
                            width: 30,
                            child: Center(
                              child: Container(
                                width: isFirst ? 14 : 10,
                                height: isFirst ? 14 : 10,
                                decoration: BoxDecoration(
                                  color: isFirst ? teamColor : (isDark ? Colors.white24 : Colors.grey[400]),
                                  shape: BoxShape.circle,
                                  border: isFirst ? Border.all(color: teamColor.withValues(alpha: 0.3), width: 3) : null,
                                  boxShadow: isFirst ? [BoxShadow(color: teamColor.withValues(alpha: 0.3), blurRadius: 8)] : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(child: Text(c['team']!,
                                    style: TextStyle(fontSize: 15, fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600, color: tx))),
                                if (role.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: role == 'Allenatore' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(role, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                      color: role == 'Allenatore' ? Colors.blue : Colors.green[700])),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 2),
                              Text(c['period']!,
                                  style: TextStyle(fontSize: 12, color: lb)),
                            ],
                          )),
                          if (c['trophy']!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Text(c['trophy']!, style: const TextStyle(fontSize: 12)),
                            ),
                        ]),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _section({required bool isDark, required Color sectionBg, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title, bool isDark) {
    return Row(children: [
      Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 1.5)),
    ]);
  }

  Widget _statBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }

  Widget _infoTile(String label, String value, Color tx, Color lb) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: lb, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAYER COMPARISON SCREEN — Schede affiancate con scroll indipendente
// ═══════════════════════════════════════════════════════════════════════════
