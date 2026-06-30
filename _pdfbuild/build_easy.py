# -*- coding: utf-8 -*-
"""やさしいアプリ説明 markdown -> PDF（余白多め・大きめ・たとえ話ボックス）。"""
import os, sys, json, subprocess, shutil
import build  # reuse fetch_libs, find_chrome, HTML_TMPL, BUILD

PROJ = build.PROJ
MD_PATH = os.path.join(PROJ, "docs", "発表_開発解説", "やさしいアプリ説明_鳩ナビ.md")
OUT_FINAL = os.path.join(PROJ, "docs", "発表_開発解説", "鳩ナビ_やさしい説明.pdf")
OUT_TMP = os.path.join(build.BUILD, "easy_out.pdf")

CSS_EASY = r"""
:root{ --green:#2E7D5B; --green2:#1F5A40; --orange:#FF9B42; --warm:#FFF6E3;
       --line:#e7dcc6; --ink:#33312e; }
*{ box-sizing:border-box; }
body{
  font-family:"Yu Gothic","YuGothic","Meiryo","Hiragino Kaku Gothic ProN",sans-serif;
  color:var(--ink); line-height:2.0; font-size:12.5pt; margin:0;
  -webkit-print-color-adjust:exact; print-color-adjust:exact;
}
#content{ max-width:172mm; margin:0 auto; padding:6mm 4mm; }

/* タイトルページ */
#content > h1:first-child{
  page-break-before:avoid; text-align:center; font-size:30pt; color:var(--green2);
  border:none; margin:34mm 0 0; line-height:1.35;
}
#content > h1:first-child + h2{
  text-align:center; font-size:16pt; color:var(--orange); border:none;
  margin:6px 0 0; padding:0;
}

/* セクション見出し（各ページ） */
h1{ page-break-before:always; font-size:21pt; color:var(--green2);
    border-bottom:4px solid var(--green); padding-bottom:8px; margin:0 0 18px; }
h2{ font-size:15pt; color:var(--green2); margin:22px 0 8px;
    padding-left:10px; border-left:6px solid var(--orange); }
p{ margin:10px 0; }
strong{ color:#b5430a; }

/* 箇条書き（うれしさ・手順） */
ul,ol{ margin:10px 0 14px; padding-left:1.4em; }
li{ margin:8px 0; }

/* たとえ話・ポイントの黄色ボックス（blockquote） */
blockquote{
  background:var(--warm); border:1px solid var(--line); border-left:8px solid var(--orange);
  border-radius:12px; margin:16px 0; padding:12px 18px; font-size:13pt;
  page-break-inside:avoid;
}
blockquote p{ margin:4px 0; }
blockquote strong{ color:var(--green2); }

/* 表 */
table{ border-collapse:collapse; width:100%; margin:14px 0; font-size:12pt;
       page-break-inside:avoid; }
th,td{ border:1px solid var(--line); padding:10px 12px; text-align:left; vertical-align:top; }
th{ background:var(--green); color:#fff; }
tr:nth-child(even) td{ background:#faf6ee; }

code{ background:#f3eede; padding:1px 6px; border-radius:5px; font-size:11pt; color:#7a5200; }
hr{ border:none; border-top:1px dashed var(--line); margin:20px 0; }
small{ color:#8a8170; font-size:10pt; }

/* 図：大きめ・中央・余白 */
.mermaid{ text-align:center; margin:18px 0; page-break-inside:avoid; }
.mermaid svg{ max-width:100%; max-height:120mm; height:auto; }

@page{ size:A4 portrait; margin:16mm 14mm; }
"""

def main():
    print("1) JSライブラリ準備...")
    if not build.fetch_libs():
        return 2
    print("2) Markdown読み込み...")
    with open(MD_PATH, encoding="utf-8") as f:
        md = f.read()
    with open(os.path.join(build.BUILD, "md.js"), "w", encoding="utf-8") as f:
        f.write("window.MD = " + json.dumps(md, ensure_ascii=False) + ";")
    print("3) HTML生成（やさしいCSS）...")
    html = build.HTML_TMPL.replace("__CSS__", CSS_EASY)
    index = os.path.join(build.BUILD, "index.html")
    with open(index, "w", encoding="utf-8") as f:
        f.write(html)
    chrome = build.find_chrome()
    if not chrome:
        print("  Chrome/Edge が見つかりません。")
        return 3
    if os.path.exists(OUT_TMP):
        os.remove(OUT_TMP)
    print(f"4) PDF化... ({os.path.basename(chrome)})")
    url = "file:///" + index.replace("\\", "/")
    cmd = [chrome, "--headless", "--disable-gpu", "--no-sandbox",
           "--no-pdf-header-footer", "--run-all-compositor-stages-before-draw",
           "--virtual-time-budget=30000", f"--print-to-pdf={OUT_TMP}", url]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    if not os.path.exists(OUT_TMP) or os.path.getsize(OUT_TMP) < 5000:
        print("  失敗 stderr:", res.stderr[-1500:])
        return 4
    shutil.copyfile(OUT_TMP, OUT_FINAL)
    print(f"5) 完成: {OUT_FINAL} ({os.path.getsize(OUT_FINAL):,} bytes)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
