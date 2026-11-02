// node render.js <outDir> <fps> <seconds>  -> frames f0000.png... (720x1280)
const {chromium}=require('playwright');
(async()=>{const [out,fps,dur]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960},deviceScaleFactor:4/3});
await p.goto('file://'+__dirname+'/scene.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
const n=Math.round(fps*dur);for(let f=0;f<n;f++){await p.evaluate(t=>update(t),f/fps);await p.screenshot({path:`${out}/f${String(f).padStart(4,'0')}.png`})}
await b.close()})();
