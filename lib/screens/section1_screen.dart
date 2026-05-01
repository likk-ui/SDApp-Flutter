import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Section1Screen extends StatefulWidget {
  const Section1Screen({super.key});

  @override
  State<Section1Screen> createState() => _Section1ScreenState();
}

class _Section1ScreenState extends State<Section1Screen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 600;
  bool _isPlaying = false;
  bool _isTraining = false;
  int _frame = 0;
  String _gratingStyle = 'scroll-bw';
  int _gratingSpeed = 2;
  int _opacityLevel = 6;
  bool _showControls = false;
  late AnimationController _animationController;

  final List<String> _styles = ['scroll-bw', 'scroll-ry', 'checker-bw', 'checker-ry', 'flash-bw', 'flash-ry', 'rotate-stripes', 'rotate-checker'];
  final List<String> _styleLabels = ['滚动黑白', '滚动红黄', '棋盘黑白', '棋盘红黄', '闪烁黑白', '闪烁红黄', '旋转条纹', '旋转棋盘'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      if (_isPlaying) {
        setState(() => _frame++);
      }
    });
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('光栅训练'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isPlaying || _isTraining)
            CustomPaint(
              painter: GratingPainter(
                frame: _frame,
                style: _gratingStyle,
                speed: _gratingSpeed,
                opacity: _opacityLevel / 10.0,
                isTraining: _isTraining,
                remainingSeconds: _remainingSeconds,
              ),
              size: Size.infinite,
            ),
          if (!_isPlaying && !_isTraining)
            Container(
              color: Colors.black,
              child: const Center(
                child: Text('点击开始训练', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
          if (_isTraining)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          if (_isPlaying || _isTraining)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.pink,
                  onPressed: () => setState(() => _showControls = !_showControls),
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
              ),
            ),
          if (_showControls)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('控制面板', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: List.generate(_styles.length, (i) => ChoiceChip(
                          label: Text(_styleLabels[i]),
                          selected: _gratingStyle == _styles[i],
                          onSelected: (_) => setState(() => _gratingStyle = _styles[i]),
                        )),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('速度: '),
                          IconButton(icon: const Icon(Icons.remove), onPressed: () {
                            if (_gratingSpeed > 1) setState(() => _gratingSpeed--);
                          }),
                          Text('$_gratingSpeed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add), onPressed: () {
                            if (_gratingSpeed < 5) setState(() => _gratingSpeed++);
                          }),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('透明度: '),
                          IconButton(icon: const Icon(Icons.remove), onPressed: () {
                            if (_opacityLevel > 1) setState(() => _opacityLevel--);
                          }),
                          Text('$_opacityLevel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add), onPressed: () {
                            if (_opacityLevel < 6) setState(() => _opacityLevel++);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _stopGrating,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('停止'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isPlaying && !_isTraining)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '训练时长（分钟）',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: TextEditingController(text: '10'),
                      onSubmitted: (v) => _startTraining(int.tryParse(v) ?? 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _startTraining(10),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始训练'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _startTraining(int minutes) async {
    setState(() {
      _isTraining = true;
      _isPlaying = true;
      _remainingSeconds = minutes * 60;
      _showControls = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPlaying', true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _stopGrating();
        }
      });
    });
  }

  void _stopGrating() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isTraining = false;
      _remainingSeconds = 0;
      _showControls = false;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class GratingPainter extends CustomPainter {
  final int frame;
  final String style;
  final int speed;
  final double opacity;
  final bool isTraining;
  final int remainingSeconds;

  GratingPainter({
    required this.frame,
    required this.style,
    required this.speed,
    required this.opacity,
    required this.isTraining,
    required this.remainingSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final colors = style.contains('ry') ? [Colors.red, Colors.yellow] : [Colors.black, Colors.white];
    final minDim = w < h ? w : h;
    final stripeSize = (minDim / 12).clamp(10.0, 100.0);

    final paint = Paint();

    switch (style) {
      case 'scroll-bw':
      case 'scroll-ry':
        paint.color = colors[0];
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = colors[1];
        final offset = (frame * speed) % (stripeSize * 2);
        for (double x = -stripeSize * 2; x < w + stripeSize; x += stripeSize * 2) {
          canvas.drawRect(Rect.fromLTWH(x + offset, 0, stripeSize, h), paint);
        }
        break;
      case 'checker-bw':
      case 'checker-ry':
        final inv = (frame * speed ~/ 60) % 2 == 0;
        for (double x = 0; x < w; x += stripeSize) {
          for (double y = 0; y < h; y += stripeSize) {
            final isEven = ((x / stripeSize).toInt() + (y / stripeSize).toInt()) % 2 == 0;
            paint.color = isEven == inv ? colors[0] : colors[1];
            canvas.drawRect(Rect.fromLTWH(x, y, stripeSize, stripeSize), paint);
          }
        }
        break;
      case 'flash-bw':
      case 'flash-ry':
        paint.color = (frame * speed ~/ 80) % 2 == 0 ? colors[0] : colors[1];
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        break;
      case 'rotate-stripes':
      case 'rotate-checker':
        final cx = w / 2;
        final cy = h / 2;
        final maxDim = (w * w + h * h).toDouble();
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(frame * speed * 0.5);
        paint.color = colors[1];
        canvas.drawRect(Rect.fromLTWH(-maxDim, -maxDim, maxDim * 2, maxDim * 2), paint);
        paint.color = colors[0];
        if (style == 'rotate-stripes') {
          for (double x = -maxDim; x < maxDim; x += stripeSize * 2) {
            canvas.drawRect(Rect.fromLTWH(x, -maxDim, stripeSize, maxDim * 2), paint);
          }
        } else {
          for (double x = -maxDim; x < maxDim; x += stripeSize) {
            for (double y = -maxDim; y < maxDim; y += stripeSize) {
              final gx = (x / stripeSize).round();
              final gy = (y / stripeSize).round();
              if ((gx + gy) % 2 == 0) {
                canvas.drawRect(Rect.fromLTWH(x, y, stripeSize, stripeSize), paint);
              }
            }
          }
        }
        canvas.restore();
        break;
    }

    if (isTraining && remainingSeconds > 0) {
      paint.color = Colors.black.withOpacity(0.7);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, 80), paint);
      paint.color = Colors.white;
      paint.textSize = 40;
      paint.textAlign = TextAlign.center;
      canvas.drawText('剩余时间 ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}', Offset(w / 2, 50), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GratingPainter oldDelegate) => true;
}