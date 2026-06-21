import 'package:shared_preferences/shared_preferences.dart';

/// クイズの難易度レベル（おこさまの がくねん の目安）。
///
/// [id] は永続化・API送信に使う番号（1〜3）。
/// [label] は画面に出すラベル、[hint] は Gemini に渡す難易度の指示文。
class QuizLevel {
  final int id;
  final String label;
  final String hint;
  const QuizLevel({
    required this.id,
    required this.label,
    required this.hint,
  });
}

/// クイズ難易度レベルを端末ローカルに永続保存するサービス。
///
/// [PointService] と同じく `shared_preferences` を使い、
/// キー `'quiz_level'` にレベル id（int）を読み書きする。
/// `flutter` に依存しない静的メソッドだけで構成し、画面側から手軽に呼べる。
///
/// 同期参照用に [currentId] のメモリキャッシュを持つ。
/// [load] / [save] のたびに更新するので、クイズ生成時など
/// await できない場面でも最新値を即座に参照できる。
class LevelService {
  /// 読み書きに使う SharedPreferences のキー。
  static const String _key = 'quiz_level';

  /// 用意した3段階の難易度。id 昇順で並べる。
  static const List<QuizLevel> levels = [
    QuizLevel(
      id: 1,
      label: 'ちいさめ（年少〜年長）',
      hint: 'とてもやさしく。ひらがな中心。選択肢の違いを大きく、直感で選べる。',
    ),
    QuizLevel(
      id: 2,
      label: 'ふつう（小1〜2）',
      hint: 'やさしい日本語。すなおな4択。',
    ),
    QuizLevel(
      id: 3,
      label: 'むずかしめ（小3〜4）',
      hint: '少し考える問題。語彙はやや高め。ただし低学年でも読める範囲。',
    ),
  ];

  /// 既定のレベル id（「ふつう（小1〜2）」）。
  static const int defaultId = 2;

  /// 現在のレベル id のメモリキャッシュ（同期参照用）。
  /// [load] / [save] のたびに更新される。初期値は既定レベル。
  static int currentId = defaultId;

  /// 保存済みのレベル id を読み込む。
  ///
  /// 未保存・不正値のときは既定値（[defaultId]）を返す。
  /// 読み込んだ値は [currentId] にも反映する。
  static Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    // 用意したレベルに無い値は既定値へ丸める。
    final id =
        (saved != null && levels.any((l) => l.id == saved)) ? saved : defaultId;
    currentId = id;
    return id;
  }

  /// レベル id を保存する。あわせて [currentId] も更新する。
  static Future<void> save(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, id);
    currentId = id;
  }

  /// id からレベルを引く。該当が無ければ既定レベルを返す。
  static QuizLevel byId(int id) {
    return levels.firstWhere(
      (l) => l.id == id,
      orElse: () => levels.firstWhere((l) => l.id == defaultId),
    );
  }
}
