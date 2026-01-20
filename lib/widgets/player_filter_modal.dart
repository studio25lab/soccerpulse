// lib/widgets/player_filter_modal.dart

import 'package:flutter/material.dart';

class PlayerFilterModal extends StatefulWidget {
  final double minRating;
  final int minMinutes;
  final String? positionFilter;
  final String? nationalityFilter;
  final int? minAge;
  final int? maxAge;
  final List<String> selectedBadges;
  final Function(Map<String, dynamic>) onApply;

  const PlayerFilterModal({
    Key? key,
    required this.minRating,
    required this.minMinutes,
    this.positionFilter,
    this.nationalityFilter,
    this.minAge,
    this.maxAge,
    required this.selectedBadges,
    required this.onApply,
  }) : super(key: key);

  @override
  State<PlayerFilterModal> createState() => _PlayerFilterModalState();
}

class _PlayerFilterModalState extends State<PlayerFilterModal> {
  late double _minRating;
  late int _minMinutes;
  String? _positionFilter;
  String? _nationalityFilter;
  int? _minAge;
  int? _maxAge;
  late List<String> _selectedBadges;

  @override
  void initState() {
    super.initState();
    _minRating = widget.minRating;
    _minMinutes = widget.minMinutes;
    _positionFilter = widget.positionFilter;
    _nationalityFilter = widget.nationalityFilter;
    _minAge = widget.minAge;
    _maxAge = widget.maxAge;
    _selectedBadges = List.from(widget.selectedBadges);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingFilter(theme, isDark),
                  const SizedBox(height: 24),
                  _buildMinutesFilter(theme, isDark),
                  const SizedBox(height: 24),
                  _buildPositionFilter(theme, isDark),
                  const SizedBox(height: 24),
                  _buildAgeFilter(theme, isDark),
                  const SizedBox(height: 24),
                  _buildBadgeFilter(theme, isDark),
                ],
              ),
            ),
          ),
          _buildFooter(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filtri Avanzati',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _minRating = 0;
                    _minMinutes = 0;
                    _positionFilter = null;
                    _nationalityFilter = null;
                    _minAge = null;
                    _maxAge = null;
                    _selectedBadges.clear();
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Rating Minimo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _minRating == 0 ? 'Tutti' : _minRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
            thumbColor: theme.primaryColor,
            overlayColor: theme.primaryColor.withOpacity(0.2),
            valueIndicatorColor: theme.primaryColor,
          ),
          child: Slider(
            value: _minRating,
            min: 0,
            max: 10,
            divisions: 20,
            label: _minRating == 0 ? 'Tutti' : _minRating.toStringAsFixed(1),
            onChanged: (value) => setState(() => _minRating = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('10.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinutesFilter(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Minuti Giocati',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _minMinutes == 0 ? 'Tutti' : '${_minMinutes}\'',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0, 100, 300, 500, 900].map((minutes) {
            final isSelected = _minMinutes == minutes;
            return ChoiceChip(
              label: Text(minutes == 0 ? 'Tutti' : '${minutes}\''),
              selected: isSelected,
              onSelected: (selected) => setState(() => _minMinutes = minutes),
              selectedColor: theme.primaryColor.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.primaryColor
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPositionFilter(ThemeData theme, bool isDark) {
    final positions = ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Posizione',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tutte'),
              selected: _positionFilter == null,
              onSelected: (selected) => setState(() => _positionFilter = null),
              selectedColor: theme.primaryColor.withOpacity(0.3),
              labelStyle: TextStyle(
                color: _positionFilter == null
                    ? theme.primaryColor
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: _positionFilter == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            ...positions.map((position) {
              final isSelected = _positionFilter == position;
              return ChoiceChip(
                label: Text(position),
                selected: isSelected,
                onSelected: (selected) =>
                    setState(() => _positionFilter = position),
                selectedColor: theme.primaryColor.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? Colors.white : Colors.black),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeFilter(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cake, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Età',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Min', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int?>(
                      value: _minAge,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Nessun limite'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Nessun limite')),
                        ...List.generate(20, (i) => (i + 1) * 1 + 16)
                            .map((age) {
                          return DropdownMenuItem(
                              value: age, child: Text('$age anni'));
                        }),
                      ],
                      onChanged: (value) => setState(() => _minAge = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Max', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int?>(
                      value: _maxAge,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Nessun limite'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Nessun limite')),
                        ...List.generate(20, (i) => (i + 1) * 1 + 16)
                            .map((age) {
                          return DropdownMenuItem(
                              value: age, child: Text('$age anni'));
                        }),
                      ],
                      onChanged: (value) => setState(() => _maxAge = value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAgePreset('Giovani', 16, 23, theme),
            _buildAgePreset('Prime', 24, 29, theme),
            _buildAgePreset('Esperti', 30, 40, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildAgePreset(String label, int min, int max, ThemeData theme) {
    final isSelected = _minAge == min && _maxAge == max;
    return ActionChip(
      label: Text('$label ($min-$max)'),
      onPressed: () => setState(() {
        _minAge = min;
        _maxAge = max;
      }),
      backgroundColor: isSelected ? theme.primaryColor.withOpacity(0.3) : null,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBadgeFilter(ThemeData theme, bool isDark) {
    final badges = {
      '100_appearances': {
        'icon': Icons.emoji_events,
        'label': '100 Presenze',
        'color': const Color(0xFFFFD700)
      },
      '10_goals': {
        'icon': Icons.sports_soccer,
        'label': '10 Goal',
        'color': const Color(0xFF00C853)
      },
      '5_assists': {
        'icon': Icons.assistant,
        'label': '5 Assist',
        'color': const Color(0xFF2196F3)
      },
      'motm': {
        'icon': Icons.star,
        'label': 'MOTM',
        'color': const Color(0xFFFF9800)
      },
      'clean_sheet': {
        'icon': Icons.block,
        'label': 'Porta Inviolata',
        'color': const Color(0xFF9C27B0)
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.military_tech, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Badge & Milestone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: badges.entries.map((entry) {
            final isSelected = _selectedBadges.contains(entry.key);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedBadges.remove(entry.key);
                } else {
                  _selectedBadges.add(entry.key);
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            entry.value['color'] as Color,
                            (entry.value['color'] as Color).withOpacity(0.7),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (entry.value['color'] as Color)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : (entry.value['color'] as Color),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.value['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Annulla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply({
                  'minRating': _minRating,
                  'minMinutes': _minMinutes,
                  'position': _positionFilter,
                  'nationality': _nationalityFilter,
                  'minAge': _minAge,
                  'maxAge': _maxAge,
                  'badges': _selectedBadges,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Applica Filtri',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
