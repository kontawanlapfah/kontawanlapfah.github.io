// node engine/sfx.js out.wav <dur> "pop@9.7,ding@31.2,shock@13.1,rise@27.8,bleep@24.5-27.6,msg@3.0,type@7.3-8.2"
const {execFileSync}=require('child_process');const [out,dur,spec='']=process.argv.slice(2);
const g=(a)=>`gte(t,${a})`,d=(a)=>`(t-${a})`;
const T={pop:a=>`0.28*${g(a)}*exp(-${d(a)}*22)*sin(2*PI*900*${d(a)})`,
 ding:a=>`0.22*${g(a)}*exp(-${d(a)}*3)*sin(2*PI*1320*${d(a)})`,
 shock:a=>`0.3*${g(a)}*lt(t,${+a+1.1})*exp(-${d(a)}*3)*sin(2*PI*(420-200*${d(a)})*${d(a)})`,
 rise:a=>`0.15*${g(a)}*lt(t,${+a+.6})*sin(2*PI*(500+900*${d(a)})*${d(a)})`,
 msg:a=>`0.22*${g(a)}*exp(-${d(a)}*25)*sin(2*PI*1050*${d(a)})+0.22*${g(+a+.09)}*exp(-${d(+a+.09)}*20)*sin(2*PI*1400*${d(+a+.09)})`,
 bleep:(a,b)=>`0.12*${g(a)}*lt(t,${b})*gt(sin(2*PI*8*t),0)*sin(2*PI*1200*t)`,
 type:(a,b)=>`0.12*${g(a)}*lt(t,${b})*exp(-mod(t,0.11)*90)*sin(2*PI*3000*t)`,
 chalk:(a,b)=>`0.05*${g(a)}*lt(t,${b})*sin(2*PI*2200*t)*sin(2*PI*7*t)`};
const E=spec.split(',').filter(Boolean).map(s=>{const[k,v]=s.split('@');const[a,b]=v.split('-');return T[k](a,b)}).join('+')||'0';
execFileSync('ffmpeg',['-y','-loglevel','error','-f','lavfi','-i',`anoisesrc=color=pink:amplitude=0.07:duration=${dur},lowpass=f=1200,highpass=f=150`,
 '-f','lavfi','-i',`aevalsrc='${E}':s=44100:d=${dur}`,'-filter_complex',`[0][1]amix=inputs=2:normalize=0,afade=t=in:d=1,afade=t=out:st=${dur-1.5}:d=1.5`,'-ar','44100',out],{stdio:'inherit'});
