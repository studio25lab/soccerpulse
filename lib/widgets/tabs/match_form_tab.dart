// lib/widgets/tabs/match_form_tab.dart
//
// Tab "Forma" pre-match: mostra la forma recente di entrambe le squadre
// (ultime ~5 partite). Estratta da match_detail_screen.dart.
//
// La tab e' un widget puro: riceve dati gia calcolati via costruttore.
// I dati (forma, colori squadre, URL loghi) vengono preparati dallo state
// padre e passati come parametri. Per la navigazione su una partita della
// lista, riceve un callback onMatchTap.
//
// // [FAV-formtab]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/l10n_helper.dart';
import '../../models/soccer_match.dart';
import '../team_form_section.dart';

class MatchFormTab extends StatefulWidget {
  final String homeName;
  final String awayName;
  final Color homeColor;
  final Color awayColor;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final List<Map<String, dynamic>> homeForm;
  final List<Map<String, dynamic>> awayForm;

  // Helper opzionali per i loghi delle squadre AVVERSARIE nei singoli match.
  // Se non forniti, viene usato l-abbreviazione del nome.
  final String Function(String teamName)? opponentLogoUrl;
  final Color Function(String teamName)? opponentColor;

  // Callback chiamato quando si tappa una partita della forma.
  // Riceve un SoccerMatch costruito al volo dalla tab.
  final void Function(SoccerMatch) onMatchTap;

  const MatchFormTab({
    Key? key,
    required this.homeName,
    required this.awayName,
    required this.homeColor,
    required this.awayColor,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.homeForm,
    required this.awayForm,
    required this.onMatchTap,
    this.opponentLogoUrl,
    this.opponentColor,
  }) : super(key: key);

  @override
  State<MatchFormTab> createState() => _MatchFormTabState();
}

class _MatchFormTabState extends State<MatchFormTab> {
  // [FAV-form-limit-filter]
  // null = mostra tutte; altrimenti limite al numero di partite mostrate
  // nella match list dettagliata. I form dots (chips V/P/S) restano sempre 5.
  int? _formLimit = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.withOpacity(0.1);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // [FAV-chip-disable] passa max tra home/away per disabilitare
        // chip che richiedono piu partite di quelle disponibili
        _buildLimitSelector(isDark, tx, lb,
            widget.homeForm.length > widget.awayForm.length
                ? widget.homeForm.length
                : widget.awayForm.length),
        const SizedBox(height: 14),
        // [FAV-team-form-refactor] sostituito con TeamFormSection riusabile
        TeamFormSection(
          teamName: widget.homeName,
          form: widget.homeForm,
          formLimit: _formLimit,
          teamColor: widget.homeColor,
          cardBg: cardBg,
          tx: tx,
          lb: lb,
          divider: divider,
          opponentLogoUrl: widget.opponentLogoUrl,
          opponentColor: widget.opponentColor,
          onMatchTap: widget.onMatchTap,
        ),
        const SizedBox(height: 16),
        TeamFormSection(
          teamName: widget.awayName,
          form: widget.awayForm,
          formLimit: _formLimit,
          teamColor: widget.awayColor,
          cardBg: cardBg,
          tx: tx,
          lb: lb,
          divider: divider,
          opponentLogoUrl: widget.opponentLogoUrl,
          opponentColor: widget.opponentColor,
          onMatchTap: widget.onMatchTap,
        ),
      ]),
    );
  }

  // [FAV-form-limit-filter] selettore numero partite mostrate
  // [FAV-chip-disable] disabilita chip se value > totalMatches
  Widget _buildLimitSelector(bool isDark, Color tx, Color lb, int totalMatches) {
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    Widget chip(String label, int? value) {
      final active = _formLimit == value;
      final disabled = value != null && totalMatches < value;
      return GestureDetector(
        onTap: disabled
            ? null
            : () => setState(() => _formLimit = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: disabled
                      ? (isDark ? Colors.grey[700] : Colors.grey[400])
                      : (active ? tx : lb))),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          chip('5', 5),
          const SizedBox(width: 4),
          chip('10', 10),
          const SizedBox(width: 4),
          chip('20', 20),
          const SizedBox(width: 4),
          chip(tr(context, 'Tutte'), null),
        ]),
      ),
    );
  }

}
