import 'package:flutter/material.dart';
import '../theme.dart';

/// ゆらゆら浮かぶ「はとっぴー」のアバター。
/// 絵文字ベースなので画像アセット無しでもそのまま動く。
class HatoppyAvatar extends StatefulWidget {
  final double size;
  const HatoppyAvatar({super.key, this.size = 72});

  @override
  State<HatoppyAvatar> createState() => _HatoppyAvatarState();
}

class _HatoppyAvatarState extends State<HatoppyAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
        final dy = -6 * _controller.value;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentYellow,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '🕊️',
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    );
  }
}

/// はとっぴーのセリフを表示する吹き出し。
/// アバターと横並びにして使う想定。
class HatoppySpeechBubble extends StatelessWidget {
  final String message;
  final Color color;
  const HatoppySpeechBubble({
    super.key,
    required this.message,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(color: color),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 吹き出し左側の小さな三角形（しっぽ）を描くペインター。
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(10, size.height / 2 - 8)
      ..lineTo(0, size.height / 2)
      ..lineTo(10, size.height / 2 + 8)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => false;
}

/// はとっぴーのアバター＋ふきだしをまとめたセット。
/// クイズ画面などで「はとっぴーが話しかけてくる」演出に使う。
class HatoppyTalk extends StatelessWidget {
  final String message;
  const HatoppyTalk({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HatoppyAvatar(size: 64),
        Expanded(child: HatoppySpeechBubble(message: message)),
      ],
    );
  }
}
