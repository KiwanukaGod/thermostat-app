import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

void main() {
  runApp(const ThermostatApp());
}

// ==========================================
// 1. APP ROOT
// ==========================================
class ThermostatApp extends StatelessWidget {
  const ThermostatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glassmorphism Thermostat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF18181E),
      ),
      home: const ThermostatPage(),
    );
  }
}

// ==========================================
// 2. MAIN PAGE & STATE
// ==========================================
class ThermostatPage extends StatefulWidget {
  const ThermostatPage({super.key});

  @override
  State<ThermostatPage> createState() => _ThermostatPageState();
}

class _ThermostatPageState extends State<ThermostatPage> {
  // State variables
  double _temperature = 22.0; //???///
  bool _isHeating = true;

  // Constants
  final double _minTemp = 16.0;
  final double _maxTemp = 30.0;

  void _updateTemp(double newTemp) {
    if (_temperature != newTemp) {
      setState(() {
        _temperature = newTemp;
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.white54),
        actions: const [
          Icon(Icons.settings, color: Colors.white54),
          SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // LAYER 1: Background (Wrapped in ClipRect to stop blur bleeding)
          const Positioned.fill(child: _AmbientBackground()),

          // LAYER 2: Main Content (Sharp)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Thermostat Control",
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Thermostat Dial
                GlassThermostatDial(
                  temperature: _temperature,
                  min: _minTemp,
                  max: _maxTemp,
                  onChanged: _updateTemp,
                ),

                const SizedBox(height: 60),

                // Mode Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeButton(
                      isActive: _isHeating,
                      icon: Icons.local_fire_department,
                      label: "HEAT",
                      color: Colors.redAccent,
                      onTap: () => setState(() => _isHeating = true),
                    ),
                    const SizedBox(width: 20),
                    _ModeButton(
                      isActive: !_isHeating,
                      icon: Icons.ac_unit,
                      label: "COOL",
                      color: Colors.lightBlueAccent,
                      onTap: () => setState(() => _isHeating = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. BACKGROUND WIDGET (Fixed Clipping)
// ==========================================
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    // ClipRect ensures the BackdropFilter inside doesn't blur the whole screen
    return ClipRect(
      child: Container(
        color: const Color(0xFF101014),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.1),
                ),
              ),
            ),
            // The blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. THE GLASS DIAL (Fixed Clipping)
// ==========================================
class GlassThermostatDial extends StatefulWidget {
  final double temperature;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const GlassThermostatDial({
    super.key,
    required this.temperature,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<GlassThermostatDial> createState() => _GlassThermostatDialState();
}

class _GlassThermostatDialState extends State<GlassThermostatDial> {
  static const double _startAngle = 135 * pi / 180;
  static const double _sweepAngle = 270 * pi / 180;

  void _handlePan(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;
    double angle = atan2(vector.dy, vector.dx);
    if (angle < 0) angle += 2 * pi;
    double relativeAngle = angle - _startAngle;
    if (relativeAngle < 0) relativeAngle += 2 * pi;
    double progress = relativeAngle / _sweepAngle;

    if (progress > 1.0) {
      if (progress > 1.5)
        progress = 0.0;
      else
        progress = 1.0;
    }

    final newTemp = widget.min + (progress * (widget.max - widget.min));
    final rounded = double.parse(newTemp.toStringAsFixed(1));

    if (rounded != widget.temperature) {
      widget.onChanged(rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 300;
    final progress =
        (widget.temperature - widget.min) / (widget.max - widget.min);

    return GestureDetector(
      onPanUpdate: (d) => _handlePan(d.localPosition, const Size(size, size)),
      onPanDown: (d) => _handlePan(d.localPosition, const Size(size, size)),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: The Painter
            CustomPaint(
              size: const Size(size, size),
              painter: _DialPainter(
                progress: progress,
                startAngle: _startAngle,
                sweepAngle: _sweepAngle,
              ),
            ),
            // Layer 2: The Glass Center (FIXED: Added ClipOval)
            ClipOval(
              child: Container(
                width: size * 0.65,
                height: size * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${widget.temperature.toStringAsFixed(1)}°",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "CELSIUS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. THE PAINTER
// ==========================================
class _DialPainter extends CustomPainter {
  final double progress;
  final double startAngle;
  final double sweepAngle;

  _DialPainter({
    required this.progress,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Background Track
    final trackPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.05);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active Gradient
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [Color(0xFF64B5F6), Color(0xFFBA68C8), Color(0xFFE57373)],
      tileMode: TileMode.repeated,
    );

    final activePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    // Ticks
    final tickPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..strokeWidth = 2;

    const int totalTicks = 40;
    for (int i = 0; i <= totalTicks; i++) {
      final t = i / totalTicks;
      final angle = startAngle + (sweepAngle * t);
      final outerR = radius - 40;
      final innerR = radius - 50;
      final p1 = Offset(
        center.dx + cos(angle) * outerR,
        center.dy + sin(angle) * outerR,
      );
      final p2 = Offset(
        center.dx + cos(angle) * innerR,
        center.dy + sin(angle) * innerR,
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Knob Indicator
    final currentAngle = startAngle + (sweepAngle * progress);
    final knobRadius = radius - 20;
    final knobCenter = Offset(
      center.dx + cos(currentAngle) * knobRadius,
      center.dy + sin(currentAngle) * knobRadius,
    );

    canvas.drawCircle(
      knobCenter,
      12,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(knobCenter, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ==========================================
// 6. HELPER WIDGETS
// ==========================================
class _ModeButton extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:
              isActive
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
