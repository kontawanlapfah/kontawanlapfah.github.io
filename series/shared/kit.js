// Shared engine, helpers and characters for สี่สิบวันของอาดัม (EP02 onward).
//
// An episode page loads kit.css + kit.js (+ audio/warp.js once a voiceover exists),
// declares CAPS one caption per line (align.py reads them), draws its scenes with
// KIT.S(id, svg) and calls KIT.episode({...}). Everything on screen is a function
// of time, so every render is identical.

// ---------- helpers ----------
const clamp = (x, a = 0, b = 1) => Math.max(a, Math.min(b, x));
const ease = x => { x = clamp(x); return x < .5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2; };
const back = (x, c = 1.2) => { x = clamp(x); return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
const win = (t, a, b, f = .4) => Math.min(clamp((t - a) / f), clamp((b - t) / f));
const lerp = (a, b, k) => a + (b - a) * k;
let seed = 11; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const $ = id => document.getElementById(id);
const attr = (id, k, v) => { const e = $(id); if (e) e.setAttribute(k, v); };
const lerpMap = (x, xs, ys) => { if (x <= xs[0]) return ys[0]; for (let i = 1; i < xs.length; i++) if (x <= xs[i]) return ys[i - 1] + (ys[i] - ys[i - 1]) * (x - xs[i - 1]) / (xs[i] - xs[i - 1]); return ys[ys.length - 1]; };

const KIT = {};
KIT.S = (id, svg) => { $(id).querySelector('svg').innerHTML = svg; };
KIT.zoom = (id, s) => { $(id).querySelector('svg').style.transform = `scale(${s})`; };

// ---------- props ----------
KIT.bread = (x, y, s = 1, fresh = true, id = '') => `
  <g ${id ? `id="${id}"` : ''} transform="translate(${x} ${y}) scale(${s})">
    <ellipse cx="0" cy="0" rx="120" ry="62" fill="${fresh ? '#b8732f' : '#8c6a45'}"/>
    <ellipse cx="0" cy="-12" rx="104" ry="44" fill="${fresh ? '#d9954a' : '#a3825a'}"/>
    ${fresh ? '<path d="M-60 -30 q20 -14 40 0 M-10 -34 q20 -14 40 0 M40 -28 q16 -10 32 2" stroke="#f3c27a" stroke-width="6" fill="none" stroke-linecap="round"/>'
            : '<path d="M-50 -20 l30 10 l-8 14 M20 -26 l18 22 M50 -6 l-24 8" stroke="#6e5236" stroke-width="4" fill="none"/>'}
  </g>`;
KIT.steam = (pfx, x, y, n = 3) => Array.from({ length: n }, (_, i) =>
  `<path id="${pfx}${i}" data-x="${x + (i - (n - 1) / 2) * 46}" data-y="${y}" d="" stroke="rgba(255,240,220,.5)" stroke-width="7" fill="none" stroke-linecap="round"/>`).join('');
KIT.updSteam = (pfx, n, t, h = 170, op = 1) => {
  for (let i = 0; i < n; i++) {
    const e = $(pfx + i); if (!e) continue;
    const p = (t * .5 + i * .33) % 1, ph = t * 2 + i;
    let d = 'M0 0'; for (let k = 1; k <= 6; k++) d += ` L${Math.sin(ph + k * .9) * 14 * (k / 6)} ${-k * h / 6}`;
    e.setAttribute('d', d); e.setAttribute('opacity', Math.sin(p * Math.PI) * .9 * op);
    e.setAttribute('transform', `translate(${e.dataset.x} ${+e.dataset.y - p * 40})`);
  }
};
KIT.lantern = (p, x, y) => `
  <g transform="translate(${x} ${y})">
    <circle id="${p}glow" cx="0" cy="40" r="420" fill="url(#${p}lg)"/>
    <radialGradient id="${p}lg"><stop offset="0" stop-color="#ffb35c" stop-opacity=".5"/><stop offset="1" stop-color="#ffb35c" stop-opacity="0"/></radialGradient>
    <path d="M-40 -40 h50 v20" stroke="#3a2a1c" stroke-width="8" fill="none"/>
    <path d="M-22 -20 h44 l8 16 v70 l-8 16 h-44 l-8 -16 v-70z" fill="#2a1d12" stroke="#c9a45e" stroke-width="4"/>
    <rect x="-18" y="0" width="36" height="58" fill="#ffcf8a" opacity=".35"/>
    <ellipse id="${p}flame" cx="0" cy="30" rx="9" ry="18" fill="#ffd27a"/>
  </g>`;
KIT.updLantern = (p, t) => {
  const fl = 1 + Math.sin(t * 13) * .06 + Math.sin(t * 7.3) * .05;
  attr(p + 'flame', 'ry', 18 * fl); attr(p + 'glow', 'opacity', .85 + Math.sin(t * 9) * .08);
};
// wristwatch with hour / minute / second hands; size is the dial radius
KIT.watch = (p, x, y, r = 56) => `
  <g transform="translate(${x} ${y})">
    <circle r="${r * 1.2}" fill="#cfc6b4" stroke="#8a7a62" stroke-width="${r * .18}"/>
    <circle r="${r}" fill="#f4efe4"/>
    ${Array.from({ length: 12 }, (_, i) => `<line x1="0" y1="${-r * .9}" x2="0" y2="${-r * (i % 3 ? .8 : .72)}" stroke="#333" stroke-width="${r * (i % 3 ? .04 : .07)}" transform="rotate(${i * 30})"/>`).join('')}
    <line id="${p}h" x1="0" y1="0" x2="0" y2="${-r * .5}" stroke="#222" stroke-width="${r * .1}" stroke-linecap="round"/>
    <line id="${p}m" x1="0" y1="0" x2="0" y2="${-r * .76}" stroke="#222" stroke-width="${r * .07}" stroke-linecap="round"/>
    <line id="${p}s" x1="0" y1="${r * .15}" x2="0" y2="${-r * .85}" stroke="#c0392b" stroke-width="${r * .035}"/>
    <circle r="${r * .08}" fill="#222"/>
  </g>`;
// clock time in hours (e.g. 5.25 = 5:15:00); sec drives the red hand
KIT.setWatch = (p, hours, sec) => {
  attr(p + 'h', 'transform', `rotate(${hours * 30})`);
  attr(p + 'm', 'transform', `rotate(${hours * 360})`);
  attr(p + 's', 'transform', `rotate(${Math.floor(sec) * 6})`);
};
// row of ten verse dots (the series' ten verses of al-Kahf)
KIT.dots = (p, y) => Array.from({ length: 10 }, (_, i) => `<circle id="${p}${i}" cx="${315 + i * 50}" cy="${y}" r="14" fill="#e9c47e" opacity=".18"/>`).join('');
KIT.setDots = (p, lit, t, t0) => { for (let i = 0; i < 10; i++) attr(p + i, 'opacity', i < lit ? .18 + .82 * ease((t - t0 - i * .2) / .4) : .18); };

// ---------- characters (stylised: faces left without features) ----------
const SKIN = '#c99a7b', HAIR = '#2a1a12';
KIT.salma = (x, y) => `
  <g transform="translate(${x} ${y})">
    <path d="M-150 0 C-160 -120 -120 -230 -60 -260 L60 -260 C120 -230 160 -120 150 0 Z" fill="#3d4f57"/>
    <path d="M-62 -262 C-90 -330 -70 -420 0 -430 C70 -420 90 -330 62 -262 C40 -240 -40 -240 -62 -262Z" fill="#56707a"/>
    <ellipse cx="0" cy="-345" rx="44" ry="52" fill="${SKIN}"/>
    <path d="M-50 -350 C-52 -410 52 -410 50 -350 C46 -395 -46 -395 -50 -350Z" fill="#56707a"/>
  </g>`;
// Hawa, five, hair past the shoulders. Origin between the feet.
KIT.hawa = p => `
  <g id="${p}">
    <path d="M-50 -272 C-64 -210 -62 -165 -50 -140 L50 -140 C62 -165 64 -210 50 -272Z" fill="${HAIR}"/>
    <g id="${p}LegL"><rect x="-26" y="-122" width="22" height="114" rx="10" fill="${SKIN}"/><ellipse cx="-17" cy="-6" rx="19" ry="9" fill="#5a2f22"/></g>
    <g id="${p}LegR"><rect x="4" y="-122" width="22" height="114" rx="10" fill="${SKIN}"/><ellipse cx="17" cy="-6" rx="19" ry="9" fill="#5a2f22"/></g>
    <g id="${p}ArmL"><rect x="-50" y="-228" width="18" height="98" rx="9" fill="${SKIN}"/></g>
    <g id="${p}ArmR"><rect x="32" y="-228" width="18" height="98" rx="9" fill="${SKIN}"/></g>
    <path d="M-34 -234 C-42 -190 -62 -140 -68 -102 L68 -102 C62 -140 42 -190 34 -234Z" fill="#a8583f"/>
    <path d="M-34 -234 L-50 -205 L-32 -200Z M34 -234 L50 -205 L32 -200Z" fill="#a8583f"/>
    <rect x="-9" y="-252" width="18" height="22" fill="${SKIN}"/>
    <circle cx="0" cy="-286" r="38" fill="${SKIN}"/>
    <path d="M-42 -280 C-52 -342 52 -342 42 -280 C36 -312 -36 -312 -42 -280Z" fill="${HAIR}"/>
  </g>`;
// walk cycle: k in 0..1 along the path, walking=true swings legs
KIT.poseHawa = (p, x, y, t, walking, lean = 0, armR = 0) => {
  const ph = t * 2 * Math.PI * 1.3, sw = walking ? Math.sin(ph) * 20 : 0, bob = walking ? -Math.abs(Math.sin(ph)) * 7 : 0;
  attr(p, 'transform', `translate(${x} ${y + bob}) rotate(${lean})`);
  attr(p + 'LegL', 'transform', `rotate(${sw} -15 -122)`); attr(p + 'LegR', 'transform', `rotate(${-sw} 15 -122)`);
  attr(p + 'ArmL', 'transform', `rotate(${-sw * .8} -41 -226)`); attr(p + 'ArmR', 'transform', `rotate(${sw * .8 + armR} 41 -226)`);
};
// Adam, 27: short hair, short beard, beige shirt. Standing, origin between the feet (about 560 px tall).
KIT.adam = p => `
  <g id="${p}">
    <rect x="-44" y="-262" width="38" height="252" rx="16" fill="#3a3a44"/><rect x="6" y="-262" width="38" height="252" rx="16" fill="#3a3a44"/>
    <ellipse cx="-26" cy="-8" rx="30" ry="12" fill="#1e1a17"/><ellipse cx="26" cy="-8" rx="30" ry="12" fill="#1e1a17"/>
    <g id="${p}ArmL"><rect x="-96" y="-462" width="34" height="200" rx="16" fill="#cdbb9a"/><circle cx="-79" cy="-258" r="18" fill="${SKIN}"/></g>
    <g id="${p}ArmR"><rect x="62" y="-462" width="34" height="200" rx="16" fill="#cdbb9a"/><circle cx="79" cy="-258" r="18" fill="${SKIN}"/></g>
    <path d="M-66 -470 C-80 -400 -70 -300 -60 -250 L60 -250 C70 -300 80 -400 66 -470 C40 -490 -40 -490 -66 -470Z" fill="#cdbb9a"/>
    <rect x="-14" y="-506" width="28" height="40" fill="${SKIN}"/>
    <ellipse cx="0" cy="-548" rx="44" ry="52" fill="${SKIN}"/>
    <path d="M-42 -530 C-40 -488 -18 -476 0 -476 C18 -476 40 -488 42 -530 C34 -506 -34 -506 -42 -530Z" fill="${HAIR}" opacity=".85"/>
    <path d="M-46 -556 C-54 -620 54 -620 46 -556 C38 -590 -38 -590 -46 -556Z" fill="${HAIR}"/>
  </g>`;
// Adam kneeling (to hold Hawa). Origin at the knee on the floor.
KIT.adamKneel = p => `
  <g id="${p}">
    <path d="M-70 0 h150 a20 20 0 0 0 0 -40 h-110 Z" fill="#3a3a44"/>
    <rect x="-80" y="-170" width="40" height="170" rx="18" fill="#3a3a44"/>
    <path d="M-110 -380 C-124 -310 -110 -220 -96 -160 L30 -160 C40 -220 50 -310 30 -380 C10 -400 -90 -400 -110 -380Z" fill="#cdbb9a"/>
    <rect x="-52" y="-416" width="28" height="40" fill="${SKIN}"/>
    <ellipse cx="-38" cy="-458" rx="44" ry="52" fill="${SKIN}"/>
    <path d="M-80 -440 C-78 -398 -56 -386 -38 -386 C-20 -386 2 -398 4 -440 C-4 -416 -72 -416 -80 -440Z" fill="${HAIR}" opacity=".85"/>
    <path d="M-84 -466 C-92 -530 16 -530 8 -466 C0 -500 -76 -500 -84 -466Z" fill="${HAIR}"/>
  </g>`;
// seated on the floor, seen from behind. Origin at the floor under the body.
KIT.adamBack = p => `
  <g id="${p}">
    <ellipse cx="0" cy="-30" rx="170" ry="48" fill="#3a3a44"/>
    <path d="M-120 -40 C-130 -160 -100 -270 -70 -300 L70 -300 C100 -270 130 -160 120 -40Z" fill="#cdbb9a"/>
    <rect x="-16" y="-330" width="32" height="34" fill="${SKIN}"/>
    <ellipse cx="0" cy="-372" rx="46" ry="52" fill="${HAIR}"/>
    <ellipse cx="-46" cy="-366" rx="8" ry="14" fill="${SKIN}"/><ellipse cx="46" cy="-366" rx="8" ry="14" fill="${SKIN}"/>
  </g>`;
// Shaykh Yahya, elderly teacher, seen from behind: white thobe and white turban, grey hair at the nape.
KIT.sheikhBack = p => `
  <g id="${p}">
    <ellipse cx="0" cy="-30" rx="180" ry="50" fill="#d9d2c2"/>
    <path d="M-130 -40 C-140 -170 -110 -270 -66 -300 L66 -300 C110 -270 140 -170 130 -40Z" fill="#ece6d8"/>
    <path d="M-60 -296 C-40 -200 -30 -120 -36 -40 M50 -290 C34 -200 30 -120 34 -40" stroke="#d2cab8" stroke-width="5" fill="none"/>
    <rect x="-18" y="-332" width="36" height="38" fill="#b98a6c"/>
    <path d="M-40 -340 C-44 -320 -30 -306 0 -306 C30 -306 44 -320 40 -340Z" fill="#c9c4bb"/>
    <ellipse cx="0" cy="-376" rx="50" ry="48" fill="#f3efe6"/>
    <path d="M-50 -380 C-30 -398 30 -398 50 -380 M-48 -362 C-28 -378 28 -378 48 -362" stroke="#d8d0bf" stroke-width="5" fill="none"/>
    <path d="M52 -350 C64 -330 62 -300 50 -290 C46 -310 46 -330 52 -350Z" fill="#e8e4dc"/>
  </g>`;
// Harith, a dark silhouette in a doorway: rim light, eyes, drips. Origin between the feet, faces the viewer.
KIT.harith = p => `
  <g id="${p}">
    <path d="M-160 0 C-160 -190 -140 -330 -100 -390 C-70 -430 70 -430 100 -390 C140 -330 160 -190 160 0Z" fill="#14171d"/>
    <path d="M-100 -390 C-70 -430 70 -430 100 -390" stroke="#7ea3c8" stroke-width="6" fill="none" opacity=".6"/>
    <rect x="-25" y="-480" width="50" height="70" fill="#14171d"/>
    <ellipse cx="0" cy="-550" rx="80" ry="96" fill="#14171d"/>
    <path d="M-78 -570 C-70 -660 70 -660 78 -570" stroke="#7ea3c8" stroke-width="6" fill="none" opacity=".6"/>
    <ellipse id="${p}EyeL" cx="-28" cy="-550" rx="9" ry="5" fill="#d8e6f2" opacity=".35"/>
    <ellipse id="${p}EyeR" cx="28" cy="-550" rx="9" ry="5" fill="#d8e6f2" opacity=".35"/>
    <g id="${p}Arms"><path d="M-110 -290 C-70 -230 -20 -220 0 -230 C20 -220 70 -230 110 -290" stroke="#14171d" stroke-width="48" fill="none" stroke-linecap="round"/></g>
  </g>`;
KIT.harithEyes = (p, cold) => ['EyeL', 'EyeR'].forEach(e => { attr(p + e, 'opacity', .35 + .65 * cold); attr(p + e, 'fill', cold > .5 ? '#eaf6ff' : '#d8e6f2'); });

// ---------- engine ----------
KIT.episode = cfg => {
  const stage = $('stage');
  const ids = [...new Set(cfg.scenes.map(s => s[0]))];
  stage.insertAdjacentHTML('afterbegin', ids.map(id => `<section class="scene" id="${id}"><svg viewBox="0 0 1080 1920"></svg></section>`).join('') + '<div id="shade"></div>');
  stage.insertAdjacentHTML('beforeend', `
    <div id="titleDim"></div>
    <div class="overlay" id="title"><div class="t-series">สี่สิบวัน<br>ของอาดัม</div><div class="t-ep">ตอนที่ ${cfg.num}</div><div class="t-name">${cfg.name}</div><div class="t-latin">THE ERA OF DAJJAL</div></div>
    <div class="overlay" id="cta"><div class="cta">${cfg.cta}</div></div>
    <div class="overlay" id="disc"><div class="disc-h">คำเตือน</div>
      <div class="disc">เรื่องราวนี้เป็นการจำลองสถานการณ์สมมติ<br>เพื่อการศึกษาและสร้างความเข้าใจเกี่ยวกับฟิตนะฮ์ของดัจญาล<br>โดยมีการอ้างอิงข้อมูลจากอัลกุรอานและหะดีษที่เชื่อถือได้<br>ตัวละคร บทสนทนา และรายละเอียดบางส่วน<br>เป็นจินตนาการเพื่อประกอบการเล่าเรื่อง<br>ไม่ใช่เหตุการณ์จริงหรือคำรายงานทางศาสนา<br>โปรดแยกแยะระหว่างหลักฐานทางศาสนา<br>กับส่วนที่เป็นเรื่องสมมติ</div>
      <div class="refs">${cfg.refs}</div><div class="logo">สี่สิบวันของอาดัม</div></div>
    <div id="outro"><div id="outroDim"></div><div id="popup"><div id="logoWrap"><div id="logoRing"></div><img id="logoImg" src="../shared/logo.png" alt="ก่อนตะวันลับฟ้า"></div><div id="subPill">Subscribe • Follow</div></div></div>
    <div id="caps">${cfg.caps.map(([a, b, cls, txt], i) => `<div class="cap ${cls}" id="cap${i}">${txt}</div>`).join('')}
      ${(cfg.tags || []).map(([a, b, txt], i) => `<div class="tag" id="tag${i}"><span>${txt}</span></div>`).join('')}</div>
    <img id="mark" src="../shared/logo-mark.png" alt="ก่อนตะวันลับฟ้า">`);
  cfg.build();
  // each source tag holds one height for its whole window: the tallest caption it sits over
  (cfg.tags || []).forEach(([a, b], i) => {
    const h = Math.max(70, ...cfg.caps.map(([ca, cb], j) => (ca < b && cb > a) ? $('cap' + j).offsetHeight : 0));
    $('tag' + i).style.bottom = (h + 16) + 'px';
  });

  const [t0, t1] = cfg.title, [c0, c1] = cfg.ctaWin, [d0, d1] = cfg.discWin, o0 = cfg.outroAt, END = cfg.total;
  function frame(t) {
    const vis = {};
    for (const [id, a, b, opt = {}] of cfg.scenes) {
      let v;
      if (a === 0) v = t < b ? clamp((b - t) / .4) : 0;                         // frame 0 is already the hook
      else if (opt.hardOut) v = t >= a && t < b ? clamp((t - a) / .4) : 0;      // hard cut at the end
      else if (opt.cut) v = t >= a && t < b ? 1 : 0;                            // straight cut
      else v = win(t, a, b);
      vis[id] = Math.max(vis[id] || 0, v);
    }
    for (const id in vis) $(id).style.opacity = vis[id];
    $('shade').style.opacity = t < c0 - .3 ? 1 : 0;
    // one motion for every caption: fade in with a short rise, fade out in place, never overlapping
    cfg.caps.forEach(([a, b], i) => {
      const kin = a === 0 ? 1 : clamp((t - a) / .3), kout = clamp((b - t) / .22);
      const c = $('cap' + i); c.style.opacity = Math.min(kin, kout); c.style.transform = `translateY(${(1 - ease(kin)) * 14}px)`;
    });
    (cfg.tags || []).forEach(([a, b], i) => { $('tag' + i).style.opacity = Math.min(clamp((t - a) / .3), clamp((b - t) / .22)); });
    // cards: lines come in one after another with the same rise, leave together without moving
    [['title', t0, t1], ['cta', c0, c1], ['disc', d0, d1]].forEach(([id, a, b]) => {
      const box = $(id), out = clamp((b - t) / .4);
      box.style.opacity = t > a - .1 && t < b ? 1 : 0;
      [...box.children].forEach((el, j) => {
        const kin = clamp((t - a - j * .14) / .45);
        el.style.opacity = Math.min(kin, out); el.style.transform = `translateY(${(1 - ease(kin)) * 18}px)`;
      });
    });
    $('titleDim').style.opacity = .7 * Math.min(clamp((t - t0 + .2) / .5), clamp((t1 - t) / .4));
    const u = t - o0;                                                           // closing pop-up
    $('outro').style.opacity = clamp(u / .4);
    const lg = $('logoWrap'), pill = $('subPill');
    lg.style.opacity = clamp((u - .15) / .3); lg.style.transform = `scale(${.86 + .14 * back((u - .15) / .5)})`;
    $('logoRing').style.opacity = clamp((u - .4) / .4);
    const q = clamp((u - .7) / .4); pill.style.opacity = q; pill.style.transform = `translateY(${(1 - ease(q)) * 22}px)`;
    cfg.draw(t);
  }
  // authored timeline -> voiceover timeline (audio/warp.js from build_timing.py)
  const WA = window.WARP ? window.WARP.anchors : [[0, 0], [END, END]];
  const toOld = T => lerpMap(T, WA.map(a => a[1]), WA.map(a => a[0]));
  const toNew = t => lerpMap(t, WA.map(a => a[0]), WA.map(a => a[1]));
  window.setFrame = T => frame(toOld(T));
  window.TOTAL = window.WARP ? window.WARP.total : END;
  window.KEYS = cfg.keys.map(([t, n]) => [+toNew(t).toFixed(2), n]);
  const q = new URLSearchParams(location.search);
  if (q.has('t')) window.setFrame(+q.get('t'));
  else if (!q.has('render')) { const s = performance.now(); (function loop() { window.setFrame(((performance.now() - s) / 1000) % window.TOTAL); requestAnimationFrame(loop); })(); }
};
