import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/goal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_decoration.dart';
import '../widgets/pastel_card.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isCompleting = false;

  int get _totalSeconds => widget.goal.durationMinutes * 60;
  int get _halfSeconds => (_totalSeconds / 2).ceil();
  bool get _canValidate => _elapsedSeconds >= _halfSeconds;
  int get _remainingSeconds => _totalSeconds - _elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 1.0 : (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Focus timer')),
      body: Stack(
        children: [
          const Positioned(top: 24, right: 70, child: FlowerDecoration(size: 58)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: PastelCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.goal.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (widget.goal.description != null) ...[
                        const SizedBox(height: 10),
                        Text(widget.goal.description!, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 28),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 450),
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 18,
                            backgroundColor: CozyColors.beige,
                            color: CozyColors.sage,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        _timerLabel(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: CozyColors.roseText,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _canValidate ? 'You may validate now, or continue a little longer.' : 'Validation unlocks halfway through the session.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _canValidate
                            ? FilledButton.icon(
                                key: const ValueKey('validate'),
                                onPressed: _isCompleting ? null : _completeGoal,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: Text(_isCompleting ? 'Validating...' : 'Validate goal'),
                              )
                            : OutlinedButton.icon(
                                key: const ValueKey('wait'),
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_bottom_rounded),
                                label: Text('Validate available in ${_formatDuration(_halfSeconds - _elapsedSeconds)}'),
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Stop and return without validating'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timerLabel() {
    if (_remainingSeconds >= 0) {
      return _formatDuration(_remainingSeconds);
    }
    return '+${_formatDuration(_remainingSeconds.abs())}';
  }

  String _formatDuration(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final secs = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _completeGoal() async {
    setState(() => _isCompleting = true);
    await ref.read(appControllerProvider.notifier).completeGoalAfterFocus(widget.goal);
    if (mounted) Navigator.of(context).pop();
  }
}
