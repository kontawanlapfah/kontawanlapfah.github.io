// Shared characters + backgrounds for NithanTH skits (crayon style). Requires engine/ui.js first (NS, el, helpers).
const DEFS=`<filter id="crayon" x="-5%" y="-5%" width="110%" height="110%">
 <feTurbulence id="turb" type="fractalNoise" baseFrequency="0.035" numOctaves="3" seed="3" result="n1"/>
 <feDisplacementMap in="SourceGraphic" in2="n1" scale="5" xChannelSelector="R" yChannelSelector="G" result="d"/>
 <feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="8" result="grain"/>
 <feColorMatrix in="grain" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -0.9 0.5" result="specks"/>
 <feComposite in="specks" in2="d" operator="in" result="sp"/>
 <feMerge><feMergeNode in="d"/><feMergeNode in="sp"/></feMerge></filter>
<filter id="glow" x="-200%" y="-200%" width="500%" height="500%"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#232a55"/><stop offset=".6" stop-color="#7a4f7a"/><stop offset="1" stop-color="#e8936a"/></linearGradient>
<linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c2448"/><stop offset="1" stop-color="#454a7e"/></linearGradient>
<radialGradient id="vig" cx="50%" cy="45%" r="75%"><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient>`;
function grp(parent,html,attrs={}){const g=el('g',attrs,parent);g.innerHTML=html;return g}
const FACE=(eyY,mY)=>`
 <g class="blush" fill="#ee8f86" opacity=".65"><ellipse cx="-25" cy="${eyY+22}" rx="9" ry="5"/><ellipse cx="25" cy="${eyY+22}" rx="9" ry="5"/></g>
 <g class="eyes" fill="#2b2430"><circle cx="-15" cy="${eyY}" r="4"/><circle cx="15" cy="${eyY}" r="4"/></g>
 <g class="shock" opacity="0"><circle cx="-15" cy="${eyY}" r="8" fill="#fff" stroke="#2b2430" stroke-width="2"/><circle cx="15" cy="${eyY}" r="8" fill="#fff" stroke="#2b2430" stroke-width="2"/><circle cx="-15" cy="${eyY}" r="3" fill="#2b2430"/><circle cx="15" cy="${eyY}" r="3" fill="#2b2430"/></g>
 <g class="happy" stroke="#2b2430" stroke-width="3" fill="none" stroke-linecap="round" opacity="0"><path d="M-21 ${eyY+2} q6 -8 12 0"/><path d="M9 ${eyY+2} q6 -8 12 0"/></g>
 <path class="brow" d="M-24 ${eyY-16} l13 4 M11 ${eyY-12} l13 -4" stroke="#4a3330" stroke-width="3" stroke-linecap="round" opacity="0"/>
 <path class="mouthC" d="M-7 ${mY} q7 5 14 0" stroke="#8a3f3a" stroke-width="3" fill="none" stroke-linecap="round"/>
 <path class="mouthB" d="M-10 ${mY-2} q10 12 20 0z" fill="#7a3a35" opacity="0"/>
 <ellipse class="mouthO" cx="0" cy="${mY+1}" rx="6" ry="6" fill="#7a3a35" opacity="0"/>
 <path class="sweat" d="M44 ${eyY-44} q-9 14 0 18 q9 -4 0 -18z" fill="#9fd3ea" opacity="0"/>
 <g class="tears" fill="#9fd3ea" opacity="0"><path d="M-24 ${eyY+6} q-6 14 -2 26 q6 -4 4 -26z"/><path d="M24 ${eyY+6} q6 14 2 26 q-6 -4 -4 -26z"/></g>`;
const SLEEVE=(c,o)=>`<path d="M-48 -238 Q-68 -180 -60 -128" stroke="${o}" stroke-width="25" stroke-linecap="round" fill="none"/><path d="M-48 -238 Q-68 -180 -60 -128" stroke="${c}" stroke-width="20" stroke-linecap="round" fill="none"/>`;
const ARMR=(c,o,skin)=>`<g class="armR"><g filter="url(#crayon)"><path d="M46 -238 Q66 -180 58 -128" stroke="${o}" stroke-width="25" stroke-linecap="round" fill="none"/><path d="M46 -238 Q66 -180 58 -128" stroke="${c}" stroke-width="20" stroke-linecap="round" fill="none"/><circle cx="58" cy="-120" r="11" fill="${skin}"/></g>
 <g class="phone" opacity="0"><rect x="46" y="-146" width="24" height="40" rx="5" fill="#2b2d42"/><rect x="49" y="-142" width="18" height="30" rx="2" fill="#8fd3f0"/></g></g>`;
