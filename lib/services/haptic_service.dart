import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  bool _isEnabled = true;

  // Setter per abilitare/disabilitare la vibrazione
  set isEnabled(bool value) => _isEnabled = value;
  bool get isEnabled => _isEnabled;

  // ============== METODI PRINCIPALI ==============

  // Light impact - feedback leggero
  Future<void> lightImpact() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await HapticFeedback.lightImpact();
        // Fallback per dispositivi che supportano solo vibrazione custom
        await Vibration.vibrate(duration: 10);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Medium impact - feedback medio
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await HapticFeedback.mediumImpact();
        // Fallback per dispositivi che supportano solo vibrazione custom
        await Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Heavy impact - feedback forte
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await HapticFeedback.heavyImpact();
        // Fallback per dispositivi che supportano solo vibrazione custom
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Selection impact - feedback per selezione
  Future<void> selectionImpact() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await HapticFeedback.selectionClick();
        // Fallback per dispositivi che supportano solo vibrazione custom
        await Vibration.vibrate(duration: 5);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // ============== ALIAS BREVI (per compatibilità) ==============

  // Alias brevi per i metodi principali
  Future<void> light() => lightImpact();
  Future<void> medium() => mediumImpact();
  Future<void> heavy() => heavyImpact();
  Future<void> selection() => selectionImpact();

  // ============== METODI SPECIALI ==============

  // Success notification - pattern di successo
  Future<void> success() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 50, 50, 50]);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Warning notification - pattern di avviso
  Future<void> warning() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 100, 100, 100]);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Error notification - pattern di errore
  Future<void> error() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Goal scored - vibrazione speciale per i gol
  Future<void> goalScored() async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Pattern celebrativo per i gol
        await Vibration.vibrate(
          pattern: [0, 100, 50, 100, 50, 200, 100, 500],
          intensities: [0, 128, 0, 255, 0, 128, 0, 255],
        );
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Custom vibration
  Future<void> vibrate({int duration = 50}) async {
    if (!_isEnabled) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  // Check if device supports vibration
  Future<bool> hasVibrator() async {
    try {
      return await Vibration.hasVibrator() ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if device supports amplitude control
  Future<bool> hasAmplitudeControl() async {
    try {
      return await Vibration.hasAmplitudeControl() ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if device supports custom vibrations
  Future<bool> hasCustomVibrationsSupport() async {
    try {
      return await Vibration.hasCustomVibrationsSupport() ?? false;
    } catch (e) {
      return false;
    }
  }

  // Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      print('Cancel vibration error: $e');
    }
  }
}
