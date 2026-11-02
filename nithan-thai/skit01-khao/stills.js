const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960},deviceScaleFactor:4/3});
await p.goto('file://'+__dirname+'/scene.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
for(const t of process.argv.slice(2)){await p.evaluate(t=>update(+t),t);await p.screenshot({path:process.env.OUT+'/k-'+t+'.png'})}
await b.close()})();
