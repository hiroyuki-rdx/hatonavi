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
      label: '未就学（〜6さい）',
      hint: 'とてもやさしく。ぜんぶ ひらがな。みじかい文。選択肢は3〜4語で、正解とのちがいがはっきりわかるように。',
    ),
    QuizLevel(
      id: 2,
      label: '小学生（1〜3年）',
      hint: 'やさしい日本語。小学校 低〜中学年向け。すなおな4択。',
    ),
    QuizLevel(
      id: 3,
      label: '高学年（4〜6年）',
      hint: '小学校 高学年（4〜6年）向け。ひらがなだけにせず、高学年で習う常用漢字を'
          'ふつうに使う（例：新鮮・鮮度・輸送・距離・生産者・地産地消・旬・流通・産地）。'
          'ふりがなは付けない。幼い言い回し（「〜だぴ」調の甘い説明や過度なひらがな）は避け、'
          '理由や仕組みを考えさせる問い方にする。語彙・文はやや高め・説明的でよい。'
          'ただし「正しい事実」に書かれていないことは足さず、難解な専門用語・数値の断定・'
          '下品な表現はしない。',
    ),
  ];

  /// 既定のレベル id（「小学生（1〜3年）」）。
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
