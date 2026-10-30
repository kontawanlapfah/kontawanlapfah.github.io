// Deterministic HTML -> video renderer. The page must expose:
//   window.setFrame(t)  draws the frame at t seconds
//   window.TOTAL        length in seconds
//   window.KEYS         [[seconds, label], ...] storyboard keyframes (optional)
//
// Usage:
//   node render.js <page.html> storyboard <outDir>
//   node render.js <page.html> video <out.mp4> [fps=30] [scale=1] [audio.wav]
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const [page_, mode, out, fpsArg, scaleArg, audio] = process.argv.slice(2);
const url = 'file://' + path.resolve(page_) + '?render=1';

(async () => {
  const scale = +(scaleArg || 1);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: scale });
  await page.goto(url);
  await page.evaluate(() => document.fonts.ready);

  if (mode === 'storyboard') {
    fs.mkdirSync(out, { recursive: true });
    const keys = await page.evaluate(() => window.KEYS);
    for (const [t, n] of keys) {
      await page.evaluate(t => setFrame(t), t);
      await page.screenshot({ path: path.join(out, `frame-${String(n).padStart(2, '0')}-at-${t}s.png`) });
    }
  } else {
    const fps = +(fpsArg || 30);
    const total = await page.evaluate(() => TOTAL);
    const args = ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-'];
    if (audio) args.push('-i', audio, '-c:a', 'aac', '-b:a', '160k', '-shortest');
    args.push('-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-movflags', '+faststart', out);
    const ff = spawn('ffmpeg', args, { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let i = 0; i < Math.round(total * fps); i++) {
      await page.evaluate(t => setFrame(t), i / fps);
      ff.stdin.write(await page.screenshot({ type: 'jpeg', quality: 92 }));
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  await browser.close();
})();
