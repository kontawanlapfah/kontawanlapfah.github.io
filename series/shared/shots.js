// Screenshot an episode page at given seconds (voiceover timeline): node shots.js page.html outDir t1 t2 ...
const { chromium } = require('playwright'); const path = require('path');
(async () => {
  const [html, out, ...ts] = process.argv.slice(2);
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve(html) + '?render=1'); await p.evaluate(() => document.fonts.ready);
  for (const t of ts) { await p.evaluate(t => setFrame(t), +t); await p.screenshot({ path: `${out}/s-${t}.png` }); }
  await b.close();
})();
