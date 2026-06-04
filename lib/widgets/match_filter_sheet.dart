import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../generated/l10n.dart';

enum MatchFilterType { all, live, scheduled, finished }

class MatchFilterSheet extends StatefulWidget {
  final MatchFilterType currentFilter;
  final Function(MatchFilterType) onFilterChanged;

  const MatchFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<MatchFilterSheet> createState() => _MatchFilterSheetState();
}

class _MatchFilterSheetState extends State<MatchFilterSheet> {
  late MatchFilterType _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'Filtri'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            s.status,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterOption(
            MatchFilterType.all,
            tr(context, 'Tutte'),
            Icons.grid_view,
            Colors.blue,
          ),
          _buildFilterOption(
            MatchFilterType.live,
            tr(context, 'Solo in corso'),
            Icons.circle,
            Colors.red,
          ),
          _buildFilterOption(
            MatchFilterType.scheduled,
            tr(context, 'Solo programmate'),
            Icons.schedule,
            Colors.orange,
          ),
          _buildFilterOption(
            MatchFilterType.finished,
            tr(context, 'Solo terminate'),
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedFilter = MatchFilterType.all);
                  },
                  child: Text(tr(context, 'Reimposta filtri')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFilterChanged(_selectedFilter);
                    Navigator.pop(context);
                  },
                  child: Text(tr(context, 'Applica filtri')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    MatchFilterType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFilter == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
