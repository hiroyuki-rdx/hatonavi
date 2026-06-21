import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';
import '../services/level_service.dart';
import 'shopping_list_screen.dart';
import 'point_screen.dart';

/// アプリのトップ画面。
///
/// スタートボタンの近くに「おこさまの がくねん（クイズのむずかしさ）」セレクタを置き、
/// 選んだ難易度を [LevelService] に保存する。保存値はクイズ生成時に使われる。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 現在選択中のレベル id。初期値は既定（無ければ「小学生」）。
  int _levelId = LevelService.defaultId;

  @override
  void initState() {
    super.initState();
    // 保存済みのレベルを読み込んで初期表示に反映する。
    LevelService.load().then((id) {
      if (!mounted) return;
      setState(() => _levelId = id);
    });
  }

  /// チップ選択時：表示を更新しつつ永続化＋メモリキャッシュ更新。
  void _selectLevel(int id) {
    setState(() => _levelId = id);
    LevelService.save(id); // currentId もここで更新される
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const HatoppyAvatar(size: 120),
              const SizedBox(height: 20),
              const Text(
                'はとナビ\nおつかいクエスト',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreenDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBeige,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'おかいものリストにそって\n'
                  'はとっぴーといっしょに\n'
                  'お店をたんけんしよう！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Spacer(),
              // クイズの難易度（おこさまの がくねん）を選ぶコンパクトなセレクタ。
              _LevelSelector(
                selectedId: _levelId,
                onSelect: _selectLevel,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    );
                  },
                  child: const Text('クエストをはじめる！'),
                ),
              ),
              const SizedBox(height: 12),
              // いつでもポイント確認・シール交換ができる導線。
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PointScreen(
                          fromHome: true,
                          onBackToHome: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: const Text('ポイント・シールこうかん'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '平和堂 × ソフトバンク\nハッカソン プロトタイプ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「おこさまの がくねん（クイズのむずかしさ）」を選ぶ小さなチップ群。
class _LevelSelector extends StatelessWidget {
  final int selectedId;
  final ValueChanged<int> onSelect;
  const _LevelSelector({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'おこさまの がくねん（クイズのむずかしさ）',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final level in LevelService.levels) ...[
              Expanded(
                child: _LevelChip(
                  level: level,
                  selected: level.id == selectedId,
                  onTap: () => onSelect(level.id),
                ),
              ),
              // 末尾以外はチップ間にすき間を入れる。
              if (level.id != LevelService.levels.last.id)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

/// 難易度1つ分のチップ。選択中はグリーンで塗り、未選択は白＋枠線。
class _LevelChip extends StatelessWidget {
  final QuizLevel level;
  final bool selected;
  final VoidCallback onTap;
  const _LevelChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 「小学生（1〜3年）」→「小学生」のように、括弧前の短い名前だけ表示する。
    final shortLabel = level.label.split('（').first;
    return Material(
      color: selected ? AppColors.primaryGreen : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primaryGreen : AppColors.cardBeige,
              width: 1.5,
            ),
          ),
          child: Text(
            shortLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
