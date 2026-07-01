// Vercel Serverless Function — Gemini プロキシ
//
// 目的: GEMINI_API_KEY を**サーバー側の環境変数で秘匿**し、フロント(Flutter Web)に出さない。
// フロントは同一オリジンの /api/gemini を叩くだけ。CORS・キー管理をここで吸収する。
//
// mode:
//   "order"   … 買い物リスト(items)を店内を効率よく回れる巡回順に並べ替え → {"order":[id,...]}
//   "quiz"    … 商品名から食育クイズを1問生成 → {question, choices[4], correctIndex, explanation}
//   "summary" … 今日学んだ商品(name/area/explanation)から保護者向けサマリを1つ生成 → {"summary":"..."}
//
// 失敗時はエラーを返し、フロント側が固定データ(models.dart)にフォールバックする
// （デモがネットワークやキー未設定で止まらない設計）。

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'GEMINI_API_KEY not set' });

  let body = req.body;
  if (typeof body === 'string') {
    try { body = JSON.parse(body); } catch (_) { body = {}; }
  }
  body = body || {};

  let prompt;
  let temperature = 0.7; // 既定（巡回順など）。quizは事実ベースなので後で下げる。
  if (body.mode === 'order') {
    // 物理的な通路ルートではなく、店内を効率よく回れる「巡回順」に並べ替える。
    const items = Array.isArray(body.items) ? body.items : [];
    prompt =
      '次の買い物リストを、物理的な通路ルートではなく、スーパーの店内を効率よく回れる「巡回順」に並べ替えてください。\n' +
      'リスト(JSON): ' + JSON.stringify(items) + '\n' +
      '出力は {"order":["id",...]} のJSONのみ。' +
      'idは入力のidだけを使い、各1回ずつ含めること。';
  } else if (body.mode === 'quiz') {
    const name = String(body.name || '商品');
    const area = String(body.area || '');
    // 子どもの年齢/学年に合わせた難易度。level(1-3)とlevelHint(指示文)を反映する。
    // 値が無い・範囲外のときは「ふつう」相当(2)へフォールバックする。
    const level = [1, 2, 3].includes(body.level) ? body.level : 2;
    const levelHint = String(body.levelHint || 'やさしい日本語。すなおな4択。');
    // ハルシネーション対策：渡された「正しい事実」だけを根拠に出題させる。
    const fact = String(body.fact || '地元でとれた食べものは新鮮で、地元の生産者の応援になる。');
    temperature = 0.3; // 事実ベースなので低めにして創作（暴走）を抑える
    prompt =
      'あなたは子ども向けの食育クイズ作成者です。次の「正しい事実」だけを根拠に、4択クイズを1問作ってください。\n' +
      '正しい事実: ' + fact + '\n' +
      '商品名: ' + name + '（売場: ' + area + '）。テーマは地産地消・食育。\n' +
      '難易度レベル: ' + level + '。' + levelHint + '\n' +
      'ルール:\n' +
      '・「正しい事実」に書かれていないことは出題しない（推測・創作、むずかしい固有名詞や数値の断定は禁止）。\n' +
      '・4つの選択肢のうち、ちょうど1つだけが「正しい事実」に合う正解。残り3つは明らかなまちがいだが意地悪でない。\n' +
      '・子どもにこわい・不適切・差別的な内容は禁止。\n' +
      '・問題文/選択肢/解説は難易度レベルに合わせた言葉づかいにする。\n' +
      '出力は {"question":"問題文","choices":["選択肢1","選択肢2","選択肢3","選択肢4"],' +
      '"correctIndex":0,"explanation":"正解の理由（事実に基づき短く）"} のJSONのみ。' +
      'choicesはちょうど4つ・重複なし、correctIndexは正解の番号(0-3の整数)。';
  } else if (body.mode === 'summary') {
    // 完了画面の「おうちの人へ：きょうのまなび」用サマリ。
    // 子どもが今日クイズで学んだ商品リスト(name/area/explanation)だけを根拠にする。
    const learned = Array.isArray(body.items) ? body.items : [];
    // 各項目を「正しい事実」つきで列挙。explanation がグラウンディング根拠。
    const lines = learned
      .map((it) => {
        const name = String((it && it.name) || '商品');
        const area = String((it && it.area) || '');
        const fact = String((it && it.explanation) || '');
        return '・' + name + '（売場: ' + area + '）／学んだこと: ' + fact;
      })
      .join('\n');
    // 事実ベースなので低めにして創作（暴走）を抑える。order(0.7)より低く、quiz(0.3)より少しだけ自由度を持たせる。
    temperature = 0.4;
    prompt =
      'あなたは、子どものおつかい学習に寄りそうアシスタントです。\n' +
      '次に挙げる「今日子どもがクイズで学んだこと」だけを根拠に、保護者（大人）向けの温かいふりかえりメッセージを書いてください。\n' +
      '今日学んだこと:\n' + lines + '\n' +
      'ルール:\n' +
      '・上の「学んだこと」に書かれていないことは書かない（推測・創作、むずかしい固有名詞や数値の断定は禁止）。\n' +
      '・断定的なウソや誇張をしない。事実に忠実にまとめる。\n' +
      '・読み手は保護者（大人）。子ども向けのやさしすぎる言い回しやひらがなの多用は避け、常用漢字をふつうに使った、ていねいで自然な大人向けの日本語で書く。\n' +
      '・子どもをほめ、家庭での会話のきっかけになるような前向きな締めにする。\n' +
      '・全体で2〜3文の、ひとつづきの自然な文章にする（箇条書きにしない）。\n' +
      '・「おうちの人へ」などの宛名や見出しは付けず、本文だけを書く。\n' +
      '出力は {"summary":"本文"} のJSONのみ。';
  } else {
    return res.status(400).json({ error: 'bad mode' });
  }

  try {
    const url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=' +
      apiKey;
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', temperature },
      }),
    });
    if (!r.ok) return res.status(502).json({ error: 'gemini_http_' + r.status });
    const data = await r.json();
    const text =
      data &&
      data.candidates &&
      data.candidates[0] &&
      data.candidates[0].content &&
      data.candidates[0].content.parts &&
      data.candidates[0].content.parts[0] &&
      data.candidates[0].content.parts[0].text;
    if (!text) return res.status(502).json({ error: 'no_text' });
    let parsed;
    try { parsed = JSON.parse(text); } catch (_) { return res.status(502).json({ error: 'parse_error' }); }
    return res.status(200).json(parsed);
  } catch (e) {
    return res.status(502).json({ error: String(e) });
  }
};
