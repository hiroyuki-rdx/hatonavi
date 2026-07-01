import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/point_service.dart';
import '../services/gemini_service.dart';
import 'home_screen.dart';
import 'point_screen.dart';

/// おつかい完了画面。
/// お会計をうながす演出 → 今回／累計ポイントの表示 → 獲得バッジ（ご当地はとっぴー図鑑）
/// → 保護者向け「きょうのまなび」、という一連の体験をまとめている。
/// （旧「シール引換券」はポイント表示に置き換え。シール交換はポイント画面に残す）
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

  /// 今回ぶんを加算した後の累計ポイント（読み込み完了までは null）。
  int? _totalPoints;

  /// 「おうちのひとへ きょうのまなび」サマリの状態。
  /// 取得中は _summaryLoading=true でローディング表示、完了で文章を表示する。
  bool _summaryLoading = true;
  String? _parentSummary;

  /// AI（GeminiService.generateParentSummary）が null を返した／落ちたときに
  /// 必ず表示する固定フォールバック文（温かい日本語2文）。
  /// これによりAIが落ちても保護者向けカードを絶対に空にしない＝デモを止めない。
  static const String _fallbackSummary =
      '本日は、地産地消や食育について楽しく学びました。'
      'ご家庭でも、今日どんなことを学んだか話してみてくださいね。';

  @override
  void initState() {
    super.initState();
    // 今回獲得ポイントを累計に一度だけ加算し、加算後の累計を読み込む。
    _applyPointsAndLoadTotal();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _processing = false);
    });
    _loadParentSummary();
  }

  /// 今回ぶんのポイントを一度だけ累計に加算し、加算後の累計を読み込んで表示に反映する。
  Future<void> _applyPointsAndLoadTotal() async {
    await PointService.add(widget.earnedPoints);
    final total = await PointService.loadTotal();
    if (!mounted) return;
    setState(() => _totalPoints = total);
  }

  /// 今日クイズで学んだ商品リスト（widget.collected）から保護者向けサマリを取得する。
  /// 生成は別部隊実装の GeminiService.generateParentSummary に委譲（契約シグネチャ）。
  /// 失敗・null 時は固定フォールバック文を使い、カードを必ず埋める。
  Future<void> _loadParentSummary() async {
    String? summary;
    try {
      summary = await GeminiService.generateParentSummary(widget.collected);
    } catch (_) {
      summary = null;
    }
    if (!mounted) return;
    setState(() {
      _parentSummary = (summary == null || summary.trim().isEmpty)
          ? _fallbackSummary
          : summary;
      _summaryLoading = false;
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
            'おかいけいに すすもうね',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _PointsResultCard(
            earnedPoints: widget.earnedPoints,
            totalPoints: _totalPoints,
          ),
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
                          Text(
                            item.badgeEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.badgeName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ParentSummaryCard(
            loading: _summaryLoading,
            summary: _parentSummary ?? _fallbackSummary,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showPoints,
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
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
            'おかいけいに すすもうね',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 完了画面で「今回の獲得ポイント」と「累計ポイント」を見せるカード。
/// （旧「シール引換券」の置き換え。シール交換はポイント画面に残している）
class _PointsResultCard extends StatelessWidget {
  /// 今回のおつかいで獲得したポイント。
  final int earnedPoints;

  /// 加算後の累計ポイント。読み込み中は null。
  final int? totalPoints;

  const _PointsResultCard({required this.earnedPoints, this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          const Text(
            'こんかいの ポイント',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$earnedPoints',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'P',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBeige,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'ためた ポイント',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  totalPoints == null ? '… P' : '$totalPoints P',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreenDark,
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

/// 完了画面の「おうちのひとへ きょうのまなび」カード。
/// AI（[GeminiService.generateParentSummary]）が生成した保護者向けサマリを表示する。
/// 取得中は [loading]=true でローディング表示、取得後（失敗時は固定フォールバック文）は本文を表示。
class _ParentSummaryCard extends StatelessWidget {
  final bool loading;
  final String summary;
  const _ParentSummaryCard({required this.loading, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: const [
              Text('🕊️', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'おうちのひとへ きょうのまなび',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'AIが きょうの まなびを まとめました',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.accentOrange,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            Row(
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'まとめを よみこみちゅう…',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ],
            )
          else
            Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textDark,
              ),
            ),
        ],
      ),
    );
  }
}
