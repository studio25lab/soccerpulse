import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final LoadingStyle style;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.style = LoadingStyle.circular,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case LoadingStyle.circular:
        return _buildCircularLoading(context);
      case LoadingStyle.soccer:
        return _buildSoccerLoading(context);
      case LoadingStyle.pulse:
        return _buildPulseLoading(context);
      case LoadingStyle.dots:
        return _buildDotsLoading(context);
    }
  }

  Widget _buildCircularLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoccerLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: const Center(
              child: Text('⚽', style: TextStyle(fontSize: 40)),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms)
              .then()
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 500.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 500.ms,
              ),
          if (message != null) ...[
            const SizedBox(height: 32),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 1000.ms,
                )
                .then()
                .fadeOut(duration: 1000.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildPulseLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: 1000.ms,
                  )
                  .fadeOut(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ).animate(onPlay: (controller) => controller.repeat()).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 1000.ms,
                  ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 32),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotsLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                      delay: Duration(milliseconds: index * 200),
                    )
                    .moveY(
                      begin: 0,
                      end: -20,
                      duration: 600.ms,
                    )
                    .then()
                    .moveY(
                      begin: -20,
                      end: 0,
                      duration: 600.ms,
                    ),
              );
            }),
          ),
          if (message != null) ...[
            const SizedBox(height: 32),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

enum LoadingStyle {
  circular,
  soccer,
  pulse,
  dots,
}

// Loading overlay che copre tutto lo schermo
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final LoadingStyle style;

  const LoadingOverlay({
    super.key,
    this.message,
    this.style = LoadingStyle.soccer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: LoadingStateWidget(
        message: message,
        style: style,
      ),
    );
  }

  static void show(
    BuildContext context, {
    String? message,
    LoadingStyle style = LoadingStyle.soccer,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingOverlay(
        message: message,
        style: style,
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
