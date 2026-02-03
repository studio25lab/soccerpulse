import 'package:flutter/material.dart';
import 'dart:math' as math;

// ========================================
// MODELLO DATI TIRO
// ========================================
class ShotData {
  final String playerName;
  final String playerPhoto;
  final int minute;
  final double startX;
  final double startY;
  final double? goalX;
  final double? goalY;
  final String type;
  final double xG;
  final double? xGOT;
  final String? situation;
  final String? shotType;
  final String? goalZone;

  ShotData({
    required this.playerName,
    required this.playerPhoto,
    required this.minute,
    required this.startX,
    required this.startY,
    this.goalX,
    this.goalY,
    required this.type,
    required this.xG,
    this.xGOT,
    this.situation,
    this.shotType,
    this.goalZone,
  });

  Color get color {
    switch (type) {
      case 'goal':
        return const Color(0xFFE53935); // Rosso per in porta
      case 'on_target':
        return const Color(0xFFE53935); // Rosso per in porta
      case 'off_target':
        return const Color(0xFF212121); // Nero (solo bordo)
      case 'blocked':
        return const Color(0xFF757575); // Grigio per stanghetta
      default:
        return const Color(0xFFE53935);
    }
  }

  String get esito {
    switch (type) {
      case 'goal':
        return 'Goal';
      case 'on_target':
        return 'Risultato salvato';
      case 'off_target':
        return 'Mancato';
      case 'blocked':
        return 'Respinto';
      default:
        return 'Tiro';
    }
  }
}

// ========================================
// WIDGET PRINCIPALE
// ========================================
class InteractiveShotMapWidget extends StatefulWidget {
  final List<ShotData> shots;
  final Color teamColor;
  final bool isDark;

  const InteractiveShotMapWidget({
    Key? key,
    required this.shots,
    required this.teamColor,
    required this.isDark,
  }) : super(key: key);

  @override
  State<InteractiveShotMapWidget> createState() =>
      _InteractiveShotMapWidgetState();
}

class _InteractiveShotMapWidgetState extends State<InteractiveShotMapWidget> {
  int selectedShotIndex = 0;

  void _selectShot(int index) {
    setState(() {
      selectedShotIndex = index;
    });
  }

  void _previousShot() {
    if (selectedShotIndex > 0) {
      _selectShot(selectedShotIndex - 1);
    }
  }

