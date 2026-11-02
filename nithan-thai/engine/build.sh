#!/bin/sh
# sh engine/build.sh <skitDir> <seconds> "<sfx spec>"  -> <skitDir>/<name>-preview.mp4 (720x1280)
# If <skitDir>/voice.json exists, real voice lines are mixed in and the timeline is stretched to fit them.
set -e; D=$1; N=$(basename $D); TMP=${TMPDIR:-/tmp}/nt-$N; rm -rf $TMP; mkdir -p $TMP
E=$(dirname $0); DUR=$2
if [ -f $D/voice.json ]; then DUR=$(node $E/voice.js $D $TMP); else mkdir -p $D/voice; echo "" > $D/voice/timing.js; node $E/sfx.js $TMP/a.wav $DUR "$3"; fi
node $E/render.js $D/scene.html $TMP 24 $DUR
ffmpeg -y -loglevel error -framerate 24 -i $TMP/f%04d.png -i $TMP/a.wav -c:v libx264 -pix_fmt yuv420p -crf 21 -c:a aac -b:a 160k -shortest $D/$N-preview.mp4
rm -rf $TMP; echo done $D/$N-preview.mp4 $DUR
