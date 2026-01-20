import 'package:flutter/material.dart';

class AnimatedPageTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType type;

  AnimatedPageTransition({
    required this.page,
    this.type = TransitionType.slideFromRight,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(type, animation, child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );

  static Widget _buildTransition(
    TransitionType type,
    Animation<double> animation,
    Widget child,
  ) {
    switch (type) {
      case TransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case TransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case TransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.fadeScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
    }
  }
}

enum TransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  fade,
  scale,
  rotation,
  fadeScale,
}

extension NavigationExtension on BuildContext {
  Future<T?> pushWithTransition<T>(
    Widget page, {
    TransitionType type = TransitionType.slideFromRight,
  }) {
    return Navigator.push<T>(
      this,
      AnimatedPageTransition<T>(page: page, type: type),
    );
  }

  Future<T?> replaceWithTransition<T>(
    Widget page, {
    TransitionType type = TransitionType.fade,
  }) {
    return Navigator.pushReplacement<T, void>(
      this,
      AnimatedPageTransition<T>(page: page, type: type),
    );
  }
}