  void _nextShot() {
    if (selectedShotIndex < widget.shots.length - 1) {
      _selectShot(selectedShotIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shots.isEmpty) {
      return _buildEmptyState();
    }

    final selectedShot = widget.shots[selectedShotIndex];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildGoalSection(selectedShot),

              // ✅ SPAZIO NEUTRO tra porta e campo
              const SizedBox(height: 16),

              _buildFieldSection(selectedShot),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPlayerInfoCard(selectedShot),
      ],
    );
  }

  Widget _buildGoalSection(ShotData selectedShot) {
    return Container(
      height: 165,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final goalWidth = width * 0.55;
          final goalLeft = (width - goalWidth) / 2;
          final goalHeight = 70.0;
          final goalTop = 15.0;

          // ✅ CENTRO PORTA ESATTO (stesso calcolo della linea!)
          final goalCenterX = width / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, 165),
                painter: GoalPainter(
                  goalLeft: goalLeft,
                  goalWidth: goalWidth,
                  goalHeight: goalHeight,
                  goalTop: goalTop,
                  totalWidth: width,
                ),
              ),

              // ✅ IN PORTA - Coordinamento PERFETTO con startX
              if (selectedShot.type == 'goal' ||
                  selectedShot.type == 'on_target')
                Positioned(
                  // ✅ USA startX per orizzontale (stessa direzione del tiro!)
                  left: goalLeft + (selectedShot.startX * goalWidth) - 18,
                  // Usa goalY se presente, altrimenti centro porta
                  top: selectedShot.goalY != null
                      ? goalTop + (selectedShot.goalY! * goalHeight) - 18
                      : goalTop + (goalHeight / 2) - 18,
                  child:
                      _buildImpactPoint(selectedShot.color, selectedShot.type),
                ),

              // ✅ FUORI - Coordinamento PERFETTO basato su startX
              if (selectedShot.type == 'off_target')
                Builder(
                  builder: (context) {
                    // ✅ Calcola posizione ESATTA fuori porta basandosi su startX
                    // Estende la posizione oltre i limiti della porta

                    double outsideX;
                    double outsideY;

                    // Calcola dove sarebbe nella porta
                    final targetInGoalX =
                        goalLeft + (selectedShot.startX * goalWidth);

                    if (selectedShot.startX < 0.5) {
                      // Tiro da SINISTRA o CENTRO-SINISTRA
                      if (selectedShot.startX < 0.25) {
                        // Molto a sinistra → fuori a sinistra
                        outsideX = targetInGoalX - 80;
                        outsideY = goalTop + 25;
                      } else if (selectedShot.startX < 0.4) {
                        // Sinistra moderato → fuori angolo sinistro alto
                        outsideX = targetInGoalX - 50;
                        outsideY = goalTop - 20;
                      } else {
                        // Centro-sinistra → sopra porta sinistra
                        outsideX = targetInGoalX;
                        outsideY = goalTop - 40;
                      }
                    } else if (selectedShot.startX > 0.5) {
                      // Tiro da DESTRA o CENTRO-DESTRA
                      if (selectedShot.startX > 0.75) {
                        // Molto a destra → fuori a destra
                        outsideX = targetInGoalX + 60;
                        outsideY = goalTop + 25;
                      } else if (selectedShot.startX > 0.6) {
                        // Destra moderato → fuori angolo destro alto
                        outsideX = targetInGoalX + 40;
                        outsideY = goalTop - 20;
                      } else {
                        // Centro-destra → sopra porta destra
                        outsideX = targetInGoalX;
                        outsideY = goalTop - 40;
                      }
                    } else {
                      // Tiro ESATTAMENTE centrale → sopra porta centro
                      outsideX = goalLeft + goalWidth / 2 - 18;
                      outsideY = goalTop - 45;
                    }

                    return Positioned(
                      left: outsideX,
                      top: outsideY,
                      child: _buildImpactPoint(
                          selectedShot.color, selectedShot.type),
                    );
                  },
                ),

              // ✅ BLOCCATO - Usa startX per coordinamento perfetto
              if (selectedShot.type == 'blocked')
                Positioned(
                  // ✅ USA startX per orizzontale (coordinato con tiro!)
                  left: goalLeft + (selectedShot.startX * goalWidth) - 18,
                  // Usa goalY se presente, altrimenti centro porta
                  top: selectedShot.goalY != null
                      ? goalTop + (selectedShot.goalY! * goalHeight) - 18
                      : goalTop + (goalHeight / 2) - 18,
                  child:
                      _buildImpactPoint(selectedShot.color, selectedShot.type),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImpactPoint(Color color, String shotType) {
    return Container(
      width: 36, // ✅ Ingrandito da 28 a 36
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 3, // ✅ Bordo più spesso: da 2.5 a 3
        ),
      ),
      child: shotType == 'goal' || shotType == 'on_target'
          ? Center(
              child: Container(
                width: 12, // ✅ Ingrandito da 10 a 12
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : (shotType == 'blocked'
              ? Center(
                  child: Container(
                    width: 16, // ✅ Ingrandito da 12 a 16
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF757575),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )
              : null),
    );
  }

  Widget _buildFieldSection(ShotData selectedShot) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2D4A2D), width: 3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            final fieldHeight = fieldWidth * 0.75;

            return SizedBox(
              height: fieldHeight,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(fieldWidth, fieldHeight),
                    painter: FieldPainter(),
                  ),
                  CustomPaint(
                    size: Size(fieldWidth, fieldHeight),
                    painter: DashedLinePainter(
                      shotX: selectedShot.startX,
                      shotY: selectedShot.startY,
                      shotType: selectedShot.type, // ✅ Passo il tipo
                    ),
                  ),
                  ...widget.shots.asMap().entries.map((entry) {
                    return _buildShotMarker(
                      entry.value,
                      entry.key,
                      fieldWidth,
                      fieldHeight,
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShotMarker(
      ShotData shot, int index, double fieldWidth, double fieldHeight) {
    final isSelected = index == selectedShotIndex;
    final size = isSelected ? 48.0 : 32.0; // ✅ Ingrandito! Era 40/26
    final innerSize = isSelected ? 32.0 : 22.0; // ✅ Ingrandito! Era 26/18

    final x = shot.startX * fieldWidth;
    final y = shot.startY * fieldHeight;

    return Positioned(
      left: x - (size / 2),
      top: y - (size / 2),
      child: GestureDetector(
        onTap: () => _selectShot(index),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cerchio esterno (solo selezionato)
              if (isSelected)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),

              // ✅ CERCHIO ESTERNO - SEMPRE NERO!
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Sempre vuoto
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : const Color(
                            0xFF212121), // Nero o bianco se selezionato
                    width: 3, // ✅ Spessore aumentato da 2.5 a 3
                  ),
                ),
              ),

              // ✅ PALLINO ROSSO INTERNO - Solo per IN PORTA
              if (shot.type == 'goal' || shot.type == 'on_target')
                Container(
                  width: isSelected ? 12 : 9, // ✅ Ingrandito da 10/7 a 12/9
                  height: isSelected ? 12 : 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935), // ROSSO!
                    shape: BoxShape.circle,
                  ),
                ),

              // ✅ STANGHETTA GRIGIA - Per BLOCCATI
              if (shot.type == 'blocked')
                Container(
                  width: isSelected ? 16 : 12, // ✅ Ingrandito da 12/9 a 16/12
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF757575), // GRIGIO!
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfoCard(ShotData shot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildNavArrow(
                  Icons.chevron_left, selectedShotIndex > 0, _previousShot),
              const SizedBox(width: 12),
              _buildPlayerAvatar(shot),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  shot.playerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                "${shot.minute}'",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              _buildNavArrow(
                Icons.chevron_right,
                selectedShotIndex < widget.shots.length - 1,
                _nextShot,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStat('xG', shot.xG.toStringAsFixed(2))),
              Expanded(
                child: _buildStat(
                  'xGOT',
                  shot.xGOT?.toStringAsFixed(2) ?? '-',
                ),
              ),
              Expanded(child: _buildStat('Esito', shot.esito)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildStat('Situazione', shot.situation ?? 'Gioco aperto'),
              ),
              Expanded(
                child: _buildStat(
                    'Tipo di tiro', shot.shotType ?? 'Tiro di destro'),
              ),
              Expanded(
                child: _buildStat('Zona gol', shot.goalZone ?? '-'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        color: enabled ? const Color(0xFF5B9BD5) : Colors.grey[700],
        size: 32,
      ),
    );
  }

  Widget _buildPlayerAvatar(ShotData shot) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: Border.all(color: Colors.grey[600]!, width: 2),
      ),
      child: shot.playerPhoto.isNotEmpty
          ? ClipOval(
              child: Image.network(
                shot.playerPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 28),
              ),
            )
          : const Icon(Icons.person, color: Colors.white, size: 28),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_soccer_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Nessun tiro disponibile',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ========================================
