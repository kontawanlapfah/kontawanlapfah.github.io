#!/bin/sh
# Placeholder market ambience + cartoon SFX (no voices yet). Usage: sh make-audio.sh out.wav
P(){ echo "0.28*gte(t,$1)*exp(-(t-$1)*22)*sin(2*PI*$2*(t-$1))"; }
E="$(P 9.7 900)+$(P 17.0 900)+$(P 32.0 700)+$(P 33.4 800)+$(P 34.8 950)+$(P 42.5 660)+$(P 42.65 880)"
E="$E+0.3*gte(t,13.1)*lt(t,14.2)*exp(-(t-13.1)*3)*sin(2*PI*(420-200*(t-13.1))*(t-13.1))"
E="$E+0.22*gte(t,31.2)*exp(-(t-31.2)*3)*sin(2*PI*1320*(t-31.2))+0.15*gte(t,27.8)*lt(t,28.4)*sin(2*PI*(500+900*(t-27.8))*(t-27.8))"
E="$E+0.12*gte(t,24.5)*lt(t,27.6)*gt(sin(2*PI*8*t),0)*sin(2*PI*1200*t)"
ffmpeg -y -loglevel error \
 -f lavfi -i "anoisesrc=color=pink:amplitude=0.08:duration=47,lowpass=f=1200,highpass=f=150" \
 -f lavfi -i "aevalsrc='$E':s=44100:d=47" \
 -filter_complex "[0][1]amix=inputs=2:normalize=0,afade=t=in:d=1,afade=t=out:st=45.5:d=1.5" -ar 44100 "$1"
