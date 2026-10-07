import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/buddy_character.dart';

class WaterBuddy extends StatefulWidget {
  const WaterBuddy({
    this.width = 112,
    this.character = BuddyCharacter.boy,
    super.key,
  });
  final double width;
  final BuddyCharacter character;

  @override
  State<WaterBuddy> createState() => _WaterBuddyState();
}

class _WaterBuddyState extends State<WaterBuddy>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _motion,
      child: SizedBox(
        width: widget.width,
        height: widget.width * widget.character.heightFactor,
        child: Image.asset(
          widget.character.asset,
          fit: widget.character == BuddyCharacter.boy
              ? BoxFit.cover
              : BoxFit.contain,
          alignment: Alignment.center,
          cacheWidth:
              (widget.width * 1.3 * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
          gaplessPlayback: true,
        ),
      ),
      builder: (context, child) {
        final wave = math.sin(_motion.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, wave * 3),
          child: Transform.rotate(angle: wave * .012, child: child),
        );
      },
    ),
  );
}