// generic face/arm controller
function ctl(g,armPivot){const q=s=>g.querySelector(s),o=(s,v)=>{const e=q(s);if(e)e.setAttribute('opacity',v)};
 return {g,set(s){const x=s.x??0,y=s.y??0;g.setAttribute('transform',`translate(${x} ${y})`);
  const e=s.expr||'normal',talk=!!s.talk,shock=e=='shock',happy=e=='happy'||e=='laugh'||e=='cry',worried=e=='worried'||shock;
  o('.eyes',shock||happy?0:1);o('.shock',shock?1:0);o('.happy',happy?1:0);o('.brow',worried?1:0);
  o('.sweat',s.sweat?.9:0);o('.tears',e=='cry'?.9:0);o('.blush',e=='emb'?1:.65);
  const open=talk||shock;o('.mouthO',open&&!(e=='laugh')?1:0);o('.mouthB',e=='laugh'?1:0);o('.mouthC',open||e=='laugh'?0:1);
  const L=s.look||[0,0];q('.eyes').setAttribute('transform',`translate(${L[0]} ${L[1]})`);
  const sw=q('.sweat');if(sw)sw.setAttribute('transform',`translate(0 ${((s.t||0)*20)%14})`);
  const a=q('.armR');if(a){const r=s.arm||0;a.setAttribute('transform',`rotate(${r} ${armPivot})`);const ph=q('.phone');if(ph){ph.setAttribute('opacity',s.phone?1:0);ph.setAttribute('transform',`rotate(${-r} 58 -124)`)}}
 }}}
function Putri(parent){const g=grp(parent,`<ellipse cx="0" cy="0" rx="62" ry="10" fill="#000" opacity=".25"/>
 <g filter="url(#crayon)"><path d="M-50 -122 L50 -122 L64 -8 L-64 -8Z" fill="#3d4a6b"/>
  <ellipse cx="-22" cy="-5" rx="18" ry="7" fill="#6b4a3f"/><ellipse cx="22" cy="-5" rx="18" ry="7" fill="#6b4a3f"/>
    <path d="M-48 -250 Q0 -262 48 -250 L55 -118 L-55 -118Z" fill="#fbfaf6" stroke="#cfc8bc" stroke-width="2"/>
  <path d="M-40 -246 L32 -128" stroke="#b08a5a" stroke-width="8"/>${SLEEVE('#fbfaf6','#cfc8bc')}<circle cx="-60" cy="-120" r="11" fill="#d9a184"/></g>
 ${ARMR('#fbfaf6','#cfc8bc','#d9a184')}
 <g filter="url(#crayon)"><path d="M0 -398 C-50 -398 -70 -360 -70 -310 C-72 -280 -76 -250 -78 -220 L-80 -160 Q-78 -142 -60 -140 Q0 -128 60 -140 Q78 -142 80 -160 L78 -220 C76 -250 72 -280 70 -310 C70 -360 50 -398 0 -398Z" fill="#e3a19b"/>
  <g stroke="#cf8a84" stroke-width="4" stroke-linecap="round" fill="none"><path d="M-58 -196 q22 5 44 0"/><path d="M-40 -172 q34 7 68 0"/><path d="M-6 -156 q26 4 48 -2"/><path d="M30 -200 q18 4 34 -2"/></g><ellipse cx="0" cy="-322" rx="43" ry="47" fill="#d9a184"/></g>
 <ellipse cx="0" cy="-322" rx="46" ry="50" fill="none" stroke="#c98680" stroke-width="5"/>${FACE(-324,-296)}`);return ctl(g,'46 -238')}
