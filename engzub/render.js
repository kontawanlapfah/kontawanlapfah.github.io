const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:800,height:800}});
await p.goto('file://'+process.cwd()+'/logo.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(800);
console.log(await p.evaluate(()=>[...document.fonts].filter(f=>f.status=='loaded').map(f=>f.family).join(',')));
await p.screenshot({path:'engzub-profile.png'});
await p.addStyleTag({content:'svg{clip-path:circle(50%)}body{background:#fff}'});await p.screenshot({path:'preview-circle.png'});await b.close();})();
