// Overlay UI (header, thought bubble, 3-layer subtitles, lesson card, CTA) + helpers
const NS='http://www.w3.org/2000/svg',$=id=>document.getElementById(id);
function rnd(s){return()=>{s|=0;s=s+0x6D2B79F5|0;let t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
function el(tag,a,p){const e=document.createElementNS(NS,tag);for(const k in a)e.setAttribute(k,a[k]);p.appendChild(e);return e}
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x)),ease=x=>{x=clamp(x,0,1);return x*x*(3-2*x)},win=(t,a,b,f=.25)=>Math.min(ease((t-a)/f),1-ease((t-b)/f));
const talking=(t,a,b)=>{const v=typeof voxTalk=='function'?voxTalk(a):undefined;return v!==undefined?v:t>a&&t<b-.2&&Math.sin(t*19)>-.2};
const WHO={PUTRI:'#e3a19b',BIBI:'#7fc0ad',TON:'#8fb3e8',FAH:'#c9b3e8'};
function setupUI(cfg){const w=$('wrap');w.insertAdjacentHTML('beforeend',`
<div id="head"><div class="pill">${cfg.pill}</div><div class="ttl">${cfg.title}</div></div>
<div id="thought"><div class="cl"></div><div class="d1"></div><div class="d2"></div></div><div id="dim"></div>
<div id="card"><h2>${cfg.card.title}</h2><div class="sm">${cfg.card.sm}</div>${cfg.card.rows.map((r,i)=>`<div class="row" id="r${i}">${r.icon}<div class="w" style="color:${r.color};${r.fs?'font-size:'+r.fs+'px':''}">${r.w}</div><div><div class="r">${r.r}</div><div class="m">${r.m}</div></div></div>`).join('')}</div>
<div id="cta"><div class="q">${cfg.cta}</div><div class="logo">NithanTH</div></div>
<div id="cap"></div><div id="sub"><div class="who"></div><div class="th"></div><div class="ro"></div><div class="id"></div></div><div id="black"></div>`);
 if(cfg.thoughtCss)Object.assign($('thought').style,cfg.thoughtCss);
 const S=$('sub'),who=S.querySelector('.who'),sth=S.querySelector('.th'),sro=S.querySelector('.ro'),sid=S.querySelector('.id'),TH=$('thought'),THc=TH.querySelector('.cl');
 return function(t){
  let c=null;for(const q of cfg.cues)if(t>=q.a-.01&&t<=q.b+.3)c=q;
  if(c){const o=win(t,c.a,c.b,.3);S.style.opacity=o;sth.innerHTML=c.th;
   if(c.thought){THc.innerHTML=c.thought;TH.style.opacity=o;TH.style.transform=`scale(${.9+.1*ease((t-c.a)/.3)})`;who.style.display='none';sth.style.fontSize='24px';sro.textContent='';sid.textContent=''}
   else{TH.style.opacity=0;who.style.display=c.who?'':'none';who.textContent=c.who||'';who.style.background=WHO[c.who]||'#ddd';sth.style.fontSize='';sro.textContent=c.ro||'';sid.innerHTML=c.id||''}}
  else{TH.style.opacity=0;S.style.opacity=0}
  const [ca,cb]=cfg.card.at,cd=win(t,ca,cb,.4);$('card').style.opacity=cd;$('card').style.transform=`translateY(${(1-ease((t-ca)/.4))*40}px)`;
  cfg.card.rows.forEach((r,i)=>{const a=ca+.8+i*1.4,e=$('r'+i);e.style.opacity=ease((t-a)/.3);e.style.transform=`translateX(${(1-ease((t-a)/.3))*-20}px)`});
  const k=ease((t-cfg.ctaAt)/.4);$('cta').style.opacity=k;$('cta').style.transform=`scale(${.9+.1*k})`;
  $('dim').style.opacity=.55*cd+.6*k;$('head').style.opacity=1-.7*cd;
  let bl=1-ease(t/.8)+ease((t-cfg.dur+.6)/.6);if(cfg.cut){const[a,b,txt]=cfg.cut;const m=win(t,a,b,.5);bl=Math.max(bl,m*.92);$('cap').innerHTML=txt;$('cap').style.opacity=m}
  $('black').style.opacity=bl;
  const tb=document.getElementById('turb');if(tb)tb.setAttribute('seed',3+Math.floor(t*8)%4);
 }}
const ICON={
 rice:`<svg width="56" height="56" viewBox="0 0 56 56"><path d="M6 28 h44 q-2 20 -22 22 q-20 -2 -22 -22z" fill="#7aa58f"/><ellipse cx="28" cy="27" rx="20" ry="9" fill="#fff" stroke="#ddd"/></svg>`,
 boy:`<svg width="56" height="56" viewBox="0 0 56 56"><circle cx="28" cy="30" r="20" fill="#ecbca2"/><path d="M8 28 C6 8 50 8 48 28 C42 18 30 16 8 28Z" fill="#1d1a22"/><circle cx="21" cy="32" r="2.5"/><circle cx="35" cy="32" r="2.5"/><path d="M23 40 q5 4 10 0" stroke="#8a3f3a" stroke-width="2" fill="none"/></svg>`,
 girl:`<svg width="56" height="56" viewBox="0 0 56 56"><circle cx="28" cy="29" r="24" fill="#e3a19b"/><ellipse cx="28" cy="31" rx="15" ry="17" fill="#d9a184"/><circle cx="22" cy="31" r="2.5"/><circle cx="34" cy="31" r="2.5"/><path d="M23 39 q5 4 10 0" stroke="#8a3f3a" stroke-width="2" fill="none"/></svg>`,
 ask:`<svg width="56" height="56" viewBox="0 0 56 56"><circle cx="28" cy="28" r="22" fill="#c9b3e8"/><text x="28" y="40" text-anchor="middle" font-family="Kanit" font-weight="800" font-size="34" fill="#fff">?</text></svg>`,
 five:`<svg width="56" height="56" viewBox="0 0 56 56"><rect x="6" y="6" width="44" height="44" rx="10" fill="#e9c46a"/><text x="28" y="42" text-anchor="middle" font-family="Kanit" font-weight="800" font-size="36" fill="#1d2440">5</text></svg>`,
 laugh:`<svg width="56" height="56" viewBox="0 0 56 56"><circle cx="28" cy="28" r="22" fill="#ffd27a"/><path d="M16 24 q4 -5 8 0M32 24 q4 -5 8 0" stroke="#2b2430" stroke-width="2.5" fill="none"/><path d="M16 32 q12 16 24 0z" fill="#7a3a35"/></svg>`,
 indo:`<svg width="56" height="56" viewBox="0 0 56 56"><rect x="6" y="12" width="44" height="16" fill="#d8352a"/><rect x="6" y="28" width="44" height="16" fill="#fff" stroke="#ddd"/></svg>`};
