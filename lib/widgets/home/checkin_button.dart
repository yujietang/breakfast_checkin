import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 打卡按钮 - 带动画效果
class CheckInButton extends StatefulWidget {
  final bool isCheckedIn;
  final VoidCallback onPressed;
  final double size;

  const CheckInButton({
    super.key,
    required this.isCheckedIn,
    required this.onPressed,
    this.size = 160,
  });

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (!widget.isCheckedIn) {
      _startPulseAnimation();
    }
  }

  void _startPulseAnimation() {
    _controller.repeat(reverse: true, period: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(CheckInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCheckedIn != oldWidget.isCheckedIn) {
      if (widget.isCheckedIn) {
        _controller.stop();
      } else {
        _startPulseAnimation();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCheckedIn ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isCheckedIn
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.8),
                        AppColors.success,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary,
                        AppColors.accent,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isCheckedIn ? AppColors.success : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isCheckedIn ? Icons.check : Icons.restaurant,
                  size: widget.size * 0.35,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isCheckedIn ? '已打卡' : '打卡',
                  style: TextStyle(
                    fontSize: widget.size * 0.18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!widget.isCheckedIn)
                  Text(
                    '🍳',
                    style: TextStyle(fontSize: widget.size * 0.15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
