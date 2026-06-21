import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/gemini_service.dart';
import 'navigation_screen.dart';
import 'safety_pledge_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _selectedIds = {};

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// 売り場マスタの pathIndex（入口→レジの一方向スイープ順）を返す。
  /// マスタに無い areaId は最後尾扱い（9999）にして後戻りを防ぐ。
  int _pathIndexOf(ShoppingItem item) => storeAreas[item.areaId]?.pathIndex ?? 9999;

  /// ローカル基本順：選択商品を pathIndex 昇順で並べる。
  /// 売り場の並び通りに進むので、必ず後戻りしない巡回順になる。
  List<ShoppingItem> _localOrder(List<ShoppingItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) => _pathIndexOf(a).compareTo(_pathIndexOf(b)));
    return sorted;
  }

  /// 回遊性の指標：連続する2品で pathIndex が前より小さくなった（＝後戻りした）回数。
  /// 小さいほど一筆書きに近く、回遊（行ったり来たり）が少ない。
  int _backtrackCount(List<ShoppingItem> list) {
    var count = 0;
    for (var i = 1; i < list.length; i++) {
      if (_pathIndexOf(list[i]) < _pathIndexOf(list[i - 1])) count++;
    }
    return count;
  }

  Future<void> _onCalculateRoute() async {
    if (_selectedIds.isEmpty) return;

    // AIがまわる順番を考えている様子を演出するローディング。
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: _RouteCalculatingCard(),
      ),
    );

    final selectedItems =
        sampleItems.where((item) => _selectedIds.contains(item.id)).toList();

    // ローカル基本順（売り場の並び通り＝必ず後戻りしない）を先に用意しておく。
    final localOrder = _localOrder(selectedItems);

    // 演出を見せつつ、裏で AI に巡回順（商品idの並び）を尋ねる（最低1.2秒は表示）。
    // 失敗・不正・キー未設定時は null が返り、ローカル基本順にフォールバックする。
    final aiFuture = GeminiService.suggestVisitOrder(selectedItems);
    await Future.delayed(const Duration(milliseconds: 1200));
    final aiIds = await aiFuture;

    if (!mounted) return;
    Navigator.of(context).pop(); // ローディングダイアログを閉じる

    // 既定はローカル基本順。AI提案が回遊性で勝る（同点含む）ときだけ採用する。
    var orderedItems = localOrder;
    if (aiIds != null) {
      // id→商品 のマップを作り、AIが返した順に並べ替える（null安全に欠落をスキップ）。
      final byId = {for (final it in selectedItems) it.id: it};
      final aiOrder = [
        for (final id in aiIds)
          if (byId[id] != null) byId[id]!,
      ];
      // 回遊性ガード：AI順の後戻り回数がローカル順以下なら、AI順を採用。
      // 全商品を漏れなく含む場合のみ採用（欠落・重複時はローカル順を守る）。
      if (aiOrder.length == selectedItems.length &&
          _backtrackCount(aiOrder) <= _backtrackCount(localOrder)) {
        orderedItems = aiOrder;
      }
    }

    // 巡回順の確定後はいきなりナビへ進まず、まず安全のお約束画面を挟む。
    // 「やくそくした！スタート！」を押したら NavigationScreen へ置き換え遷移する。
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pledgeContext) => SafetyPledgeScreen(
          onStart: () {
            Navigator.of(pledgeContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => NavigationScreen(items: orderedItems),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('かいものリストをえらぼう')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: const Text(
              '今日かいたいものをタップしてね。\n'
              'AIがまわる順番を考えるよ！',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sampleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = sampleItems[index];
                final selected = _selectedIds.contains(item.id);
                return _ItemTile(
                  emoji: item.emoji,
                  name: item.name,
                  area: item.area,
                  selected: selected,
                  onTap: () => _toggle(item.id),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty ? null : _onCalculateRoute,
                child: Text(
                  _selectedIds.isEmpty
                      ? '1つ以上えらんでね'
                      : 'おつかいの順番をきめる（${_selectedIds.length}件）',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String emoji;
  final String name;
  final String area;
  final bool selected;
  final VoidCallback onTap;

  const _ItemTile({
    required this.emoji,
    required this.name,
    required this.area,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardBeige : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accentOrange : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    area,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.accentOrange : Colors.black26,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCalculatingCard extends StatelessWidget {
  const _RouteCalculatingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGreen),
          SizedBox(height: 18),
          Text(
            'AIがまわる順番を\n考えているよ…',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
        ],
      ),
    );
  }
}
