# -*- coding: utf-8 -*-
"""機能別解説 markdown -> PDF。build.py の CSS/HTML/関数を再利用する。"""
import os, sys, json, subprocess, shutil
import build  # reuse fetch_libs, find_chrome, CSS, HTML_TMPL, BUILD

PROJ = build.PROJ
MD_PATH = os.path.join(PROJ, "docs", "発表_開発解説", "機能別解説_鳩ナビ.md")
OUT_FINAL = os.path.join(PROJ, "docs", "発表_開発解説", "鳩ナビ_機能別解説.pdf")
OUT_TMP = os.path.join(build.BUILD, "feat_out.pdf")

def main():
    print("1) JSライブラリ準備...")
    if not build.fetch_libs():
        return 2
    print("2) Markdown読み込み...")
    with open(MD_PATH, encoding="utf-8") as f:
        md = f.read()
    with open(os.path.join(build.BUILD, "md.js"), "w", encoding="utf-8") as f:
        f.write("window.MD = " + json.dumps(md, ensure_ascii=False) + ";")
    print("3) HTML生成...")
    html = build.HTML_TMPL.replace("__CSS__", build.CSS)
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
           "--virtual-time-budget=40000", f"--print-to-pdf={OUT_TMP}", url]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=200)
    if not os.path.exists(OUT_TMP) or os.path.getsize(OUT_TMP) < 5000:
        print("  失敗 stderr:", res.stderr[-1500:])
        return 4
    shutil.copyfile(OUT_TMP, OUT_FINAL)
    print(f"5) 完成: {OUT_FINAL} ({os.path.getsize(OUT_FINAL):,} bytes)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
