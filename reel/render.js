// Usage:
//   node render.js storyboard <outDir>          -> one keyframe PNG per scene
//   node render.js video <out.mp4> [fps] [scale] -> full reel via ffmpeg
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const [mode, out, fpsArg, scaleArg] = process.argv.slice(2);
const url = 'file://' + path.join(__dirname, 'reel.html') + '?render=1';
// keyframe per scene: [time, label]
const KEYS = [[4, '1'], [10, '2'], [17.5, '3'], [23.5, '4'], [30.5, '5'], [38, '6'], [43, '7'], [49, '8'], [56.5, '9'], [61.5, '10']];

(async () => {
  const scale = +(scaleArg || 1);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: scale });
  await page.goto(url);
  await page.evaluate(() => document.fonts.ready);

  if (mode === 'storyboard') {
    fs.mkdirSync(out, { recursive: true });
    for (const [t, n] of KEYS) {
      await page.evaluate(t => setFrame(t), t);
      await page.screenshot({ path: path.join(out, `scene-${n.padStart(2, '0')}.png`) });
    }
  } else {
    const fps = +(fpsArg || 30);
    const total = await page.evaluate(() => TOTAL);
    const ff = spawn('ffmpeg', ['-y', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-',
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let i = 0; i < Math.round(total * fps); i++) {
      await page.evaluate(t => setFrame(t), i / fps);
      ff.stdin.write(await page.screenshot({ type: 'jpeg', quality: 92 }));
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  await browser.close();
})();
