# -*- coding: utf-8 -*-
"""Markdown(+Mermaid) -> PDF builder using local JS libs + headless Chrome."""
import json, os, sys, subprocess, urllib.request, shutil

BUILD = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(BUILD)
MD_PATH = os.path.join(PROJ, "docs", "発表_開発解説", "教科書_鳩ナビ開発入門.md")
OUT_DIR = os.path.join(PROJ, "docs", "発表_開発解説")
OUT_PDF_FINAL = os.path.join(OUT_DIR, "鳩ナビ開発入門_教科書.pdf")
OUT_PDF_TMP = os.path.join(BUILD, "out.pdf")

LIBS = {
    "marked.min.js": "https://cdn.jsdelivr.net/npm/marked@4.3.0/marked.min.js",
    "mermaid.min.js": "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js",
}

def fetch_libs():
    ok = True
    for fn, url in LIBS.items():
        dest = os.path.join(BUILD, fn)
        if os.path.exists(dest) and os.path.getsize(dest) > 1000:
            print(f"  [skip] {fn} already present ({os.path.getsize(dest)} bytes)")
            continue
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            with open(dest, "wb") as f:
                f.write(data)
            print(f"  [ok] {fn} downloaded ({len(data)} bytes)")
        except Exception as e:
            print(f"  [FAIL] {fn}: {e}")
            ok = False
    return ok

def find_chrome():
    cands = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ]
    for c in cands:
        if os.path.exists(c):
            return c
    return None

CSS = r"""
:root{ --accent:#2E7D5B; --accent2:#1F5A40; --beige:#FFF6E9; --line:#dcd2c2; }
*{ box-sizing:border-box; }
body{
  font-family:"Yu Gothic","YuGothic","Meiryo","Hiragino Kaku Gothic ProN",sans-serif;
  color:#2b2b2b; line-height:1.85; font-size:11pt;
  margin:0; padding:0; -webkit-print-color-adjust:exact; print-color-adjust:exact;
}
#content{ max-width:170mm; margin:0 auto; padding:4mm 2mm; }
h1{
  page-break-before:always; font-size:19pt; color:var(--accent2);
  border-bottom:3px solid var(--accent); padding-bottom:6px; margin:0 0 14px;
}
#content>h1:first-child{ page-break-before:avoid; }
h2{ font-size:14.5pt; color:var(--accent2); border-left:7px solid var(--accent);
    padding-left:10px; margin:22px 0 8px; page-break-after:avoid; }
h3{ font-size:12.5pt; color:var(--accent2); margin:16px 0 6px; page-break-after:avoid; }
p{ margin:6px 0; }
strong{ color:#9a2b00; }
a{ color:var(--accent2); }
ul,ol{ margin:6px 0 10px; padding-left:1.5em; }
li{ margin:3px 0; }
code{ font-family:"Consolas","Courier New",monospace; background:#f3efe6;
      padding:1px 5px; border-radius:4px; font-size:9.5pt; color:#5a3d00; }
pre{ background:#f6f3ec; border:1px solid var(--line); border-radius:8px;
     padding:10px 12px; overflow:auto; }
pre code{ background:none; padding:0; color:#333; }
blockquote{
  background:var(--beige); border:1px solid var(--line);
  border-left:6px solid var(--accent); border-radius:8px;
  margin:12px 0; padding:8px 14px; page-break-inside:avoid;
}
blockquote p{ margin:4px 0; }
table{ border-collapse:collapse; width:100%; margin:12px 0; font-size:10pt;
       page-break-inside:avoid; }
th,td{ border:1px solid var(--line); padding:6px 9px; text-align:left;
       vertical-align:top; }
th{ background:var(--accent); color:#fff; }
tr:nth-child(even) td{ background:#faf7f0; }
hr{ border:none; border-top:1px dashed var(--line); margin:18px 0; }
.mermaid{ text-align:center; margin:14px 0; page-break-inside:avoid; }
.mermaid svg{ max-width:100%; height:auto; }
@page{ size:A4; margin:18mm 14mm; }
"""

HTML_TMPL = """<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<title>鳩ナビ 開発入門テキスト</title>
<style>__CSS__</style>
<script src="marked.min.js"></script>
<script src="mermaid.min.js"></script>
<script src="md.js"></script>
</head><body>
<div id="content"></div>
<script>
(function(){
  try{
    var html = marked.parse(window.MD);
    document.getElementById('content').innerHTML = html;
    document.querySelectorAll('code.language-mermaid').forEach(function(code){
      var div=document.createElement('div');
      div.className='mermaid';
      div.textContent=code.textContent;
      var pre=code.closest('pre');
      (pre||code).replaceWith(div);
    });
    mermaid.initialize({startOnLoad:false, securityLevel:'loose', theme:'default',
      flowchart:{htmlLabels:true, useMaxWidth:true},
      themeVariables:{fontFamily:'"Yu Gothic","Meiryo",sans-serif'}});
    mermaid.run({querySelector:'.mermaid'}).then(function(){
      window.__ready=true; document.title='READY';
    }).catch(function(e){ console.error(e); window.__ready=true; document.title='READY'; });
  }catch(e){ console.error(e); window.__ready=true; }
})();
</script>
</body></html>
"""

def main():
    print("1) JSライブラリを取得...")
    if not fetch_libs():
        print("  ライブラリ取得に失敗しました。ネット接続を確認してください。")
        return 2

    print("2) Markdown読み込み...")
    with open(MD_PATH, encoding="utf-8") as f:
        md = f.read()
    with open(os.path.join(BUILD, "md.js"), "w", encoding="utf-8") as f:
        f.write("window.MD = " + json.dumps(md, ensure_ascii=False) + ";")

    print("3) HTML生成...")
    html = HTML_TMPL.replace("__CSS__", CSS)
    index = os.path.join(BUILD, "index.html")
    with open(index, "w", encoding="utf-8") as f:
        f.write(html)

    chrome = find_chrome()
    if not chrome:
        print("  Chrome/Edge が見つかりませんでした。")
        return 3
    print(f"4) ヘッドレスブラウザでPDF化... ({os.path.basename(chrome)})")
    if os.path.exists(OUT_PDF_TMP):
        os.remove(OUT_PDF_TMP)
    url = "file:///" + index.replace("\\", "/")
    cmd = [chrome, "--headless", "--disable-gpu", "--no-sandbox",
           "--no-pdf-header-footer",
           "--run-all-compositor-stages-before-draw",
           "--virtual-time-budget=30000",
           f"--print-to-pdf={OUT_PDF_TMP}", url]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    if res.returncode != 0 and not os.path.exists(OUT_PDF_TMP):
        print("  Chrome stderr:", res.stderr[-1500:])
        return 4

    if not os.path.exists(OUT_PDF_TMP) or os.path.getsize(OUT_PDF_TMP) < 5000:
        print("  PDFが生成されませんでした。stderr:", res.stderr[-1500:])
        return 5

    shutil.copyfile(OUT_PDF_TMP, OUT_PDF_FINAL)
    print(f"5) 完成: {OUT_PDF_FINAL} ({os.path.getsize(OUT_PDF_FINAL):,} bytes)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
