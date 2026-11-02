// Voice timing helpers (loaded after <skit>/voice/timing.js, which may define WARP and VOX).
// WARP: [[origStart, origEnd, newLen], ...] stretches cue windows to fit real voice clips.
// VOX:  [{a: origCueStart, start: realStart, env: [0..1 @50Hz]}] drives lip-sync from audio loudness.
window.WARP=window.WARP||[];window.VOX=window.VOX||[];window.RT=0;
function unwarp(rt){let sh=0;for(const[a,b,L]of WARP){const na=a+sh;if(rt<na)return rt-sh;if(rt<na+L)return a+(rt-na)*(b-a)/L;sh+=L-(b-a)}return rt-sh}
function voxTalk(a){const v=VOX.find(v=>Math.abs(v.a-a)<.01);if(!v)return undefined;const i=Math.floor((RT-v.start)*50);return i>=0&&i<v.env.length&&v.env[i]>.14}
