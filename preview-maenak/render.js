// Renders scene.html frame-by-frame to PNGs: node render.js <outDir> [fps] [seconds]
const {chromium}=require('playwright');
(async()=>{const [out,fps=24,dur=30]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:1280,height:720}});
await p.goto('file://'+__dirname+'/scene.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
const n=Math.round(fps*dur);for(let f=0;f<n;f++){await p.evaluate(t=>update(t),f/fps);await p.screenshot({path:`${out}/f${String(f).padStart(4,'0')}.png`})}
await b.close()})();
