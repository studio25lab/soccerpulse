// lib/pages/player_detail_comparison_screen.dart
//
// Schermata di confronto fra 2 giocatori (player1 vs player2).
// Estratta da player_detail_screen.dart per ridurre la dimensione del file.
//
// RINOMINATA da PlayerComparisonScreen a PlayerDetailComparisonScreen per
// evitare conflitto con la classe omonima in player_comparison_screen.dart.
//
// // [FAV-extract-pdcs]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../utils/l10n_helper.dart';
import '../models/player_detail.dart';
import '../painters/player_detail_painters.dart';

class PlayerDetailComparisonScreen extends StatelessWidget {
  final PlayerDetail player1;
  final PlayerDetail player2;

  const PlayerDetailComparisonScreen({
    Key? key,
    required this.player1,
    required this.player2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(context, 'Confronto Giocatori'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlayersHeader(isDark),
            const SizedBox(height: 24),
            _buildRadarComparison(isDark),
            const SizedBox(height: 24),
            _buildStatsComparison(context, isDark),
            const SizedBox(height: 24),
            _buildFormComparison(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerHeaderCard(player1),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [player1.teamColor, player2.teamColor],
              ),
              shape: BoxShape.circle,
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: _buildPlayerHeaderCard(player2),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeaderCard(PlayerDetail player) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: player.teamColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: player.teamColor.withOpacity(0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipOval(
            child: player.photo != null
                ? CachedNetworkImage(
                    imageUrl: player.photo!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: player.teamColor.withOpacity(0.2),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 35),
                    ),
                  )
                : Container(
                    color: player.teamColor.withOpacity(0.2),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          player.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: player.teamColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            player.teamName,
            style: TextStyle(
              fontSize: 11,
              color: player.teamColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniStat('⚽', player.goals.toString(), player.teamColor),
            const SizedBox(width: 8),
            _buildMiniStat('🅰️', player.assists.toString(), player.teamColor),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarComparison(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Confronto Abilità',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(player1.name, player1.teamColor),
              const SizedBox(width: 20),
              _buildLegendItem(player2.name, player2.teamColor),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 280,
              width: 280,
              child: CustomPaint(
                painter: ComparisonRadarChartPainter(
                  skills1: player1.skills,
                  skills2: player2.skills,
                  color1: player1.teamColor,
                  color2: player2.teamColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name.split(' ').last,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsComparison(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            tr(context, 'Statistiche Stagionali'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildComparisonBar(context, tr(context, 'Partite'), player1.matches, player2.matches),
          _buildComparisonBar(context, tr(context, 'Gol'), player1.goals, player2.goals),
          _buildComparisonBar(context, tr(context, 'Assist'), player1.assists, player2.assists),
          _buildComparisonBar(context, tr(context, 'Tiri'), player1.shots, player2.shots),
          _buildComparisonBar(context, tr(context, 'Dribbling'), player1.dribbles, player2.dribbles),
          _buildComparisonBar(context, tr(context, 'Contrasti'), player1.tackles, player2.tackles),
          _buildComparisonBar(context, 
              tr(context, 'Duelli Vinti'), player1.duelsWon, player2.duelsWon),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(BuildContext context, String label, int value1, int value2) {
    final maxValue = math.max(value1, value2);
    final ratio1 = maxValue > 0 ? value1 / maxValue : 0.0;
    final ratio2 = maxValue > 0 ? value2 / maxValue : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value1.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: player1.teamColor,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value2.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: player2.teamColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        widthFactor: ratio1,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                player1.teamColor.withOpacity(0.5),
                                player1.teamColor,
                              ],
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 16,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        widthFactor: ratio2,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                player2.teamColor,
                                player2.teamColor.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormComparison(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Forma Recente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      player1.name.split(' ').last,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: player1.teamColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: player1.recentForm
                          .map((f) => _buildFormDot(f))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: player1.teamColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Media: ${player1.averageRating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: player1.teamColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      player2.name.split(' ').last,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: player2.teamColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: player2.recentForm
                          .map((f) => _buildFormDot(f))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: player2.teamColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Media: ${player2.averageRating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: player2.teamColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormDot(String result) {
    Color color;
    switch (result) {
      case 'W':
        color = Colors.green;
        break;
      case 'D':
        color = Colors.orange;
        break;
      case 'L':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          result,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// COMPARISON RADAR CHART PAINTER
