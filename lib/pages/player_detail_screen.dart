import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../models/player_detail.dart';
import '../painters/player_detail_painters.dart';
import '../widgets/dialogs/player_comparison_dialog.dart';
import 'player_detail_comparison_screen.dart';

class PlayerDetailScreen extends StatefulWidget {
  final PlayerDetail player;
  final bool isLive;

  const PlayerDetailScreen({
    Key? key,
    required this.player,
    this.isLive = false,
  }) : super(key: key);

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Heatmap & Pass Map expand state
  bool _heatmapExpanded = false;
  bool _passMapExpanded = false;

  // Pass Map filters
  String _selectedPassType = 'Pass';
  String _selectedAccuracy = 'Tutti i passaggi';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          _buildTabBar(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, isDark),
                _buildStatsTab(theme, isDark),
                _buildInfoTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.player.teamColor,
            widget.player.teamColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (widget.isLive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.compare_arrows,
                      color: Colors.white, size: 28),
                  tooltip: tr(context, tr(context, 'Confronta giocatori')),
                  onPressed: () {
                    _showPlayerComparisonDialog(context);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Hero(
                tag: 'player_${widget.player.number}',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.player.photo != null
                        ? CachedNetworkImage(
                            imageUrl: widget.player.photo!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(
                                    color: Colors.white),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 50),
                            ),
                          )
                        : Container(
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 50),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${widget.player.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.player.position,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.shield, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.player.teamName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBubble(tr(context, 'Partite'), widget.player.matches.toString()),
              _buildStatBubble('Gol', widget.player.goals.toString()),
              _buildStatBubble('Assist', widget.player.assists.toString()),
              _buildStatBubble(
                  'Voto', widget.player.averageRating.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: TabBar(
        controller: _tabController,
        labelColor: widget.player.teamColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: widget.player.teamColor,
        tabs: [
          Tab(text: 'Panoramica'),
          Tab(text: tr(context, 'Statistiche')),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceSection(theme, isDark),
          const SizedBox(height: 24),
          _buildRecentFormSection(theme, isDark),
          const SizedBox(height: 24),
          _buildSkillsRadarSection(theme, isDark),
          const SizedBox(height: 24),

          // NEW: Heatmap Section
          _buildHeatmapSection(isDark),
          const SizedBox(height: 24),

          // NEW: Pass Map Section
          _buildPassMapSection(isDark),
        ],
      ),
    );
  }

