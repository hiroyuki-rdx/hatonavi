# プロジェクト概要

**はとナビ（鳩ナビ）おつかいクエスト** — 親子の買い物を知育エンタメ化する **Flutter Web デモ**。
子どもが店内で商品を探し（おつかいクエスト）、食育クイズに答えながらポイント／シールを集める。平和堂×ソフトバンクのハッカソン向けプロトタイプ。

- 独立した Web デモ（ピピットセルフ等との外部連携は未実装）。
- AI（Gemini 2.5 Flash）は **巡回順の提案** と **クイズ生成** の2用途のみ。いずれも検証＋固定データへのフォールバック前提で、AI が落ちても体験は壊れない設計。
- 詳細仕様・背景は `docs/`（`仕様書.md` / `要件定義書.md` / `プロダクト詳細レポート.md` 等）を参照。

# ビルド・実行・デプロイ

```bash
flutter run -d chrome                       # ローカル起動（/api は無いので AI はフォールバック動作）
flutter build web --no-tree-shake-icons     # ローカルでの Web ビルド（権限登録済みコマンド）
flutter analyze                             # 静的解析
flutter test                                # テスト（test/widget_test.dart）
```

- **デプロイは Vercel**（GitHub 連携で push 時に自動デプロイ）。ビルド／出力設定は `vercel.json` に定義済み。手順は `docs/デプロイ手順.md` 参照。
- Vercel 側のビルドコマンドは `vercel.json` 内で `flutter build web --release`（Flutter SDK を clone してから実行）。出力は `build/web`。
- **方位センサー・カメラは HTTPS でしか動かない**。実機でのセンサー／カメラ確認は Vercel の `https://` URL で行う（ローカル `http://` では不可）。

# ディレクトリ構成

```
lib/
  main.dart                 アプリ起点（HatoNaviApp → HomeScreen）
  models.dart               データモデル＋固定データ（商品・売場・固定クイズ等。AI失敗時のフォールバック元）
  theme.dart                アプリ全体テーマ
  screens/                  画面（home / shopping_list / navigation / compass / quiz / point / sticker / safety_pledge）
  services/                 ロジック層
    gemini_service.dart     /api/gemini 経由で Gemini を呼ぶ。失敗・不正時は null を返し固定データへフォールバック
    compass_service.dart    方位センサー
    motion_service.dart     走行検知（歩行中操作の抑止）
    speech_service.dart     音声読み上げ（危険アラート等）
    point_service.dart      ポイント管理
    level_service.dart      難易度レベル（1〜3）管理
  widgets/                  共通ウィジェット（hatoppy_widget / sticker_ticket）
api/
  gemini.js                 Vercel サーバーレス関数。GEMINI_API_KEY を秘匿し Gemini をプロキシ（mode: order / quiz）
web/                        index.html・manifest.json・アイコン等（Flutter Web 標準構成）
docs/                       仕様・要件・デプロイ手順・引き継ぎ・既知の課題（.md）
test/                       widget_test.dart
```

- `android/ ios/ macos/ linux/ windows/` はネイティブ生成物（このプロジェクトでは未使用）。`build/` `.dart_tool/` は生成物で `.gitignore` 済み。

# コーディング規約

- `analysis_options.yaml` は `package:flutter_lints/flutter.yaml` を include（カスタムルール追加・無効化なし＝Flutter 推奨 lint をそのまま適用）。
- 変更後は `flutter analyze` でクリーンであることを確認する。

# 主要依存パッケージ

`pubspec.yaml` より（Dart SDK `^3.12.2`）:

- `http` — `/api/gemini`（Vercel Function）への HTTP 呼び出し。
- `mobile_scanner` — JAN コードのスキャン（商品を「みつけた！」合図）。
- `shared_preferences` — ローカル状態の永続化。
- `cupertino_icons` — アイコン。
- dev: `flutter_lints`。

# 注意点

- **AI のキー管理**: `GEMINI_API_KEY` は Vercel の環境変数で秘匿し、フロントには出さない。フロントは同一オリジンの `/api/gemini` を叩くだけ（`api/gemini.js` がプロキシ）。ローカル実行では `/api` が存在しないため AI は常にフォールバックする。
- **ハルシネーション対策**: クイズ生成は手書きの「正しい事実」を渡してグラウンディングし、`gemini_service.dart` 側で選択肢数・重複・正解インデックス等を検証。巡回順は入力 id と過不足なく一致するときのみ採用。崩れたら固定データへフォールバック。
- **Web 固有の留意点**: 方位センサー／カメラは HTTPS 必須。iOS Safari ではセンサー許可ポップアップが出る／音声はユーザー操作起点でしか鳴らない等の制約あり。詳細は `docs/既知の課題.md` 参照。
- **`build/web` を公開対象とするデプロイ構成**。`vercel.json` の `rewrites` で `/api/` 以外を `index.html` にフォールバック（SPA ルーティング）。
- PDF（`Step3に向けて.pdf` 等）は補助資料。コードの正は `lib/` と `docs/*.md`。
