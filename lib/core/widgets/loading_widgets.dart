import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

/// Phase 5: UI/UX Polish - Custom Loading States
/// 
/// Beautiful loading indicators with HelaService branding

/// Animated loading indicator with brand colors
class HelaLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final LoadingIndicatorType type;

  const HelaLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.type = LoadingIndicatorType.ballSpinFadeLoader,
  });

  const HelaLoadingIndicator.small({
    super.key,
    this.size = 24,
    this.color,
    this.type = LoadingIndicatorType.ballPulse,
  });

  const HelaLoadingIndicator.large({
    super.key,
    this.size = 72,
    this.color,
    this.type = LoadingIndicatorType.ballSpinFadeLoader,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: LoadingIndicator(
        indicatorType: type,
        colors: [themeColor],
        strokeWidth: size / 12,
      ),
    );
  }
}

/// Full screen loading overlay with blur effect
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HelaLoadingIndicator.large(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pull-to-refresh indicator with custom animation
class PullToRefreshIndicator extends StatelessWidget {
  final double progress;

  const PullToRefreshIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _RefreshPainter(
        progress: progress,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _RefreshPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RefreshPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );

    // Draw arrow head
    final arrowAngle = -math.pi / 2 + sweepAngle;
    final arrowLength = 8.0;
    final arrowX = center.dx + radius * math.cos(arrowAngle);
    final arrowY = center.dy + radius * math.sin(arrowAngle);

    final path = Path()
      ..moveTo(arrowX, arrowY)
      ..lineTo(
        arrowX - arrowLength * math.cos(arrowAngle - 0.5),
        arrowY - arrowLength * math.sin(arrowAngle - 0.5),
      )
      ..moveTo(arrowX, arrowY)
      ..lineTo(
        arrowX - arrowLength * math.cos(arrowAngle + 0.5),
        arrowY - arrowLength * math.sin(arrowAngle + 0.5),
      );

    canvas.drawPath(path, paint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _RefreshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated progress bar with percentage
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Duration duration;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPercentage;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.duration = const Duration(milliseconds: 500),
    this.backgroundColor,
    this.progressColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final fgColor = progressColor ?? theme.colorScheme.primary;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeInOut,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        fgColor,
                        fgColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(clampedProgress * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Step progress indicator for multi-step flows
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? labels;
  final double height;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.height = 4,
  }) : assert(labels == null || labels.length == totalSteps);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress line
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector
              final stepIndex = index ~/ 2;
              final isActive = stepIndex < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
              );
            } else {
              // Step dot
              final stepIndex = index ~/ 2;
              final isActive = stepIndex <= currentStep;
              final isCurrent = stepIndex == currentStep;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 20 : 12,
                height: isCurrent ? 20 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  border: isCurrent
                      ? Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 4,
                        )
                      : null,
                ),
                child: isActive && !isCurrent
                    ? Icon(
                        Icons.check,
                        size: 8,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              );
            }
          }),
        ),

        // Labels
        if (labels != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              return Text(
                labels![index],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Circular progress with center text
class CircularProgressWithText extends StatelessWidget {
  final double progress;
  final String? label;
  final double size;
  final double strokeWidth;

  const CircularProgressWithText({
    super.key,
    required this.progress,
    this.label,
    this.size = 80,
    this.strokeWidth = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation(
              theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          // Progress circle
          AnimatedCircularProgress(
            progress: clampedProgress,
            strokeWidth: strokeWidth,
            color: theme.colorScheme.primary,
          ),
          // Center text
          if (label != null)
            Center(
              child: Text(
                label!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated circular progress indicator
class AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Duration duration;

  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    required this.strokeWidth,
    required this.color,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animateToProgress(widget.progress);
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animateToProgress(widget.progress);
    }
  }

  void _animateToProgress(double progress) {
    _animation = Tween<double>(
      begin: _previousProgress,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CircularProgressIndicator(
          value: _animation.value,
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation(widget.color),
        );
      },
    );
  }
}

/// Loading button with built-in loading state
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final bool fullWidth;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.elevated,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    final buttonContent = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    type == ButtonType.elevated
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(text),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    switch (type) {
      case ButtonType.elevated:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

enum ButtonType { elevated, outlined, text }

/// Pulsing dot indicator for "more content loading"
class PulsingDots extends StatefulWidget {
  final int dotCount;
  final double size;
  final Color? color;

  const PulsingDots({
    super.key,
    this.dotCount = 3,
    this.size = 8,
    this.color,
  });

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Curves.easeInOut,
              ),
            ))
        .toList();

    // Start animations with delays
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size * _animations[index].value,
              height: widget.size * _animations[index].value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withOpacity(_animations[index].value),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Loading state wrapper that shows skeleton or loading indicator
class LoadingState extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? skeleton;
  final LoadingType type;
  final String? message;

  const LoadingState({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
    this.type = LoadingType.skeleton,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    switch (type) {
      case LoadingType.skeleton:
        return skeleton ?? const SizedBox.shrink();
      case LoadingType.indicator:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HelaLoadingIndicator.large(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        );
      case LoadingType.none:
        return const SizedBox.shrink();
    }
  }
}

enum LoadingType { skeleton, indicator, none }