// ✅ PAINTER: PORTA - AREA PICCOLA 90%!
// ========================================
class GoalPainter extends CustomPainter {
  final double goalLeft;
  final double goalWidth;
  final double goalHeight;
  final double goalTop;
  final double totalWidth;

  GoalPainter({
    required this.goalLeft,
    required this.goalWidth,
    required this.goalHeight,
    required this.goalTop,
    required this.totalWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final goalRight = goalLeft + goalWidth;
    final goalBottom = goalTop + goalHeight;

    // Sfondo rete
    canvas.drawRect(
      Rect.fromLTRB(goalLeft, goalTop, goalRight, goalBottom),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // Griglia rete
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    for (int i = 0; i <= 14; i++) {
      final x = goalLeft + (i / 14) * goalWidth;
      canvas.drawLine(Offset(x, goalTop), Offset(x, goalBottom), netPaint);
    }

    for (int i = 0; i <= 6; i++) {
      final y = goalTop + (i / 6) * goalHeight;
      canvas.drawLine(Offset(goalLeft, y), Offset(goalRight, y), netPaint);
    }

    // Pali DRITTI
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(goalLeft, goalTop),
      Offset(goalLeft, goalBottom + 8),
      postPaint,
    );

    canvas.drawLine(
      Offset(goalRight, goalTop),
      Offset(goalRight, goalBottom + 8),
      postPaint,
    );

    canvas.drawLine(
      Offset(goalLeft, goalTop),
      Offset(goalRight, goalTop),
      postPaint,
    );

    // ✅ STRISCIA VERDE AREA PICCOLA (tutta la larghezza)
    canvas.drawRect(
      Rect.fromLTRB(0, goalBottom + 6, size.width, size.height),
      Paint()..color = const Color(0xFF3D5A3D),
    );

    // ✅ LINEA AREA PICCOLA - 90% LARGHEZZA TOTALE (MOLTO PIÙ GRANDE!)
    final areaWidth = totalWidth * 0.90; // 90% della larghezza totale!
    final areaLeft = (totalWidth - areaWidth) / 2;

    // ✅ La linea finisce PRIMA per lasciare più spazio verde sotto!
    canvas.drawRect(
      Rect.fromLTRB(areaLeft, goalBottom + 6, areaLeft + areaWidth,
          size.height - 35), // ✅ Da -2 a -35!
      Paint()
        ..color = const Color(0xFF2D4A2D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// PAINTER: CAMPO - PORTA PIÙ PICCOLA DELL'AREA
// ========================================
class FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Strisce VERTICALI
    final grassLight = const Color(0xFF4A7C4A);
    final grassDark = const Color(0xFF3D6B3D);

    final stripeCount = 8;
    final stripeWidth = size.width / stripeCount;

    for (int i = 0; i < stripeCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        Paint()..color = i % 2 == 0 ? grassLight : grassDark,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2D4A2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // PORTA PIÙ PICCOLA DELL'AREA PICCOLA
    final goalPostPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final smallWidth = size.width * 0.30;
    final goalWidth = size.width * 0.24;
    final goalLeft = (size.width - goalWidth) / 2;
    final goalRight = goalLeft + goalWidth;
    final goalHeight = size.height * 0.05;

    canvas.drawLine(
      Offset(goalLeft, 0),
      Offset(goalLeft, goalHeight),
      goalPostPaint,
    );

    canvas.drawLine(
      Offset(goalRight, 0),
      Offset(goalRight, goalHeight),
      goalPostPaint,
    );

    canvas.drawLine(
      Offset(goalLeft, 0),
      Offset(goalRight, 0),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Area rigore
    final penaltyWidth = size.width * 0.65;
    final penaltyHeight = size.height * 0.42;
    final penaltyLeft = (size.width - penaltyWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(penaltyLeft, 0, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // Area piccola
    final smallHeight = size.height * 0.16;
    final smallLeft = (size.width - smallWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(smallLeft, 0, smallWidth, smallHeight),
      linePaint,
    );

    // Dischetto
    canvas.drawCircle(
      Offset(size.width / 2, penaltyHeight * 0.30),
      3,
      Paint()..color = const Color(0xFF2D4A2D),
    );

    // ✅ Mezzaluna - CONNESSA perfettamente all'area rigore
    final arcRadius = size.width * 0.10;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, penaltyHeight, size.width, size.height));
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(
            size.width / 2, penaltyHeight), // ✅ Centro ESATTO sulla linea
        radius: arcRadius,
      ),
      0,
      math.pi,
      false,
      linePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// ✅ PAINTER: LINEA TRATTEGGIATA - COORDINAMENTO PERFETTO!
// ========================================
class DashedLinePainter extends CustomPainter {
  final double shotX;
  final double shotY;
  final String shotType;

  DashedLinePainter({
    required this.shotX,
    required this.shotY,
    required this.shotType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2;

    final startX = shotX * size.width;
    final startY = shotY * size.height;

    // ✅ COORDINAMENTO PERFETTO per TUTTI i tipi!
    final double endX;

    if (shotType == 'goal' || shotType == 'on_target') {
      // IN PORTA: linea va esattamente dove pallino porta sarà
      final goalWidth = size.width * 0.55;
      final goalLeft = (size.width - goalWidth) / 2;
      endX = goalLeft + (shotX * goalWidth);
    } else if (shotType == 'off_target') {
      // FUORI: linea va verso punto esterno (stessa logica pallino)
      final goalWidth = size.width * 0.55;
      final goalLeft = (size.width - goalWidth) / 2;
      final targetInGoalX = goalLeft + (shotX * goalWidth);

      // Calcola dove finirà il pallino fuori
      if (shotX < 0.5) {
        if (shotX < 0.25) {
          endX = targetInGoalX - 80;
        } else if (shotX < 0.4) {
          endX = targetInGoalX - 50;
        } else {
          endX = targetInGoalX;
        }
      } else if (shotX > 0.5) {
        if (shotX > 0.75) {
          endX = targetInGoalX + 60;
        } else if (shotX > 0.6) {
          endX = targetInGoalX + 40;
        } else {
          endX = targetInGoalX;
        }
      } else {
        endX = size.width / 2;
      }
    } else {
      // BLOCCATI: centro porta
      final goalWidth = size.width * 0.55;
      final goalLeft = (size.width - goalWidth) / 2;
      endX = goalLeft + (shotX * goalWidth);
    }

    final endY = 0.0;

    final dx = endX - startX;
    final dy = endY - startY;
    final distance = math.sqrt(dx * dx + dy * dy);

    const dashLength = 6.0;
    const gapLength = 4.0;
    var currentDistance = 0.0;

    // ✅ Per bloccati, calcola punto medio per interruzione
    final midDistance = shotType == 'blocked' ? distance / 2 : -1;
    final stopDistance = shotType == 'blocked' ? midDistance : distance;

    while (currentDistance < stopDistance) {
      final dashStart = currentDistance / distance;
      final dashEnd = math.min((currentDistance + dashLength) / distance, 1.0);

      // ✅ Salta il disegno vicino al punto medio per bloccati
      final isNearMid =
          shotType == 'blocked' && (currentDistance - midDistance).abs() < 10;

      if (!isNearMid) {
        canvas.drawLine(
          Offset(startX + dx * dashStart, startY + dy * dashStart),
          Offset(startX + dx * dashEnd, startY + dy * dashEnd),
          paint,
        );
      }

      currentDistance += dashLength + gapLength;
    }

    // ✅ Disegna lineetta orizzontale per bloccati (e STOP!)
    if (shotType == 'blocked') {
      final midX = startX + dx * 0.5;
      final midY = startY + dy * 0.5;

      final blockPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(midX - 8, midY),
        Offset(midX + 8, midY),
        blockPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
