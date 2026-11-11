"""Build docs/index.html (a complete page for GitHub Pages) from site/index.html.

Usage: python3 site/build_pages.py [source.html]
The source defaults to site/index.html; pass a page downloaded from the
claude.ai artifact to publish the latest edits made in its edit mode.
"""
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "site", "index.html")
OUT_DIR = os.path.join(ROOT, "docs")
SITE_URL = "https://kontawanlapfah.github.io/"

src = open(SRC, encoding="utf8").read()
# A page saved from the artifact carries the viewer skeleton; keep only the body content.
if src.lstrip().lower().startswith("<!doctype"):
    src = src[src.index("<body>") + len("<body>"):src.rindex("</body>")]

start = src.index('<style id="site-style">')
body = src[start:]

head = f"""<!doctype html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>ก่อนตะวันลับฟ้า</title>
<meta name="description" content="ก่อนตะวันลับฟ้า — ช่องข้อเตือนใจและเรื่องเล่าแอนิเมชัน จากอัลกุรอานและหะดีษ">
<meta property="og:type" content="website">
<meta property="og:title" content="ก่อนตะวันลับฟ้า">
<meta property="og:description" content="ช่องข้อเตือนใจและเรื่องเล่าแอนิเมชัน จากอัลกุรอานและหะดีษ">
<meta property="og:image" content="{SITE_URL}assets/logo.jpg">
<meta property="og:url" content="{SITE_URL}">
<meta property="og:locale" content="th_TH">
<meta property="og:site_name" content="ก่อนตะวันลับฟ้า">
<meta name="twitter:card" content="summary">
<link rel="canonical" href="{SITE_URL}">
<meta name="theme-color" content="#f7e2b8">
<link rel="icon" href="assets/logo.jpg">
<link rel="apple-touch-icon" href="assets/logo.jpg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Amiri:wght@700&family=Mitr:wght@400;500;600&family=Anuphan:wght@300;400;500;600&display=swap">
<style>:root{{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}}body{{margin:0}}img{{max-width:100%}}[hidden]{{display:none!important}}</style>
</head>
<body>
<noscript><div style="max-width:640px;margin:40px auto;padding:0 16px;font-family:sans-serif;line-height:1.7"><h1>ก่อนตะวันลับฟ้า</h1><p>ช่องข้อเตือนใจและเรื่องเล่าแอนิเมชัน จากอัลกุรอานและหะดีษ</p><p>หน้านี้ต้องเปิด JavaScript เพื่อแสดงผล ติดตามช่องได้ที่ <a href="https://www.youtube.com/@kontawanlapfah">YouTube</a> · <a href="https://www.tiktok.com/@ngaohaengpanya">TikTok</a></p></div></noscript>
"""

os.makedirs(os.path.join(OUT_DIR, "assets"), exist_ok=True)
with open(os.path.join(OUT_DIR, "index.html"), "w", encoding="utf8") as f:
    f.write(head + body + "\n</body>\n</html>\n")
shutil.copy(os.path.join(ROOT, "site", "assets", "logo.jpg"), os.path.join(OUT_DIR, "assets", "logo.jpg"))
for _f in ("gift-howto.mp4", "ep11.mp4", "ep11.jpg"):
    shutil.copy(os.path.join(ROOT, "site", "assets", _f), os.path.join(OUT_DIR, "assets", _f))
open(os.path.join(OUT_DIR, ".nojekyll"), "w").close()
shutil.copytree(os.path.join(ROOT, "site", "wallpapers"), os.path.join(OUT_DIR, "wallpapers"), dirs_exist_ok=True)
with open(os.path.join(OUT_DIR, "robots.txt"), "w") as f:
    f.write("User-agent: *\nAllow: /\nSitemap: " + SITE_URL + "sitemap.xml\n")
with open(os.path.join(OUT_DIR, "sitemap.xml"), "w") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>' + SITE_URL + '</loc></url><url><loc>' + SITE_URL + 'wallpapers/</loc></url></urlset>\n')
with open(os.path.join(OUT_DIR, "404.html"), "w", encoding="utf8") as f:
    f.write('<!doctype html><html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>ไม่พบหน้านี้ · ก่อนตะวันลับฟ้า</title><style>body{margin:0;min-height:100vh;display:grid;place-items:center;font-family:sans-serif;background:linear-gradient(180deg,#2a2244,#8b5a6c 70%,#e99d66);color:#fbf1de;text-align:center;padding:24px}a{display:inline-block;margin-top:16px;padding:12px 26px;border-radius:99px;background:#f6d79a;color:#2a2244;text-decoration:none;font-weight:600}</style></head><body><div><h1>ไม่พบหน้านี้</h1><p>ลิงก์อาจเปลี่ยนไปแล้ว</p><a href="/">กลับหน้าแรก</a></div></body></html>')

if re.search(r'"(img|logoImg)":"[0-9a-f]{32}"', body):
    print("warning: page uses images uploaded on claude.ai (/_blob/...); they will not show on GitHub Pages")
print("wrote", os.path.join(OUT_DIR, "index.html"))
