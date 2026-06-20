import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'navigation_screen.dart';

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

  Future<void> _onCalculateRoute() async {
    if (_selectedIds.isEmpty) return;

    // ソフトバンクAIが最適ルートを計算している様子を演出するローディング。
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: _RouteCalculatingCard(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    Navigator.of(context).pop(); // ローディングダイアログを閉じる

    final selectedItems =
        sampleItems.where((item) => _selectedIds.contains(item.id)).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(items: selectedItems),
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
              'AIがお店の中の最短ルートを考えるよ！',
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
                      : 'AIルートを計算する（${_selectedIds.length}件）',
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
            'AIが店内の最適ルートを\n計算しているよ…',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
        ],
      ),
    );
  }
}