function Ton(parent){const g=grp(parent,`<ellipse cx="0" cy="0" rx="58" ry="10" fill="#000" opacity=".25"/>
 <g filter="url(#crayon)"><path d="M-46 -124 L46 -124 L44 -10 L6 -10 L0 -90 L-6 -10 L-44 -10Z" fill="#2c3346"/>
  <ellipse cx="-24" cy="-6" rx="19" ry="7" fill="#222"/><ellipse cx="24" cy="-6" rx="19" ry="7" fill="#222"/>
  <path d="M-48 -252 Q0 -262 48 -252 L52 -120 L-52 -120Z" fill="#fbfaf6" stroke="#cfc8bc" stroke-width="2"/>
  <rect x="-50" y="-128" width="100" height="9" fill="#2b2b2b"/><rect x="-7" y="-129" width="14" height="11" fill="#c9a75a"/>
  <path d="M-16 -252 L0 -232 L16 -252" stroke="#cfc8bc" stroke-width="3" fill="none"/><circle cx="-26" cy="-215" r="5" fill="#c9a75a"/>
  ${SLEEVE('#fbfaf6','#cfc8bc')}<circle cx="-60" cy="-120" r="11" fill="#e9b59b"/>
  <rect x="-10" y="-275" width="20" height="26" fill="#e9b59b"/></g>
 ${ARMR('#fbfaf6','#cfc8bc','#e9b59b')}
 <g filter="url(#crayon)"><ellipse cx="-44" cy="-318" rx="8" ry="11" fill="#e9b59b"/><ellipse cx="44" cy="-318" rx="8" ry="11" fill="#e9b59b"/>
  <ellipse cx="0" cy="-320" rx="44" ry="48" fill="#ecbca2"/>
  <path d="M-47 -322 C-52 -372 -20 -378 2 -376 C30 -378 52 -366 47 -322 C40 -345 22 -352 8 -350 C14 -342 10 -336 4 -334 C-4 -348 -26 -350 -47 -322Z" fill="#1d1a22"/></g>${FACE(-318,-292)}`);return ctl(g,'46 -238')}
function Bibi(parent){const g=grp(parent,`<g filter="url(#crayon)">
  <path d="M-58 5 L-52 -92 Q0 -104 52 -92 L58 5Z" fill="#5f9a8a"/><path d="M-36 -70 L36 -70 L38 5 L-38 5Z" fill="#f1e3c8"/><path d="M-30 -70 L-22 -98 M30 -70 L22 -98" stroke="#f1e3c8" stroke-width="6"/>
  <rect x="-9" y="-112" width="18" height="20" fill="#e2ad92"/></g>
 <g class="armB"><g filter="url(#crayon)"><path d="M-48 -86 Q-74 -50 -66 -18" stroke="#5f9a8a" stroke-width="20" stroke-linecap="round" fill="none"/><circle cx="-66" cy="-14" r="10" fill="#e2ad92"/>
  <path d="M-66 -14 L-96 -46" stroke="#9aa6ad" stroke-width="5" stroke-linecap="round"/><ellipse cx="-100" cy="-50" rx="12" ry="8" fill="#9aa6ad"/></g></g>
 <g class="hd"><g filter="url(#crayon)"><ellipse cx="0" cy="-150" rx="40" ry="44" fill="#e9b59b"/>
  <g fill="#4a4450"><path d="M-42 -152 C-46 -196 -20 -200 0 -199 C20 -200 46 -196 42 -152 C34 -176 18 -182 0 -180 C-18 -182 -34 -176 -42 -152Z"/><circle cx="0" cy="-200" r="17"/><circle cx="-38" cy="-168" r="10"/><circle cx="38" cy="-168" r="10"/></g></g>
  ${FACE(-150,-124).replace(/r="4"/g,'r="3.2"')}
  <g fill="none" stroke="#3a3340" stroke-width="2.6"><circle cx="-15" cy="-150" r="12"/><circle cx="15" cy="-150" r="12"/><path d="M-3 -151 q3 -3 6 0"/></g></g>
 <text class="qm" x="38" y="-212" font-family="Kanit" font-weight="800" font-size="50" fill="#ffd27a" opacity="0">?</text>`);
 const c=ctl(g,'0 0'),base=c.set;c.set=s=>{base(s);g.querySelector('.hd').setAttribute('transform',`rotate(${s.tilt||0} 0 -110)`);
  g.querySelector('.armB').setAttribute('transform',`rotate(${s.arm||0} -48 -86)`);g.querySelector('.qm').setAttribute('opacity',s.q||0)};return c}
