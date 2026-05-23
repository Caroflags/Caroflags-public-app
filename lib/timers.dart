import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'timer_settings.dart';
import 'timer_service.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({Key? key}) : super(key: key);

  @override
  _TimersScreenState createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  late Box timerBox;

  @override
  void initState() {
    super.initState();
    timerBox = Hive.box('timer_settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const TimerSettingsPage(),
                    ),
                  )
                  .then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (timerBox.get('enable_drinks', defaultValue: true))
            const TimerCard(
              id: 'drinks',
              title: 'Drinks',
              duration: Duration(minutes: 15),
              icon: Icons.local_drink,
            ),
          if (timerBox.get('enable_all_day', defaultValue: true))
            const TimerCard(
              id: 'all_day',
              title: 'All day dining',
              duration: Duration(minutes: 90),
              icon: Icons.restaurant,
            ),
          if (timerBox.get('enable_all_season', defaultValue: true))
            const TimerCard(
              id: 'all_season',
              title: 'All season dining',
              duration: Duration(hours: 4),
              icon: Icons.restaurant_menu,
            ),
        ],
      ),
    );
  }
}

class TimerCard extends StatefulWidget {
  final String id;
  final String title;
  final Duration duration;
  final IconData icon;

  const TimerCard({
    Key? key,
    required this.id,
    required this.title,
    required this.duration,
    required this.icon,
  }) : super(key: key);

  @override
  _TimerCardState createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isActive = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _loadState() {
    final box = Hive.box('timer_settings');
    final remainingMillis = box.get('timer_remaining_${widget.id}');

    if (remainingMillis != null) {
      _isActive = false;
      _isPaused = true;
      _remaining = Duration(milliseconds: remainingMillis);
      return;
    }

    final endTimeMillis = TimerService.getTimerEndTime(widget.id);
    if (endTimeMillis != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();
      if (endTime.isAfter(now)) {
        _isActive = true;
        _isPaused = false;
        _remaining = endTime.difference(now);
      } else {
        _isActive = false;
        _isPaused = false;
        _remaining = Duration.zero;
      }
    } else {
      _isActive = false;
      _isPaused = false;
      _remaining = Duration.zero;
    }
  }

  void _tick(Timer timer) {
    if (_isActive) {
      setState(() {
        _loadState();
      });
    }
  }

  void _startTimer() {
    final box = Hive.box('timer_settings');
    box.delete('timer_remaining_${widget.id}');
    final endTime = DateTime.now().add(widget.duration);
    TimerService.startTimer(widget.id, widget.title, widget.duration, endTime);
    setState(() {
      _isActive = true;
      _isPaused = false;
      _remaining = widget.duration;
    });
  }

  void _pauseTimer() {
    final box = Hive.box('timer_settings');
    box.put('timer_remaining_${widget.id}', _remaining.inMilliseconds);
    TimerService.cancelTimer(widget.id);
    setState(() {
      _isActive = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    final box = Hive.box('timer_settings');
    box.delete('timer_remaining_${widget.id}');
    final endTime = DateTime.now().add(_remaining);
    TimerService.startTimer(widget.id, widget.title, _remaining, endTime);
    setState(() {
      _isActive = true;
      _isPaused = false;
    });
  }

  void _cancelTimer() {
    final box = Hive.box('timer_settings');
    box.delete('timer_remaining_${widget.id}');
    TimerService.cancelTimer(widget.id);
    setState(() {
      _isActive = false;
      _isPaused = false;
      _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_isActive || _isPaused)
        ? _remaining.inSeconds / widget.duration.inSeconds
        : 1.0;

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String hours = twoDigits(d.inHours);
      String minutes = twoDigits(d.inMinutes.remainder(60));
      String seconds = twoDigits(d.inSeconds.remainder(60));
      if (d.inHours > 0) {
        return "$hours:$minutes:$seconds";
      }
      return "$minutes:$seconds";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: progress, end: progress),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        size: const Size(200, 100),
                        painter: ArchPainter(
                          progress: value,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    child: Text(
                      (_isActive || _isPaused)
                          ? formatDuration(_remaining)
                          : formatDuration(widget.duration),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isActive
                        ? _pauseTimer
                        : (_isPaused ? _resumeTimer : _startTimer),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      _isActive
                          ? 'Pause'
                          : (_isPaused ? 'Resume' : 'Start Timer'),
                    ),
                  ),
                ),
                if (_isActive || _isPaused) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelTimer,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ArchPainter extends CustomPainter {
  final double progress;
  final Color color;

  ArchPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width,
      height: size.height * 2,
    );

    // Draw background arch
    canvas.drawArc(rect, pi, pi, false, paintBg);

    // Draw shrinking foreground arch based on progress (shrinking from both sides to center? Or just one side)
    // The user said "shrink from both sides to one side". Usually progress bars go from full to empty.
    // If it shrinks to one side, it means it sweeps from pi, with sweepAngle = pi * progress.
    canvas.drawArc(rect, pi, pi * progress, false, paintFg);
  }

  @override
  bool shouldRepaint(covariant ArchPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
