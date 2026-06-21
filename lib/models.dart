/// おつかいクエストで使うデータモデル一式。
/// 実際のプロダクトでは商品マスタ・クイズDBから取得する想定だが、
/// デモ用にこのファイル内にサンプルデータとして直書きしている。
library models;

/// 1つの「おつかいミッション」を表すモデル。
/// 商品名・案内する棚エリア・地産地消クイズ・獲得できるバッジをまとめて持つ。
class ShoppingItem {
  final String id;
  final String name; // 商品名（例：近江米）
  final String area; // AIナビが提示する棚エリア（例：お米売り場）
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

/// 企画書 2-② の「地産地消・食育クイズ」の例文に合わせたサンプル5品目。
/// 滋賀県（平和堂のお膝元・琵琶湖）を意識した内容にしている。
const List<ShoppingItem> sampleItems = [
  ShoppingItem(
    id: 'rice',
    name: '近江米',
    area: 'お米売り場',
    emoji: '🌾',
    question: 'これは滋賀県の農家さんが琵琶湖をキレイに守るために\n工夫して作ったお米だぴ！どんな工夫かな？',
    choices: [
      '農薬や肥料をできるだけ減らして育てている',
      '毎日お水をたくさんあげている',
      '夜だけ育てている',
      '特別な透明な箱の中で育てている',
    ],
    correctIndex: 0,
    explanation: '正解！農薬や肥料を減らすことで、田んぼの水が琵琶湖に流れても\n環境にやさしくなるよう工夫されているんだぴ🌾',
    badgeName: '稲穂はとっぴー',
    badgeEmoji: '🌾',
  ),
  ShoppingItem(
    id: 'tomato',
    name: '地場野菜（トマト）',
    area: '野菜売り場',
    emoji: '🍅',
    question: '地場野菜のトマトは、琵琶湖のために\nどんな育て方をされているかな？',
    choices: [
      '農薬の量を決められた基準より減らして育てている',
      '海外から飛行機で運んでいる',
      '一年中ハウスの中で真っ暗にして育てている',
      '土を使わずに水だけで育てている',
    ],
    correctIndex: 0,
    explanation: '正解！「環境こだわり農産物」と呼ばれる、農薬や化学肥料を\n減らして琵琶湖を守る農法で作られているぴ🍅',
    badgeName: 'やさいはとっぴー',
    badgeEmoji: '🍅',
  ),
  ShoppingItem(
    id: 'milk',
    name: '地元牛乳',
    area: '乳製品売り場',
    emoji: '🥛',
    question: '地元の牧場でしぼられた牛乳が\nお店に届くまでの時間はどれくらいだと思う？',
    choices: [
      'しぼってから1〜2日くらいの新鮮なうちに届く',
      '1ヶ月くらいかけて船で届く',
      '一度凍らせてから届く',
      '牛さんがお店まで運んでくる',
    ],
    correctIndex: 0,
    explanation: '正解！地元の牧場だから、しぼりたての新鮮さのまま\nすぐにお店に並べられるんだぴ🥛',
    badgeName: 'ミルクはとっぴー',
    badgeEmoji: '🥛',
  ),
  ShoppingItem(
    id: 'egg',
    name: '地玉子',
    area: '卵売り場',
    emoji: '🥚',
    question: '地元の養鶏場の卵が新鮮な理由は\n産地とお店の距離が関係しているよ。なぜかな？',
    choices: [
      '近くで作られているので運ぶ時間が短くてすむから',
      '卵が自分で歩いてくるから',
      '冷凍してから解凍しているから',
      '卵の中身を入れ替えているから',
    ],
    correctIndex: 0,
    explanation: '正解！地産地消だから運ぶ距離が短く、新鮮なまま\nお店に届けられるんだぴ🥚',
    badgeName: 'たまごはとっぴー',
    badgeEmoji: '🥚',
  ),
  ShoppingItem(
    id: 'dressing',
    name: '地元ドレッシング',
    area: '調味料売り場',
    emoji: '🧂',
    question: 'このドレッシングは地元の野菜や果物を使うことで\nどんな良いことがあるかな？',
    choices: [
      '地元の農家さんを応援できて、新鮮な材料が使える',
      '味が全くしなくなる',
      '賞味期限がなくなる',
      '色が消えてしまう',
    ],
    correctIndex: 0,
    explanation: '正解！地元の食材を使うことで農家さんの応援になり、\n新鮮な美味しさも楽しめるんだぴ🧂',
    badgeName: 'ちょうみりょうはとっぴー',
    badgeEmoji: '🧂',
  ),
];

/// 「リストにない商品」を途中でスキャンしたとき（途中追加）に使うボーナス用ミッション。
/// 実際の商品名は JAN→平和堂商品管理番号→商品DB の連携が必要で今回は権限が無いため、
/// 商品名が分からなくても出せる「地産地消の一般クイズ」＋限定バッジを用意している。
const ShoppingItem bonusItem = ShoppingItem(
  id: 'bonus',
  name: 'お店でみつけた地元の食べもの',
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
