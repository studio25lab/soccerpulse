// lib/pages/fanta_roster_screen.dart
// Schermata "Rosa Fanta": i giocatori scelti dall'utente, divisi nei 4
// ruoli classici del fantacalcio (Portieri, Difensori, Centrocampisti,
// Attaccanti). Per ogni giocatore: ultimo voto, media voti, media
// fantavoto, statistiche rapide + accesso alle notifiche (dalla scheda).
//
// Indipendente dai preferiti. I giocatori si aggiungono con la stella
// nella ricerca / preferiti / scheda giocatore.
//
// NB: voto/media/fantavoto sono placeholder ora; dati reali con le API
// (FASE 5) e l'algoritmo "Voto Matchline".
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/local_lineup_player.dart';
import '../services/fanta_roster_service.dart';
import '../services/haptic_service.dart';
import '../utils/l10n_helper.dart';
import 'match_player_profile_screen.dart';

class FantaRosterScreen extends StatefulWidget {
  const FantaRosterScreen({super.key});

  @override
  State<FantaRosterScreen> createState() => _FantaRosterScreenState();
}

class _FantaRosterScreenState extends State<FantaRosterScreen> {
  final HapticService _haptic = HapticService();

  // Colore associato al ruolo (coerente con lo stile dei preferiti).
  Color _roleColor(FantaRole role) {
    switch (role) {
      case FantaRole.portiere:
        return const Color(0xFFFFA726); // arancio
      case FantaRole.difensore:
        return const Color(0xFF1E88E5); // blu
      case FantaRole.centrocampista:
        return const Color(0xFF43A047); // verde
      case FantaRole.attaccante:
        return const Color(0xFFE53935); // rosso
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<FantaRosterService>(
          builder: (context, roster, _) {
            final byRole = roster.rosterByRole();
            return CustomScrollView(
              slivers: [
                _buildHeader(context, roster, isDark, theme),
                if (roster.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark, theme),
                  )
                else
                  ...byRole.entries.map((entry) => _buildRoleSection(
                        entry.key,
                        entry.value,
                        isDark,
                        theme,
                        roster,
                      )),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context, FantaRosterService roster,
      bool isDark, ThemeData theme) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.star, color: Color(0xFF9C27B0), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'Rosa Fanta'),
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: tx),
                  ),
                  Text(
                    roster.isEmpty
                        ? tr(context, 'Nessun giocatore in rosa')
                        : '${roster.count} ${tr(context, 'giocatori in rosa')}',
                    style: TextStyle(fontSize: 13, color: lb),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stato vuoto ──
  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_outline,
                size: 64, color: Color(0xFF9C27B0)),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'La tua rosa è vuota'),
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tx),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            tr(context,
                'Aggiungi i tuoi giocatori toccando la stella nella ricerca, nei preferiti o nella scheda giocatore.'),
            style: TextStyle(fontSize: 14, color: lb, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Sezione ruolo ──
  Widget _buildRoleSection(FantaRole role, List<Player> players, bool isDark,
      ThemeData theme, FantaRosterService roster) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final color = _roleColor(role);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // intestazione ruolo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  tr(context, role.labelPlural),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: tx),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${players.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
          // card giocatori
          ...players.map((p) => _buildPlayerCard(p, role, isDark, theme, roster)),
        ],
      ),
    );
  }

  // ── Card giocatore ──
  Widget _buildPlayerCard(Player p, FantaRole role, bool isDark,
      ThemeData theme, FantaRosterService roster) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final color = _roleColor(role);

    // ── DATI VOTO (placeholder: reali con le API - FASE 5) ──
    final double lastVote = p.rating > 0 ? p.rating : 6.0;
    final double avgVote = p.rating > 0 ? p.rating : 6.0;
    // fantavoto mock = voto + bonus stimato da gol/assist
    final int g = p.goals ?? 0;
    final int a = p.assists ?? 0;
    final double avgFanta = avgVote + (g * 3 + a * 1) / 10.0;

    return Dismissible(
      key: ValueKey('roster_${p.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.star, color: Colors.white),
      ),
      onDismissed: (_) {
        _haptic.mediumImpact();
        roster.removeFromRoster(p.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.name} ${tr(context, 'rimosso dalla rosa')}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openPlayer(p),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // foto giocatore
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: p.photo ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 48,
                    color: color.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: color, size: 26),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: color.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: color, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // nome + squadra
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tx),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.teamLogo != null && p.teamLogo!.isNotEmpty) ...[
                          CachedNetworkImage(
                            imageUrl: p.teamLogo!,
                            width: 16,
                            height: 16,
                            errorWidget: (_, __, ___) =>
                                const SizedBox(width: 16, height: 16),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            p.teamName,
                            style: TextStyle(fontSize: 12, color: lb),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // statistiche rapide
                    Row(
                      children: [
                        _miniStat('⚽', '$g', lb),
                        const SizedBox(width: 12),
                        _miniStat('🅰️', '$a', lb),
                        const SizedBox(width: 12),
                        _miniStat('📊', '${p.appearances ?? 0}', lb),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // voti (ultimo, media, fantavoto)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _voteBadge(tr(context, 'Ultimo'), lastVote, color),
                  const SizedBox(height: 4),
                  _voteLine(tr(context, 'Media'), avgVote, lb),
                  _voteLine('FV', avgFanta, lb),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String value, Color lb) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: lb)),
      ],
    );
  }

  // badge voto principale (ultimo voto)
  Widget _voteBadge(String label, double vote, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _voteColor(vote).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: _voteColor(vote))),
          Text(
            vote.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _voteColor(vote)),
          ),
        ],
      ),
    );
  }

  // riga voto secondaria (media / fantavoto)
  Widget _voteLine(String label, double vote, Color lb) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ',
              style: TextStyle(fontSize: 10, color: lb)),
          Text(
            vote.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: lb),
          ),
        ],
      ),
    );
  }

  // colore in base al valore del voto (rosso<6, giallo 6-6.5, verde>6.5)
  Color _voteColor(double vote) {
    if (vote >= 7.0) return const Color(0xFF2E7D32);
    if (vote >= 6.5) return const Color(0xFF43A047);
    if (vote >= 6.0) return const Color(0xFFF9A825);
    return const Color(0xFFE53935);
  }

  // ── Naviga alla scheda giocatore (converte Player -> LocalLineupPlayer) ──
  void _openPlayer(Player p) {
    _haptic.lightImpact();
    final llp = LocalLineupPlayer(
      number: p.id % 100,
      name: p.name,
      position: p.position.contains('Attacc') ||
              p.position.toLowerCase().contains('ala')
          ? 'F'
          : p.position.contains('Centroc')
              ? 'M'
              : p.position.contains('Difen') || p.position.contains('Terz')
                  ? 'D'
                  : p.position.contains('Portiere')
                      ? 'G'
                      : 'M',
      rating: p.rating,
      goals: p.goals ?? 0,
      assists: p.assists ?? 0,
      shots: p.shots ?? 0,
      shotsOnTarget: p.shotsOnTarget ?? 0,
      yellowCards: p.yellowCards ?? 0,
      redCards: p.redCards ?? 0,
      minutesPlayed: (p.appearances ?? 0) * 78,
      passes: p.passes ?? 0,
      passesCompleted: p.passesCompleted ?? 0,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchPlayerProfileScreen(
          player: llp,
          teamName: p.teamName,
          teamColor: _roleColor(FantaRosterService.roleOf(p.position)),
        ),
      ),
    );
  }
}
