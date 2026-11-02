#!/bin/sh
# Placeholder ambience (wind, crickets, low drone, reveal hit) until the ElevenLabs narration is ready
ffmpeg -y -loglevel error \
 -f lavfi -i "anoisesrc=color=brown:amplitude=0.25:duration=30,lowpass=f=500,volume=0.5" \
 -f lavfi -i "aevalsrc='0.012*sin(2*PI*4300*t)*gt(sin(2*PI*2.2*t),0.55)*gt(sin(2*PI*45*t),0)*lt(t,17.5)+0.05*sin(2*PI*55*t)*min(1,t/4)+0.035*sin(2*PI*82.4*t)*min(1,t/6)+0.5*gte(t,21.5)*exp(-(t-21.5)*1.8)*sin(2*PI*38*t)+0.12*gte(t,21.5)*exp(-(t-21.5)*1.2)*sin(2*PI*233*t)':s=44100:d=30" \
 -filter_complex "[0][1]amix=inputs=2:normalize=0,afade=t=in:d=1.5,afade=t=out:st=28.5:d=1.5" -ar 44100 "$1"
