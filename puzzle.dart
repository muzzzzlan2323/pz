import 'dart:math';
import 'package:flutter/material.dart';

class PuzzleCaptcha extends StatefulWidget {
  final ValueChanged<bool> onVerified;
  const PuzzleCaptcha({super.key, required this.onVerified});

  @override
  State<PuzzleCaptcha> createState() => _PuzzleCaptchaState();
}

class _PuzzleCaptchaState extends State<PuzzleCaptcha> {
  double _t = 0; // Положение ползунка от 0.0 до 1.0
  bool _done = false;

  // Случайная цель (от 0.35 до 0.90) и случайный неровный угол выреза
  late final double _targetT = 0.35 + Random().nextDouble() * 0.55;
  late final double _targetAngle =
      (Random().nextBool() ? 1 : -1) * (0.25 + Random().nextDouble() * 0.45);

  double get _targetX => _targetT * 220;
  double get _x => _t * 220;
  // Когда _t доходит до _targetT, угол пазла точно совпадает с _targetAngle
  double get _angle => _targetAngle + (_t - _targetT) * 3.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 160,
            child: Stack(
              children: [
                // 1. Фоновая картинка
                Image.asset('assets/images/landscape.jpg', width: 280, height: 160, fit: BoxFit.cover),

                // 2. Повёрнутый слот на фоне
                Positioned(
                  left: _targetX,
                  top: 50,
                  child: Transform.rotate(
                    angle: _targetAngle,
                    child: CustomPaint(size: const Size(60, 60), painter: _SlotPainter()),
                  ),
                ),

                // 3. Подвижный пазл с вращением и контр-вращением текстуры
                Positioned(
                  left: _x,
                  top: 50,
                  child: Transform.rotate(
                    angle: _angle, // Крутим сам пазл
                    child: ClipPath(
                      clipper: _PuzzleClipper(),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Transform.rotate(
                          angle: -_angle, // Крутим фото обратно, чтобы оно оставалось ровным
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -_targetX,
                                top: -50,
                                child: Image.asset(
                                  'assets/images/landscape.jpg',
                                  width: 280,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Ползунок
          Slider(
            value: _t,
            activeColor: _done ? Colors.green : Colors.black,
            onChanged: _done ? null : (v) => setState(() => _t = v),
            onChangeEnd: _done
                ? null
                : (v) {
                    final ok = (_x - _targetX).abs() <= 10 && (_angle - _targetAngle).abs() <= 0.15;
                    setState(() {
                      _done = ok;
                      _t = ok ? _targetT : 0;
                    });
                    widget.onVerified(ok);
                  },
          ),
        ],
      ),
    );
  }
}

// Форма пазла: сверху и снизу плоско, справа выступ, слева выемка
Path _puzzlePath() {
  var p = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 40));
  p = Path.combine(PathOperation.union, p, Path()..addOval(Rect.fromCircle(center: const Offset(50, 30), radius: 8)));
  p = Path.combine(PathOperation.difference, p, Path()..addOval(Rect.fromCircle(center: const Offset(10, 30), radius: 8)));
  return p;
}

class _PuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _puzzlePath();
  @override
  bool shouldReclip(covariant _PuzzleClipper oldClipper) => false;
}

class _SlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = _puzzlePath();
    canvas.drawPath(p, Paint()..color = Colors.black54);
    canvas.drawPath(p, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant _SlotPainter oldDelegate) => false;
}