// ---------- backgrounds ----------
function bgStall(svg,front){if(front){return grp(svg,`<g filter="url(#crayon)"><rect x="268" y="556" width="285" height="170" fill="#a8744f"/><rect x="262" y="543" width="297" height="17" fill="#c48b5c"/>
 <rect x="300" y="590" width="86" height="104" fill="#f6efe0" transform="rotate(-3 343 642)"/><g stroke="#b9a98a" stroke-width="4"><path d="M312 615h60M312 635h50M312 655h58M312 675h44" transform="rotate(-3 343 642)"/></g>
 <rect x="410" y="520" width="52" height="24" rx="4" fill="#d9822b"/><rect x="468" y="520" width="52" height="24" rx="4" fill="#6f8f4a"/>
 <rect x="302" y="482" width="78" height="62" rx="12" fill="#b9c3c9"/><rect x="296" y="476" width="90" height="12" rx="6" fill="#d3dbe0"/><ellipse cx="341" cy="478" rx="38" ry="7" fill="#fbfaf4"/></g>
 <g class="steam" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"><path/><path/><path/></g>`)}
 const R=rnd(7),g=grp(svg,`<rect width="540" height="530" fill="url(#sky)"/><g class="bld" filter="url(#crayon)"></g>
 <rect y="520" width="540" height="440" fill="#4a3f4a" filter="url(#crayon)"/><g stroke="#5a4e5a" stroke-width="3" filter="url(#crayon)"><path d="M0 600H540M0 690H540M0 790H540M90 520L40 960M260 520L250 960M430 520L470 960"/></g>
 <path class="w1" fill="none" stroke="#1d1a2a" stroke-width="2"/><path class="w2" fill="none" stroke="#1d1a2a" stroke-width="2"/><g class="bulbs" filter="url(#glow)"></g>
 <g filter="url(#crayon)"><rect x="290" y="335" width="245" height="225" fill="#5d4038"/><g fill="#7b5a4c"><rect x="300" y="380" width="225" height="8"/><rect x="300" y="440" width="225" height="8"/></g>
  <rect x="310" y="352" width="18" height="28" rx="4" fill="#c8553d"/><rect x="334" y="358" width="16" height="22" rx="4" fill="#e9c46a"/><rect x="470" y="350" width="22" height="30" rx="5" fill="#7aa58f"/><rect x="497" y="356" width="16" height="24" rx="4" fill="#c8553d"/>
  <rect x="312" y="412" width="30" height="28" rx="6" fill="#e9dfc9"/><rect x="490" y="414" width="26" height="26" rx="6" fill="#e9dfc9"/>
  <rect x="283" y="300" width="11" height="420" fill="#3b2d27"/><rect x="528" y="300" width="11" height="420" fill="#3b2d27"/><rect x="300" y="222" width="225" height="54" rx="8" fill="#f3e2b3"/></g>
 <text x="412" y="261" text-anchor="middle" font-family="Kanit" font-weight="800" font-size="30" fill="#8a3b2a">อาหารตามสั่ง</text><g class="awn" filter="url(#crayon)"></g>`);
 const q=s=>g.querySelector(s);
 for(let x=-10;x<560;){const w=50+R()*60,h=120+R()*200;el('rect',{x,y:530-h,width:w,height:h,fill:R()>.5?'#2e2a4a':'#3a3356'},q('.bld'));
  for(let wy=530-h+15;wy<510;wy+=26)for(let wx=x+8;wx<x+w-12;wx+=18)if(R()>.55)el('rect',{x:wx,y:wy,width:8,height:10,fill:'#f5c96a',opacity:.8},q('.bld'));x+=w+4}
 const bulbs=[];[[0,92,270,170,540,128],[0,190,270,250,540,165]].forEach((w,i)=>{q('.w'+(i+1)).setAttribute('d',`M${w[0]} ${w[1]} Q${w[2]} ${w[3]} ${w[4]} ${w[5]}`);
  for(let k=1;k<12;k++){const s=k/12,x=(1-s)**2*w[0]+2*(1-s)*s*w[2]+s*s*w[4],y=(1-s)**2*w[1]+2*(1-s)*s*w[3]+s*s*w[5];bulbs.push([el('circle',{cx:x,cy:y+6,r:5,fill:['#ffd27a','#ff9f7a','#9fe0c0'][k%3]},q('.bulbs')),R()*6,1+R()*2])}});
 for(let i=0;i<8;i++){el('rect',{x:272+i*35,y:278,width:35,height:58,fill:i%2?'#fbf2df':'#c8553d'},q('.awn'));el('circle',{cx:289.5+i*35,cy:336,r:17.5,fill:i%2?'#fbf2df':'#c8553d'},q('.awn'))}
 return {g,update(t,fr){bulbs.forEach(([e,p,s])=>e.setAttribute('opacity',.55+.45*Math.abs(Math.sin(t*s+p))));
  if(fr)[...fr.querySelectorAll('.steam path')].forEach((e,i)=>{const ph=(t*.6+i/3)%1,x=322+i*20,y=468-ph*70;e.setAttribute('d',`M${x} ${y} q${8*Math.sin(t*2+i)} -12 0 -24 q${-8*Math.sin(t*2+i)} -12 0 -24`);e.setAttribute('opacity',.5*Math.sin(ph*Math.PI))})}}}
