// node engine/voice.js <skitDir> <tmpDir>
// Reads <skitDir>/voice.json, cuts voice lines, stretches the timeline to fit them, writes
// <skitDir>/voice/timing.js and <tmpDir>/a.wav (ambience + sfx + voices). Prints the new duration.
const fs=require('fs'),path=require('path'),{execFileSync}=require('child_process');
const [dir,tmp]=process.argv.slice(2),cfg=JSON.parse(fs.readFileSync(path.join(dir,'voice.json')));
const ff=a=>execFileSync('ffmpeg',['-y','-loglevel','error',...a]);
const lines=cfg.lines.map((l,i)=>{const out=path.join(tmp,`v${i}.wav`);
 ff(['-i',path.resolve(dir,l.src),...(l.from!=null?['-ss',''+l.from,'-to',''+l.to]:[]),'-af','silenceremove=stop_periods=-1:stop_duration=0.3:stop_threshold=-38dB:stop_silence=0.22,areverse,silenceremove=start_periods=1:start_threshold=-40dB,areverse,silenceremove=start_periods=1:start_threshold=-40dB','-ac','1','-ar','44100',out]);
 const raw=execFileSync('ffmpeg',['-loglevel','error','-i',out,'-f','s16le','-ac','1','-ar','8000','-']);
 const n=raw.length/2,hop=160,env=[];let mx=1;for(let i=0;i+hop<=n;i+=hop){let s=0;for(let j=0;j<hop;j++){const v=raw.readInt16LE((i+j)*2);s+=v*v}const r=Math.sqrt(s/hop);env.push(r);mx=Math.max(mx,r)}
 return {...l,out,len:n/8000,env:env.map(v=>+(v/mx).toFixed(2))}});
// warp segments
const W=lines.map(l=>{const need=l.len+0.45,orig=l.cueEnd-l.cue;return [l.cue,l.cueEnd,Math.max(orig,need)]}).sort((x,y)=>x[0]-y[0]);
const warp=ot=>{let sh=0;for(const[a,b,L]of W){if(ot<a)return ot+sh;if(ot<b)return a+sh+(ot-a)*L/(b-a);sh+=L-(b-a)}return ot+sh};
const dur=+warp(cfg.dur).toFixed(2);
const VOX=lines.map(l=>({a:l.cue,start:+(warp(l.cue)+0.15).toFixed(3),env:l.env}));
fs.mkdirSync(path.join(dir,'voice'),{recursive:true});
fs.writeFileSync(path.join(dir,'voice/timing.js'),`window.WARP=${JSON.stringify(W)};\nwindow.VOX=${JSON.stringify(VOX)};\n`);
const sfx=(cfg.sfx||'').split(',').filter(Boolean).map(s=>{const[k,v]=s.split('@');return k+'@'+v.split('-').map(x=>warp(+x).toFixed(2)).join('-')}).join(',');
execFileSync('node',[path.join(__dirname,'sfx.js'),path.join(tmp,'bg.wav'),''+dur,sfx]);
const ins=['-i',path.join(tmp,'bg.wav')],fl=[];lines.forEach((l,i)=>{ins.push('-i',l.out);const ms=Math.round((warp(l.cue)+0.15)*1000);fl.push(`[${i+1}]adelay=${ms}|${ms},volume=1.6[v${i}]`)});
ff([...ins,'-filter_complex',fl.join(';')+(fl.length?';':'')+`[0]${lines.map((_,i)=>`[v${i}]`).join('')}amix=inputs=${lines.length+1}:normalize=0,alimiter=limit=0.89[o]`,'-map','[o]','-ar','44100',path.join(tmp,'a.wav')]);
console.log(dur);
