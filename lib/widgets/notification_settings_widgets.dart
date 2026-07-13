// lib/widgets/notification_settings_widgets.dart
//
// Widget condivisi per i bottom sheet delle impostazioni notifiche
// (squadra e partita). Stile unificato:
//   - chip orizzontali per i preset
//   - master switch come riga in cima
//   - righe con quadratino colorato + icona + titolo + sottotitolo
//
// Tutti i widget sono puramente di presentazione: ricevono dati e
// callback, non conoscono i servizi.

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart'; // [FIX-4TR]

/// Dato di un preset mostrato come chip.
class NotifPresetChipData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const NotifPresetChipData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Guscio del bottom sheet: handle bar in alto + colonna dei figli.
/// Gestisce altezza, colori e angoli arrotondati.
class NotifSheetContainer extends StatelessWidget {
  final List<Widget> children;
  final double heightFactor;

  const NotifSheetContainer({
    super.key,
    required this.children,
    this.heightFactor = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final h = MediaQuery.of(context).size.height * heightFactor;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Header del bottom sheet: icona, titolo, sottotitolo e, a destra, il
/// pulsante "Attiva tutto" / "Disattiva" (opzionale) e la X di chiusura.
class NotifSheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool allOn;
  final VoidCallback? onToggleAll;
  final VoidCallback onClose;

  const NotifSheetHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.allOn = false,
    this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_active,
                color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: tx,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: lb),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onToggleAll != null)
            GestureDetector(
              onTap: onToggleAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: allOn
                      ? theme.primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: allOn
                        ? theme.primaryColor
                        : (isDark ? Colors.white12 : Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  // [FIX-4TR] ora passano dal sistema di traduzione
                  allOn
                      ? tr(context, 'Disattiva')
                      : tr(context, 'Attiva tutto'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: allOn ? Colors.white : lb,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Fila orizzontale di chip per i preset rapidi.
class NotifPresetChips extends StatelessWidget {
  final List<NotifPresetChipData> presets;

  const NotifPresetChips({super.key, required this.presets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = presets[i];
          return InkWell(
            onTap: p.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Riga master switch: abilitazione generale del bottom sheet.
class NotifMasterSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotifMasterSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value
            ? theme.primaryColor.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? Colors.white10 : Colors.grey[100]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? theme.primaryColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white12 : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? theme.primaryColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              value
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: value ? theme.primaryColor : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: tx,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Intestazione di una sezione (icona piccola + titolo in maiuscoletto).
class NotifSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const NotifSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? Colors.white38 : Colors.grey[500];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga ricca con quadratino colorato + icona + titolo + sottotitolo +
/// switch animato. [enabled] false la rende grigia e non interattiva
/// (usata quando il master switch e spento).
class NotifSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const NotifSwitchRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOn = value && enabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => onChanged(!value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isOn
                  ? color.withValues(alpha: isDark ? 0.12 : 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOn
                    ? color.withValues(alpha: isDark ? 0.3 : 0.2)
                    : (isDark ? Colors.white10 : Colors.grey[200]!),
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isOn ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isOn
                        ? color
                        : (isDark ? Colors.white30 : Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOn
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                  ? Colors.white54
                                  : Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white30 : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                _AnimatedToggle(isOn: isOn, color: color, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo switch custom animato usato da NotifSwitchRow.
class _AnimatedToggle extends StatelessWidget {
  final bool isOn;
  final Color color;
  final bool isDark;

  const _AnimatedToggle({
    required this.isOn,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: isOn
            ? color
            : (isDark ? Colors.white12 : Colors.grey[300]),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
