import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';

/// 親が子どもにスマホを渡す前に表示する「お約束画面」。
/// 企画書 4-◆安全性への徹底配慮 に対応し、
/// クエスト開始前に必ず安全のお約束を確認してもらう。
///
/// [onStart] は「やくそくした！スタート！」を押したときに呼ばれる。
/// 画面内では Navigator を直接呼ばず、配線は統合担当に任せる。
class SafetyPledgeScreen extends StatelessWidget {
  /// お約束に同意してクエストを始めるときのコールバック。
  final VoidCallback onStart;

  const SafetyPledgeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreenDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const HatoppyAvatar(size: 88),
              const SizedBox(height: 16),
              const Text(
                'スマホをわたすまえに\nおやくそく',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'おとなのひとといっしょによんでね',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _PledgeCard(emoji: '🏃', text: 'はしらない'),
                      SizedBox(height: 14),
                      _PledgeCard(emoji: '👀', text: 'まえをみる'),
                      SizedBox(height: 14),
                      _PledgeCard(emoji: '🧑‍🤝‍🧑', text: 'おとなのそばにいる'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StartButton(onStart: onStart),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// お約束1項目を表すカード。絵文字＋やさしいひらがなで1つの約束を示す。
class _PledgeCard extends StatelessWidget {
  final String emoji;
  final String text;

  const _PledgeCard({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 下部に置く大きな丸ボタン。押すと [onStart] を呼ぶ。
class _StartButton extends StatelessWidget {
  final VoidCallback onStart;

  const _StartButton({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 22),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: const Text('やくそくした！スタート！'),
      ),
    );
  }
}
