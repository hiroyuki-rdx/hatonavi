import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/point_service.dart';
import 'home_screen.dart';
import 'point_screen.dart';

/// 企画書「③ リアル店舗連動『おてつだい達成シール』」を再現する完了画面。
/// ピピットセルフ決済の演出 → シール引換券の表示 → 獲得バッジ（ご当地はとっぴー図鑑）の確認、
/// という一連の体験をまとめている。
class StickerScreen extends StatefulWidget {
  final int totalItems;
  final List<ShoppingItem> collected;

  /// 今回のおつかいで獲得したポイント（＝正解数 = collected.length）。
  /// ポイント画面へ引き継ぐとともに、initState で累計に加算保存する。
  final int earnedPoints;

  const StickerScreen({
    super.key,
    required this.totalItems,
    required this.collected,
    required this.earnedPoints,
  });

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  bool _processing = true;

  @override
  void initState() {
    super.initState();
    // 今回獲得ポイントを累計に一度だけ加算保存する。
    PointService.add(widget.earnedPoints);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _processing = false);
    });
  }

  /// ポイント画面へ進む。ポイント画面の「ホームにもどる」で
  /// ホームまで一気に戻す（履歴をすべて破棄）。
  void _showPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PointScreen(
          earnedPoints: widget.earnedPoints,
          onBackToHome: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreenDark,
      body: SafeArea(
        child: _processing ? const _PayingView() : _buildResult(context),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final collected = widget.collected;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const Text(
            'おつかれさま！\nおかいもの達成！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ピピットセルフ決済が完了しました',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const _StickerTicket(),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ご当地はとっぴー図鑑',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryGreenDark,
                        ),
                      ),
                    ),
                    Text(
                      '${collected.length} / ${widget.totalItems}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: collected.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final item = collected[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBeige,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accentOrange),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.badgeEmoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            item.badgeName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (collected.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'クイズに正解するとバッジが増えるよ！\n次はチャレンジしてみよう。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDark, fontSize: 12, height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showPoints,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('ポイントをみる'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PayingView extends StatelessWidget {
  const _PayingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            'ピピットセルフで決済しています…',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// サービスカウンターで提示する「シール引換券」を模したチケットUI。
class _StickerTicket extends StatelessWidget {
  const _StickerTicket();

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
                  style: TextStyle(fontSize: 11, color: AppColors.textDark.withOpacity(0.6)),
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
