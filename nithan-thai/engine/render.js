// node engine/render.js <scene.html> <outDir> <fps> <seconds> [scale=1.3333]  -> PNG frames
const {chromium}=require('playwright'),path=require('path');
(async()=>{const [scene,out,fps,dur,sc=4/3]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960},deviceScaleFactor:+sc});
await p.goto('file://'+path.resolve(scene));await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
const n=Math.round(fps*dur);for(let f=0;f<n;f++){await p.evaluate(t=>update(t),f/fps);await p.screenshot({path:`${out}/f${String(f).padStart(4,'0')}.png`})}
await b.close()})();