function bgRoom(svg){const R=rnd(11),g=grp(svg,`<g filter="url(#crayon)"><rect width="540" height="960" fill="#e6d6c0"/>
 <g stroke="#dccab0" stroke-width="6"><path d="M40 0V720M120 0V720M200 0V720M280 0V720M360 0V720M440 0V720M520 0V720"/></g>
 <rect x="50" y="160" width="250" height="270" fill="#8a6a52"/><rect x="62" y="172" width="226" height="246" fill="url(#night)"/></g>
 <g class="sky"></g><circle cx="240" cy="220" r="22" fill="#f4ecd2" filter="url(#glow)"/>
 <g filter="url(#crayon)"><rect x="172" y="172" width="6" height="246" fill="#8a6a52"/><rect x="62" y="292" width="226" height="6" fill="#8a6a52"/>
  <path d="M36 150 Q60 300 44 440 L80 440 Q96 300 74 150Z" fill="#7aa58f"/><path d="M314 150 Q290 300 306 440 L270 440 Q254 300 276 150Z" fill="#7aa58f"/>
  <rect x="26" y="140" width="300" height="14" rx="7" fill="#6b4a3f"/>
  <rect x="352" y="190" width="150" height="170" fill="#fbf4e4" transform="rotate(3 427 275)"/>
  <rect x="0" y="720" width="540" height="240" fill="#b88a64"/><g stroke="#9c7150" stroke-width="3"><path d="M0 780H540M0 850H540M0 920H540M120 720V780M300 780V850M80 850V920M420 720V780M460 850V920"/></g>
  <rect x="300" y="610" width="250" height="120" rx="10" fill="#6b4a3f"/><rect x="306" y="585" width="240" height="50" rx="14" fill="#fbfaf6"/><rect x="380" y="600" width="170" height="70" rx="12" fill="#5f8a86"/><ellipse cx="345" cy="590" rx="40" ry="18" fill="#fff"/></g>
 <g font-family="Kanit" font-weight="800" fill="#c9653f" text-anchor="middle" transform="rotate(3 427 275)"><text x="427" y="232" font-size="30">ก ข ค</text><text x="427" y="280" font-size="26" fill="#3d6fb0">ง จ ฉ</text><text x="427" y="325" font-size="22" fill="#3f8f5a">ภาษาไทย</text></g>`);
 const sky=g.querySelector('.sky');for(let x=62;x<288;){const w=18+R()*26,h=40+R()*90;el('rect',{x,y:418-h,width:w,height:h,fill:'#262a4e'},sky);for(let wy=418-h+8;wy<410;wy+=14)if(R()>.5)el('rect',{x:x+5,y:wy,width:5,height:6,fill:'#f5c96a'},sky);x+=w+3}
 return {g,update(){}}}
function bgClass(svg){const g=grp(svg,`<g filter="url(#crayon)"><rect width="540" height="960" fill="#dfe6dc"/><rect y="740" width="540" height="220" fill="#b8a48a"/>
 <g stroke="#a6927a" stroke-width="3"><path d="M0 800H540M0 870H540"/></g>
 <rect x="30" y="140" width="480" height="300" rx="8" fill="#8f9aa0"/><rect x="42" y="152" width="456" height="276" fill="#fbfcfb"/><rect x="60" y="436" width="420" height="10" fill="#7f8a90"/>
 <rect x="80" y="430" width="30" height="8" rx="3" fill="#3d6fb0"/><rect x="118" y="430" width="30" height="8" rx="3" fill="#c8553d"/></g>
 <clipPath id="wclip"><rect class="wc" x="42" y="152" width="0" height="276"/></clipPath>
 <g clip-path="url(#wclip)" text-anchor="middle"><text class="b1" x="270" y="320" font-family="Kanit" font-weight="800" font-size="120" fill="#2f5fa8"></text><text class="b2" x="270" y="390" font-family="Kanit" font-style="italic" font-size="38" fill="#c8553d"></text></g>`);
 return {g,write(a,b,k){g.querySelector('.b1').textContent=a;g.querySelector('.b2').textContent=b;g.querySelector('.wc').setAttribute('width',456*k)},update(){}}}
