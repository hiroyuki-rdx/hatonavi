import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'level_service.dart';

/// Gemini を Vercel Function（`/api/gemini`）経由で呼ぶサービス。
///
/// APIキーはフロントに持たず、サーバー側の環境変数で秘匿する。
/// ネットワーク失敗・キー未設定・不正レスポンス時は **null を返し**、
/// 呼び出し側が固定データ（[sampleItems] のクイズ・選択順）にフォールバックする。
/// これにより、ネットや Gemini の状態に関係なくデモは必ず最後まで動く。
class GeminiService {
  /// 同一オリジンの Vercel Function を叩く（ローカル実行では存在せず null フォールバック）。
  static Uri get _endpoint => Uri.base.resolve('/api/gemini');
  static const Duration _timeout = Duration(seconds: 8);

  /// 商品を回る「順番」だけを提案する。物理ルートは生成しない。
  /// 戻り値は item の id の並び。失敗・不正時は null。
  static Future<List<String>?> suggestVisitOrder(List<ShoppingItem> items) async {
    try {
      final resp = await http
          .post(
            _endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mode': 'order',
              'items': [
                for (final it in items)
                  {'id': it.id, 'name': it.name, 'areaId': it.areaId}
              ],
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body);
      final order =
          (data['order'] as List?)?.map((e) => e.toString()).toList();
      if (order == null || order.isEmpty) return null;
      // ハルシネーション対策：入力idと過不足なく一致するときだけ採用。
      final ids = items.map((e) => e.id).toSet();
      final filtered = order.where(ids.contains).toList();
      if (filtered.toSet().length != ids.length) return null;
      return filtered;
    } catch (_) {
      return null;
    }
  }

  /// 商品のクイズを生成する。失敗・不正時は null（固定クイズへフォールバック）。
  ///
  /// [level] は子どもの年齢/学年に合わせた難易度（1〜3、既定は2）。
  /// payload にレベル番号とそのレベルの指示文（levelHint）を載せ、
  /// サーバー側のプロンプトで言葉づかい・難しさを調整する。
  static Future<GeneratedQuiz?> generateQuiz(
    ShoppingItem item, {
    int level = LevelService.defaultId,
  }) async {
    try {
      // レベルに対応する難易度の指示文を取得（不正な id は既定レベルへ丸められる）。
      final levelHint = LevelService.byId(level).hint;
      final resp = await http
          .post(
            _endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mode': 'quiz',
              'name': item.name,
              'area': item.area,
              'level': level,
              'levelHint': levelHint,
              // ハルシネーション対策：手書きの「正しい事実」を渡し、これだけを根拠に
              // 出題させる（AIに事実を発明させない＝グラウンディング）。
              'fact': item.explanation,
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final q = data['question'];
      final choices =
          (data['choices'] as List?)?.map((e) => e.toString()).toList();
      final ci = data['correctIndex'];
      final exp = data['explanation'];
      // ハルシネーション対策のバリデーション。
      if (q is! String || q.trim().isEmpty) return null;
      if (choices == null || choices.length != 4) return null;
      if (choices.any((c) => c.trim().isEmpty)) return null;
      // 選択肢の重複はNG（4つすべて異なること）。
      if (choices.map((c) => c.trim()).toSet().length != 4) return null;
      if (ci is! int || ci < 0 || ci > 3) return null;
      if (exp is! String || exp.trim().isEmpty) return null;
      return GeneratedQuiz(
        question: q,
        choices: choices,
        correctIndex: ci,
        explanation: exp,
      );
    } catch (_) {
      return null;
    }
  }

  /// 完了画面の「おうちのひとへ：きょうのまなび」用サマリを生成する。
  ///
  /// 今日クイズで学んだ商品（name / area / explanation）だけを根拠に、
  /// 保護者向けの温かいふりかえり文（2〜3文）を作る。
  /// ハルシネーション対策として、手書きの「正しい事実」(explanation) だけを渡す。
  /// 失敗・不正・キー未設定・空リスト時は null を返し、画面側が固定文へフォールバックする。
  static Future<String?> generateParentSummary(List<ShoppingItem> items) async {
    if (items.isEmpty) return null;
    try {
      final resp = await http
          .post(
            _endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mode': 'summary',
              'items': [
                for (final it in items)
                  {
                    'name': it.name,
                    'area': it.area,
                    // グラウンディング根拠（AIに事実を発明させない）。
                    'explanation': it.explanation,
                  }
              ],
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final summary = data['summary'];
      if (summary is! String || summary.trim().isEmpty) return null;
      return summary.trim();
    } catch (_) {
      return null;
    }
  }
}

/// Gemini が生成したクイズ。フォールバック時は使わず、[ShoppingItem] の固定値を使う。
class GeneratedQuiz {
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  const GeneratedQuiz({
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });
}
