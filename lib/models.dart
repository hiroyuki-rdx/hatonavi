/// おつかいクエストで使うデータモデル一式。
/// 実際のプロダクトでは商品マスタ・クイズDBから取得する想定だが、
/// デモ用にこのファイル内にサンプルデータとして直書きしている。
library models;

/// 1つの「おつかいミッション」を表すモデル。
/// 商品名・案内する棚エリア・地産地消クイズ・獲得できるバッジをまとめて持つ。
class ShoppingItem {
  final String id;
  final String name; // 商品名（例：みずうみ農園の トマト）
  final String areaId; // 売り場マスタ(storeAreas)のキー（例：local_vegetables）
  final String area; // AIナビが提示する棚エリアの表示名/売り場名（例：地場野菜）
  final String emoji; // 商品アイコン代わりの絵文字
  final String question; // はとっぴーの地産地消クイズ
  final List<String> choices; // 4択
  final int correctIndex; // 正解のインデックス
  final String explanation; // 正解発表時にはとっぴーが話す豆知識
  final String badgeName; // 図鑑に並ぶ限定バッジ名
  final String badgeEmoji; // バッジの絵文字
  final String? janCode; // 本番でスキャン照合に使うJANコード（デモは未設定でも可）

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.areaId,
    required this.area,
    required this.emoji,
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    required this.badgeName,
    required this.badgeEmoji,
    this.janCode,
  });
}

/// 売り場マスタ（1区画）のモデル。
/// 店内マップ（`売り場マップ.pdf`）を開発時にデジタル化した固定データ。
class StoreArea {
  final String id; // 売り場ID（ShoppingItem.areaId と対応）
  final String label; // 売り場の表示名（例：地場野菜）
  final int pathIndex; // 一方向スイープ（入口→レジ）での並び順インデックス
  final double x; // マップ上のX座標（方角・矢印計算用。0..100、左→右が東）
  final double y; // マップ上のY座標（方角・矢印計算用。0..100、下→上が北）

  const StoreArea(
    this.id,
    this.label,
    this.pathIndex, {
    this.x = 0.0,
    this.y = 0.0,
  });
}

/// 店内の売り場マスタ。
/// `売り場マップ.pdf` を開発時にデジタル化したもので、pathIndex は
/// 入口(スタート)からレジまでを一方向にめぐる「一方向スイープ順」を表す。
/// AIナビはこの順番を基準に、リスト商品をなるべく一筆書きで回れるよう案内する。
///
/// x,y は方角計算用の座標。`売り場マップ.pdf` の各区画の中心を実測して引いたもの
/// （PDFを画像化し各長方形の重心を計測 → 0..100 に正規化、Y反転）。近似ではなく実測値。
/// x=左→右で 0..100、y=下→上で 0..100。原点は左下、x が東/右、y が北/上。
/// NavigationScreen で「現在地→次売り場」の方位角(bearing)を求めるのに使う。
/// 同名で複数置かれている区画（お魚・野菜・果物は地図上に2つ）は、
/// スタート/レジ動線から到達しやすい側の1つを代表座標として採用している。
const Map<String, StoreArea> storeAreas = {
  'start': StoreArea('start', 'スタート', 0, x: 86.8, y: 6.5),
  'local_vegetables': StoreArea('local_vegetables', '地場野菜', 1, x: 76.4, y: 10.8),
  // 右壁を下→上にめぐる順：地場野菜(1) → 果物(2) → 野菜(3) → お魚(4)。
  // 旧データは野菜(2)→果物(3)で物理配置と逆だったため入れ替え。
  'fruits': StoreArea('fruits', '果物', 2, x: 85.5, y: 20.3),
  'vegetables': StoreArea('vegetables', '野菜', 3, x: 84.8, y: 53.7),
  'fish': StoreArea('fish', 'お魚', 4, x: 89.1, y: 92.8),
  'meat': StoreArea('meat', 'お肉', 5, x: 50.5, y: 93.1),
  'tempura': StoreArea('tempura', '天ぷら', 6, x: 10.8, y: 93.1),
  'side_dish': StoreArea('side_dish', '惣菜', 7, x: 9.6, y: 79.7),
  'dairy': StoreArea('dairy', '乳製品', 8, x: 25.1, y: 68.8),
  'yogurt': StoreArea('yogurt', 'ヨーグルト', 9, x: 9.1, y: 65.6),
  'frozen': StoreArea('frozen', '冷凍食品', 10, x: 34.4, y: 68.8),
  'drink': StoreArea('drink', '飲料水', 11, x: 43.7, y: 68.8),
  'miso': StoreArea('miso', '味噌汁', 12, x: 53.0, y: 68.8),
  'instant': StoreArea('instant', '即席食品', 13, x: 62.3, y: 68.8),
  'tofu': StoreArea('tofu', '豆腐', 14, x: 71.6, y: 68.8),
  'icecream': StoreArea('icecream', 'アイスクリーム', 15, x: 25.1, y: 37.6),
  'beer': StoreArea('beer', 'ビール', 16, x: 34.4, y: 37.6),
  'sake': StoreArea('sake', '日本酒', 17, x: 43.7, y: 37.6),
  'sweets': StoreArea('sweets', 'お菓子', 18, x: 53.0, y: 37.6),
  'kitchen': StoreArea('kitchen', '台所用品', 19, x: 62.3, y: 37.6),
  'garbage': StoreArea('garbage', 'ゴミ袋', 20, x: 71.6, y: 37.6),
  'egg': StoreArea('egg', '卵', 21, x: 9.1, y: 58.1),
  'bread': StoreArea('bread', 'パン', 22, x: 9.3, y: 35.6),
  'self_checkout': StoreArea('self_checkout', 'セルフレジ', 23, x: 18.8, y: 11.8),
  'cashier': StoreArea('cashier', 'レジ', 24, x: 47.7, y: 15.6),
};

