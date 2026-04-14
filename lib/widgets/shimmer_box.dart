import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 1).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 1).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF2E2E2E),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tam ekran yükleniyor iskeleti
class FeedShimmer extends StatelessWidget {
  const FeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShimmerBox(height: double.infinity, borderRadius: 0),
          Positioned(
            left: 16,
            right: 80,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 16, borderRadius: 8),
                SizedBox(height: 10),
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: 200, height: 12),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 60,
            child: Column(
              children: [
                ShimmerBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(height: 20),
                ShimmerBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(height: 20),
                ShimmerBox(width: 40, height: 40, borderRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
