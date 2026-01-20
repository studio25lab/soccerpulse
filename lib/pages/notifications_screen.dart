// lib/pages/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../generated/l10n.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final HapticService _haptic = HapticService();

  // Mock notifications data
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'goal',
      'title': 'GOL! Inter 1-0 Milan',
      'message': 'Lautaro Martinez ha segnato al 23\'',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'read': false,
      'icon': Icons.sports_soccer,
      'color': Colors.green,
    },
    {
      'id': 2,
      'type': 'match_start',
      'title': 'Partita iniziata',
      'message': 'Juventus vs Roma è iniziata',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
      'icon': Icons.play_arrow,
      'color': Colors.blue,
    },
    {
      'id': 3,
      'type': 'match_reminder',
      'title': 'Promemoria partita',
      'message': 'Napoli vs Lazio inizia tra 30 minuti',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
      'icon': Icons.alarm,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifiche'),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n['read']))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Segna tutte come lette',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(
                    notification, index, isDark, theme);
              },
            ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    final bool isRead = notification['read'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: InkWell(
          onTap: () {
            _haptic.lightImpact();
            _markAsRead(notification['id']);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'],
                    color: notification['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification['time']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: index * 100))
          .slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 100,
            color: Colors.grey[400],
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Nessuna notifica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le notifiche appariranno qui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuti fa';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ore fa';
    } else {
      return DateFormat('dd/MM HH:mm').format(time);
    }
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
  }

  void _markAllAsRead() {
    _haptic.mediumImpact();
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }
}
