import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int homeValue;
  final int awayValue;

  const StatBar({
    Key? key,
    required this.label,
    required this.homeValue,
    required this.awayValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? (homeValue / total) : 0.5;
    final awayPercentage = total > 0 ? (awayValue / total) : 0.5;

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$homeValue'),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: (homePercentage * 100).round(),
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (awayPercentage * 100).round(),
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text('$awayValue'),
            ],
          ),
        ],
      ),
    );
  }
}
