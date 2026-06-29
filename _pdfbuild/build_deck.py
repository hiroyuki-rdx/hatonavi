# -*- coding: utf-8 -*-
"""Self-contained slide deck (deck.html + local mermaid) -> landscape PDF via headless Chrome."""
import os, sys, subprocess, urllib.request, shutil

BUILD = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(BUILD)
DECK = os.path.join(BUILD, "deck.html")
OUT_TMP = os.path.join(BUILD, "deck_out.pdf")
OUT_FINAL = os.path.join(PROJ, "docs", "発表_開発解説", "鳩ナビ_発表資料.pdf")
MERMAID_URL = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"

def ensure_mermaid():
    dest = os.path.join(BUILD, "mermaid.min.js")
    if os.path.exists(dest) and os.path.getsize(dest) > 1000:
        print(f"  [skip] mermaid.min.js present ({os.path.getsize(dest)} bytes)")
        return True
    try:
        req = urllib.request.Request(MERMAID_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
        with open(dest, "wb") as f:
            f.write(data)
        print(f"  [ok] mermaid.min.js downloaded ({len(data)} bytes)")
        return True
    except Exception as e:
        print(f"  [FAIL] mermaid download: {e}")
        return False

def find_chrome():
    for c in [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
              r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"]:
        if os.path.exists(c):
            return c
    return None

def main():
    print("1) mermaid 準備...")
    if not ensure_mermaid():
        return 2
    chrome = find_chrome()
    if not chrome:
        print("  Chrome/Edge が見つかりません。")
        return 3
    if os.path.exists(OUT_TMP):
        os.remove(OUT_TMP)
    url = "file:///" + DECK.replace("\\", "/")
    print(f"2) PDF化 (landscape, {os.path.basename(chrome)})...")
    cmd = [chrome, "--headless=new", "--disable-gpu", "--no-sandbox",
           "--no-pdf-header-footer", "--run-all-compositor-stages-before-draw",
           "--virtual-time-budget=40000",
           f"--print-to-pdf={OUT_TMP}", url]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=200)
    if not os.path.exists(OUT_TMP) or os.path.getsize(OUT_TMP) < 5000:
        print("  失敗 stderr:", res.stderr[-1500:])
        return 4
    shutil.copyfile(OUT_TMP, OUT_FINAL)
    print(f"3) 完成: {OUT_FINAL} ({os.path.getsize(OUT_FINAL):,} bytes)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