  // NEW: Heatmap Section
  Widget _buildHeatmapSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _heatmapExpanded = !_heatmapExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.player.teamColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/icons/field_icon.png',
                      color: widget.player.teamColor,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.grid_on,
                        color: widget.player.teamColor,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(context, 'Mappa di calore della partita'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _heatmapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_heatmapExpanded) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Direction indicator (like in screenshot)
                  Row(
                    children: [
                      const Spacer(),
                      Icon(Icons.arrow_back, size: 32, color: Colors.grey[600]),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Heatmap
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(
                          painter: HeatmapPainter(
                            positions: widget.player.heatmapPositions ??
                                _generateMockHeatmapPositions(),
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Pass Map Section
  Widget _buildPassMapSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _passMapExpanded = !_passMapExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.player.teamColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.show_chart,
                      color: widget.player.teamColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(context, 'Statistiche'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _passMapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_passMapExpanded) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Type filters (Shot, Pass, Drib, Def)
                  Row(
                    children: [
                      _buildPassTypeChip('Shot', isDark),
                      const SizedBox(width: 8),
                      _buildPassTypeChip('Pass', isDark),
                      const SizedBox(width: 8),
                      _buildPassTypeChip('Drib', isDark),
                      const SizedBox(width: 8),
                      _buildPassTypeChip('Def', isDark),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Accuracy filters
                  Row(
                    children: [
                      _buildAccuracyChip('Tutti i passaggi', isDark),
                      const SizedBox(width: 8),
                      _buildAccuracyChip('Accurato', isDark),
                      const SizedBox(width: 8),
                      _buildAccuracyChip('Non accurato', isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pass Map
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(
                          painter: PassMapPainter(
                            passes: _getFilteredPasses(),
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pass statistics
                  _buildPassStatistics(isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassTypeChip(String label, bool isDark) {
    final isSelected = _selectedPassType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPassType = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.player.teamColor
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyChip(String label, bool isDark) {
    final isSelected = _selectedAccuracy == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAccuracy = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.player.teamColor
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildPassStatistics(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPassStatItem(
                  'Assists', widget.player.assists.toString(), isDark),
              _buildPassStatItem(
                  tr(context, 'Assist previsti (xA)'),
                  widget.player.expectedAssists?.toStringAsFixed(2) ?? '0.00',
                  isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPassStatItem('Grandi occasioni create',
                  widget.player.bigChancesCreated?.toString() ?? '0', isDark),
              _buildPassStatItem(tr(context, 'Passaggi chiave'),
                  widget.player.keyPasses?.toString() ?? '0', isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPassStatItem(
                    'Cross (prec.)',
                    '${widget.player.totalCrosses ?? 0} (${widget.player.accurateCrosses ?? 0})',
                    isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassStatItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  List<PassData> _getFilteredPasses() {
    final allPasses = widget.player.passes ?? _generateMockPasses();

    var filtered = allPasses;

    // Filter by accuracy
    if (_selectedAccuracy == 'Accurato') {
      filtered = filtered.where((p) => p.isAccurate).toList();
    } else if (_selectedAccuracy == 'Non accurato') {
      filtered = filtered.where((p) => !p.isAccurate).toList();
    }

    return filtered;
  }

  List<PassData> _generateMockPasses() {
    final random = math.Random(42);
    return List.generate(35, (index) {
      final fromX = 0.2 + random.nextDouble() * 0.6;
      final fromY = 0.2 + random.nextDouble() * 0.6;
      final toX = (fromX + (random.nextDouble() - 0.5) * 0.4).clamp(0.1, 0.9);
      final toY = (fromY + (random.nextDouble() - 0.5) * 0.4).clamp(0.1, 0.9);
      final isAccurate = random.nextDouble() > 0.2;

      return PassData(
        from: Offset(fromX, fromY),
        to: Offset(toX, toY),
        isAccurate: isAccurate,
      );
    });
  }

  List<Offset> _generateMockHeatmapPositions() {
    final random = math.Random(42);
    return List.generate(180, (index) {
      final x = 0.25 + random.nextDouble() * 0.5;
      final y = 0.2 + random.nextDouble() * 0.6;
      return Offset(x, y);
    });
  }

  Widget _buildPerformanceSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.trending_up, color: widget.player.teamColor),
              const SizedBox(width: 8),
              const Text(
                'Performance Comparata',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildPerformanceBar(
              tr(context, 'Precisione passaggi'), widget.player.passingAccuracy, '%'),
          SizedBox(height: 16),
          _buildPerformanceBar(tr(context, 'Tiri per goal'), widget.player.shotsPerGoal, ''),
          const SizedBox(height: 16),
          _buildPerformanceBar('Minuti per goal',
              widget.player.minutesPerGoal.toStringAsFixed(1), ''),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String label, dynamic value, String unit) {
    double percentage;
    if (value is double) {
      percentage = (value / 100).clamp(0.0, 1.0);
    } else if (value is String) {
      percentage = (double.tryParse(value) ?? 50) / 100;
    } else {
      percentage = 0.5;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.player.teamColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(widget.player.teamColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFormSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.bar_chart, color: widget.player.teamColor),
              SizedBox(width: 8),
              Text(
                tr(context, 'Forma Recente'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.player.recentForm
                .map((form) => _buildFormIndicator(form))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Valutazioni ultime 10 partite',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: _buildRatingsChart(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Miglior partita: ${widget.player.bestMatch}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormIndicator(String result) {
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
      width: 30,
      height: 30,
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsChart() {
    final ratings = widget.player.recentRatings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            (constraints.maxWidth - (ratings.length - 1) * 8) / ratings.length;
        final safeBarWidth = barWidth.clamp(20.0, 40.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: ratings.asMap().entries.map((entry) {
            final rating = entry.value;
            final normalizedHeight = ((rating - 5) / 5).clamp(0.0, 1.0);
            final barHeight = 20 + (normalizedHeight * 60);

            Color barColor;
            if (rating >= 7.5) {
              barColor = Colors.green;
            } else if (rating >= 6.5) {
              barColor = widget.player.teamColor;
            } else if (rating >= 6.0) {
              barColor = Colors.orange;
            } else {
              barColor = Colors.red;
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: safeBarWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        barColor,
                        barColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSkillsRadarSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.stars, color: widget.player.teamColor),
              SizedBox(width: 8),
              Text(
                tr(context, 'Abilità'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 250,
              width: 250,
              child: CustomPaint(
                painter: RadarChartPainter(
                  skills: widget.player.skills,
                  color: widget.player.teamColor,
                ),
                size: const Size(250, 250),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(
            'Attacco',
            [
              _buildStatRow('Gol', widget.player.goals.toString()),
              _buildStatRow('Assist', widget.player.assists.toString()),
              _buildStatRow(tr(context, 'Tiri'), widget.player.shots.toString()),
              _buildStatRow(
                  tr(context, 'Tiri in porta'), widget.player.shotsOnTarget.toString()),
              _buildStatRow('Dribbling', widget.player.dribbles.toString()),
              _buildStatRow(tr(context, 'Gol decisivi'),
                  widget.player.decisiveGoals?.toString() ?? '0'),
            ],
            isDark,
          ),
          SizedBox(height: 16),
          _buildStatsCard(
            tr(context, 'Difesa'),
            [
              _buildStatRow(tr(context, 'Contrasti'), widget.player.tackles.toString()),
              _buildStatRow(
                  tr(context, 'Intercetti'), widget.player.interceptions.toString()),
              _buildStatRow(tr(context, 'Duelli vinti'), widget.player.duelsWon.toString()),
              if (widget.player.saves > 0)
                _buildStatRow('Parate', widget.player.saves.toString()),
            ],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildStatsCard(
            'Disciplina',
            [
              _buildStatRow(
                  tr(context, 'Cartellini gialli'), widget.player.yellowCards.toString()),
              _buildStatRow(
                  tr(context, 'Cartellini rossi'), widget.player.redCards.toString()),
              _buildStatRow(tr(context, 'Falli commessi'), widget.player.fouls.toString()),
            ],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          ...stats,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.player.teamColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            tr(context, 'Informazioni Personali'),
            [
              _buildInfoRow('Data di nascita', widget.player.birthDate),
              _buildInfoRow('Età', '${widget.player.age} anni'),
              _buildInfoRow('Nazionalità', widget.player.nationality),
              _buildInfoRow('Altezza', '${widget.player.height} cm'),
              _buildInfoRow('Peso', '${widget.player.weight} kg'),
              _buildInfoRow(tr(context, 'Piede preferito'), tr(context, widget.player.preferredFoot)),
            ],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildCareerHistoryCard(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> info, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          ...info,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerHistoryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'Carriera'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.player.careerHistory.map((career) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.player.teamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          career['team'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (career['years'] as String).replaceAll('Presente', tr(context, 'Presente')),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${career['matches']} ${tr(context, 'partite')}, ${career['goals']} ${tr(context, 'gol')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showPlayerComparisonDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestedPlayers = _generateComparablePlayers();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlayerComparisonDialog(
        currentPlayer: widget.player,
        suggestedPlayers: suggestedPlayers,
        isDark: isDark,
        onPlayerSelected: (player) {
          Navigator.pop(context);
          _navigateToComparison(context, player);
        },
      ),
    );
  }

  void _navigateToComparison(BuildContext context, PlayerDetail player2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailComparisonScreen(
          player1: widget.player,
          player2: player2,
        ),
      ),
    );
  }

  List<PlayerDetail> _generateComparablePlayers() {
    final random = math.Random();
    final positions = ['Attaccante', 'Centrocampista', 'Difensore', 'Portiere'];
    final teams = [
      {'name': 'Lazio', 'color': const Color(0xFF87CEEB)},
      {'name': 'Roma', 'color': const Color(0xFFE53935)},
      {'name': 'Inter', 'color': const Color(0xFF0033FF)},
      {'name': 'Milan', 'color': const Color(0xFFE53935)},
      {'name': 'Juventus', 'color': const Color(0xFF000000)},
      {'name': 'Napoli', 'color': const Color(0xFF0066CC)},
      {'name': 'Atalanta', 'color': const Color(0xFF0066FF)},
      {'name': 'Fiorentina', 'color': const Color(0xFF6B3FA0)},
    ];

    final names = [
      'Paulo Dybala',
      'Lautaro Martinez',
      'Victor Osimhen',
      'Rafael Leão',
      'Ciro Immobile',
      'Dusan Vlahovic',
      'Romelu Lukaku',
      'Marcus Thuram',
      'Ademola Lookman',
      'Mattia Zaccagni',
      'Federico Chiesa',
      'Nicolò Zaniolo',
    ];

    return List.generate(10, (index) {
      final team = teams[random.nextInt(teams.length)];
      final name = names[index % names.length];

      return PlayerDetail(
        number: random.nextInt(90) + 1,
        name: name,
        position: positions[random.nextInt(positions.length)],
        photo: null,
        teamName: team['name'] as String,
        teamColor: team['color'] as Color,
        matches: random.nextInt(30) + 10,
        goals: random.nextInt(20),
        assists: random.nextInt(15),
        minutes: random.nextInt(2000) + 500,
        shots: random.nextInt(50) + 10,
        shotsOnTarget: random.nextInt(30) + 5,
        dribbles: random.nextInt(40) + 5,
        tackles: random.nextInt(50) + 10,
        interceptions: random.nextInt(40) + 5,
        saves: 0,
        duelsWon: random.nextInt(100) + 20,
        yellowCards: random.nextInt(8),
        redCards: random.nextInt(2),
        fouls: random.nextInt(30) + 5,
        recentRatings:
            List.generate(10, (_) => 6.0 + random.nextDouble() * 2.5),
        recentForm: List.generate(5, (_) => ['W', 'D', 'L'][random.nextInt(3)]),
        bestMatch:
            'Serie A - ${(random.nextDouble() * 2 + 7.5).toStringAsFixed(1)}',
        averageRating: 6.5 + random.nextDouble() * 1.5,
        decisiveGoals: random.nextInt(5),
        skills: {
          tr(context, 'Velocità'): 50.0 + random.nextDouble() * 40,
          'Tiro': 50.0 + random.nextDouble() * 40,
          tr(context, 'Passaggio'): 50.0 + random.nextDouble() * 40,
          'Dribbling': 50.0 + random.nextDouble() * 40,
          tr(context, 'Difesa'): 30.0 + random.nextDouble() * 50,
          'Fisico': 50.0 + random.nextDouble() * 40,
        },
        passingAccuracy: 70 + random.nextDouble() * 20,
        shotsPerGoal: 3 + random.nextDouble() * 5,
        minutesPerGoal: 100 + random.nextDouble() * 200,
        birthDate:
            '${random.nextInt(28) + 1}/${random.nextInt(12) + 1}/${1990 + random.nextInt(10)}',
        age: 22 + random.nextInt(12),
        nationality: [
          'Italia',
          'Argentina',
          'Nigeria',
          'Francia',
          'Brasile'
        ][random.nextInt(5)],
        height: 170 + random.nextInt(20),
        weight: 65 + random.nextInt(20),
        preferredFoot: random.nextBool() ? 'Destro' : 'Sinistro',
        careerHistory: [],
      );
    });
  }
}

// Custom Painters
