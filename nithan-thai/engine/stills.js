// node engine/stills.js <scene.html> <outPrefix> t1 t2 ...
const {chromium}=require('playwright'),path=require('path');
(async()=>{const [scene,pre,...ts]=process.argv.slice(2);const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960}});
p.on('pageerror',e=>console.log('ERR',e.message));
await p.goto('file://'+path.resolve(scene));await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(400);
for(const t of ts){await p.evaluate(t=>update(+t),t);await p.screenshot({path:`${pre}-${t}.png`})}await b.close()})();
