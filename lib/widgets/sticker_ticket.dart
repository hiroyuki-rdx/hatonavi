import 'package:flutter/material.dart';
import '../theme.dart';

/// サービスカウンターで提示する「シール引換券」カード。
/// ポイント画面のシール交換などで表示する（疑似QRはデザイン要素で読み取りはしない）。
class StickerTicket extends StatelessWidget {
  const StickerTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              children: [
                const Text('🎟️', style: TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                const Text(
                  'シール引換券',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '限定「はとっぴーおてつだい達成シール」と交換',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDark.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const _DashedDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const _FakeQrCode(),
                const SizedBox(height: 10),
                Text(
                  'サービスカウンターで\n店員さんにこの画面を見せてね！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// チケットの切り取り線を模した点線。
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 10).floor();
          return Row(
            children: List.generate(dashCount, (index) {
              return Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: index.isEven ? Colors.black26 : Colors.transparent,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 装飾用の疑似QRコード（実際には読み取れないデザイン要素）。
class _FakeQrCode extends StatelessWidget {
  const _FakeQrCode();

  @override
  Widget build(BuildContext context) {
    const gridSize = 7;
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          final row = index ~/ gridSize;
          final col = index % gridSize;
          final isCorner = (row < 2 && col < 2) ||
              (row < 2 && col >= gridSize - 2) ||
              (row >= gridSize - 2 && col < 2);
          final filled = isCorner || (row * 3 + col * 7) % 5 == 0;
          return Container(
            margin: const EdgeInsets.all(1),
            color: filled ? AppColors.primaryGreenDark : Colors.transparent,
          );
        },
      ),
    );
  }
}