/// 地産地消・食育クイズつきのサンプル8品目。
/// 商品名は架空ブランド＋一般名で、特定の実産地・実在商品には依存しない。
/// クイズは「地元でとれたものは新鮮で、農家さん・牧場さんの応援になる」という
/// 食育メッセージを、低学年向けにひらがな多めでやさしく出題している。
const List<ShoppingItem> sampleItems = [
  ShoppingItem(
    id: 'vegetables',
    name: 'みずうみ農園の トマト',
    areaId: 'local_vegetables',
    area: '地場野菜',
    emoji: '🍅',
    question: 'ちかくの はたけで とれた トマトだぴ！\nとれたてが おみせに ならぶと、どんな いいことが あるかな？',
    choices: [
      'はこぶ じかんが みじかくて しんせんなまま とどく',
      'とおくへ いくほど あまくなる',
      'いろが きえて しろくなる',
      'よるだけ そだてている',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの はたけだと はこぶ じかんが みじかいから、\nしんせんなまま おみせに ならべられるんだぴ🍅',
    badgeName: 'やさいはとっぴー',
    badgeEmoji: '🍅',
  ),
  ShoppingItem(
    id: 'milk',
    name: 'あおぞら牧場の ぎゅうにゅう',
    areaId: 'dairy',
    area: '乳製品',
    emoji: '🥛',
    question: 'ちかくの ぼくじょうで しぼった ぎゅうにゅうだぴ！\nちかくで つくると、どうして うれしいのかな？',
    choices: [
      'しぼりたての しんせんさで はやく とどけられる',
      'ふねで いっかげつ かけて とどく',
      'うしさんが おみせまで はこんでくる',
      'こおらせてからでないと のめない',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの ぼくじょうだから、しぼりたての\nしんせんさの まま はやく とどけられるんだぴ🥛',
    badgeName: 'ぎゅうにゅうはとっぴー',
    badgeEmoji: '🥛',
  ),
  ShoppingItem(
    id: 'egg',
    name: 'やまびこ農園の たまご',
    areaId: 'egg',
    area: '卵',
    emoji: '🥚',
    question: 'ちかくの のうえんで うまれた たまごだぴ！\nちかくで とれた たまごは、どうして しんせんなのかな？',
    choices: [
      'はこぶ きょりが みじかいから しんせんなまま とどく',
      'たまごが じぶんで あるいてくるから',
      'なんかいも こおらせているから',
      'なかみを いれかえているから',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくで とれた たまごは はこぶ きょりが\nみじかいから、しんせんなまま とどけられるんだぴ🥚',
    badgeName: 'たまごはとっぴー',
    badgeEmoji: '🥚',
  ),
  ShoppingItem(
    id: 'yogurt',
    name: 'あおぞら牧場の ヨーグルト',
    areaId: 'yogurt',
    area: 'ヨーグルト',
    emoji: '🥣',
    question: 'ちかくの ぼくじょうの ぎゅうにゅうから つくった\nヨーグルトだぴ！ちかくの ものを かうと どんな いいことが あるかな？',
    choices: [
      'ぼくじょうの ひとの おうえんに なる',
      'あじが まったく しなくなる',
      'いつまでも くさらなくなる',
      'いろが きえてしまう',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの ものを かうと、つくっている\nぼくじょうの ひとの おうえんに なるんだぴ🥣',
    badgeName: 'ヨーグルトはとっぴー',
    badgeEmoji: '🥣',
  ),
  ShoppingItem(
    id: 'bread',
    name: 'こむぎ工房の パン',
    areaId: 'bread',
    area: 'パン',
    emoji: '🍞',
    question: 'ちかくの おみせで やいた パンだぴ！\nやきたての パンが はやく ならぶのは、なぜかな？',
    choices: [
      'ちかくで やくから やきたてを すぐ ならべられる',
      'そとの くにから ふねで はこんでくるから',
      'いちど こおらせているから',
      'パンが とんでくるから',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくで やくから、やきたての おいしさを\nすぐに おみせへ ならべられるんだぴ🍞',
    badgeName: 'パンはとっぴー',
    badgeEmoji: '🍞',
  ),
  ShoppingItem(
    id: 'meat',
    name: 'みのり牧場の おにく',
    areaId: 'meat',
    area: 'お肉',
    emoji: '🥩',
    question: 'ちかくの ぼくじょうで そだてた おにくだぴ！\nちかくの おにくを えらぶと、どんな いいことが あるかな？',
    choices: [
      'そだてた ぼくじょうの ひとを おうえんできる',
      'はこぶほど あじが こくなる',
      'ずっと ふえつづける',
      'いろが にじんでしまう',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの おにくを かうと、たいせつに\nそだてた ぼくじょうの ひとの おうえんに なるんだぴ🥩',
    badgeName: 'おにくはとっぴー',
    badgeEmoji: '🥩',
  ),
  ShoppingItem(
    id: 'fish',
    name: 'みなと水産の おさかな',
    areaId: 'fish',
    area: 'お魚',
    emoji: '🐟',
    question: 'ちかくの みなとで とれた おさかなだぴ！\nちかくで とれた おさかなが しんせんなのは なぜかな？',
    choices: [
      'みなとから ちかいから はやく とどく',
      'おさかなが じぶんで およいでくるから',
      'なんども こおらせるから',
      'いろを ぬっているから',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの みなとから はやく とどくから、\nしんせんな おさかなを たべられるんだぴ🐟',
    badgeName: 'おさかなはとっぴー',
    badgeEmoji: '🐟',
  ),
  ShoppingItem(
    id: 'fruits',
    name: 'ひだまり農園の くだもの',
    areaId: 'fruits',
    area: '果物',
    emoji: '🍎',
    question: 'ちかくの はたけで そだった くだものだぴ！\nちかくで とれた くだものを えらぶと、どんな いいことが あるかな？',
    choices: [
      'しんせんで、はたけの ひとの おうえんにも なる',
      'とおくへ いくほど あまくなる',
      'たねが なくなる',
      'よるしか たべられなくなる',
    ],
    correctIndex: 0,
    explanation: 'せいかい！ちかくの くだものは しんせんで、そだてた\nはたけの ひとの おうえんにも なるんだぴ🍎',
    badgeName: 'くだものはとっぴー',
    badgeEmoji: '🍎',
  ),
];

/// 「リストにない商品」を途中でスキャンしたとき（途中追加）に使うボーナス用ミッション。
/// 実際の商品名は JAN→平和堂商品管理番号→商品DB の連携が必要で今回は権限が無いため、
/// 商品名が分からなくても出せる「地産地消の一般クイズ」＋限定バッジを用意している。
/// areaId は売り場マスタ外を表す 'unknown'（リスト外スキャン用）。
const ShoppingItem bonusItem = ShoppingItem(
  id: 'bonus',
  name: 'お店でみつけた地元の食べもの',
  areaId: 'unknown',
  area: 'リストにない商品',
  emoji: '🛒',
  question: 'お店には、近くの畑や牧場でとれた「地元の食べもの」が\nたくさんあるよ。地元のものを買うと、どんないいことがあるかな？',
  choices: [
    '近くで作られているから新鮮で、農家さんの応援にもなる',
    '遠くから運ぶほどおいしくなる',
    '地元のものはお店では買えないことになっている',
    '色がにじんでしまう',
  ],
  correctIndex: 0,
  explanation: '正解！地元でとれたものは運ぶ時間がみじかくて新鮮。\n買うと地元の農家さんや牧場の応援にもなるんだぴ🛒',
  badgeName: 'はっけんはとっぴー',
  badgeEmoji: '🛒',
);

/// 移動中の「危険箇所アラート」のサンプル文言。
/// 企画書 4-◆安全性への徹底配慮 に対応。
const List<String> hazardAlerts = [
  '⚠️ この先は床がすべりやすい総菜コーナーです。\n足元に気をつけてゆっくり歩こうね！',
  '⚠️ カートの往来が多い交差点に近づいています。\n右左をよく見て進もう！',
];
