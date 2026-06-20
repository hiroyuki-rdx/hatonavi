import 'package:shared_preferences/shared_preferences.dart';

/// ポイントをスマホ内（端末ローカル）に永続保存するサービス。
///
/// `shared_preferences` を使い、キー `'total_points'` に
/// 累計ポイントを int として読み書きする。
/// 画面担当（A）はこのクラスの静的メソッドを通じてポイントを操作する。
class PointService {
  /// 読み書きに使う SharedPreferences のキー。
  static const String _totalKey = 'total_points';

  /// シール交換に必要な累計ポイント。
  /// 画面側でこの定数を参照して「あと何ポイントでシール交換」を表示する。
  static const int stickerThreshold = 10;

  /// 累計ポイントを読み込んで返す。
  ///
  /// 一度も保存されていない場合は 0 を返す。
  static Future<int> loadTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey) ?? 0;
  }

  /// 指定したポイントを累計に加算して保存する。
  ///
  /// 現在の累計を読み込み、[points] を足した値を書き戻す。
  static Future<void> add(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalKey) ?? 0;
    await prefs.setInt(_totalKey, current + points);
  }
}
