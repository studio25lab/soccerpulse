import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final TextStyle? textStyle;
  final VoidCallback? onComplete;

  const CountdownTimer({
    Key? key,
    required this.targetTime,
    this.textStyle,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() {
        _timeRemaining = widget.targetTime.difference(now);
      });
    } else {
      _timer?.cancel();
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
      if (mounted) {
        setState(() {
          _timeRemaining = Duration.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return 'Iniziato';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_timeRemaining),
      style: widget.textStyle ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
    );
  }
}
