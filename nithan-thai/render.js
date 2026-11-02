// node render.js -> profile.png (upload) + preview-circle.png (how YouTube crops it)
const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:800,height:800}});
await p.goto('file://'+__dirname+'/profile.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(500);
await p.screenshot({path:__dirname+'/nithanth-profile.png'});
await p.addStyleTag({content:'svg{clip-path:circle(50%)}body{background:#fff}'});await p.screenshot({path:__dirname+'/preview-circle.png'});await b.close()})();
