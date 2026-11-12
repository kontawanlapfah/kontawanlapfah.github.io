#!/usr/bin/env bash
# Free from @barakahraaz on Instagram. Not for sale.
# usage: bash render.sh <reel-folder> [poster-seconds]
# Captures every frame, adds motion blur to fast frames (REEL_BLUR=0 skips it), mixes the sound,
# encodes reel.mp4 with the poster as frame 0, writes poster.jpg, and copies sfx.json next to it for the sync check.
# Frames and wavs go to a temp folder. reel.mp4 and poster.jpg go to:
# $REEL_OUT/<path after reels/> (default: the kit folder's "03 - export/..."). The reel folder keeps only the source.
set -euo pipefail
# Homebrew tools installed in this session are found too (appended, so the user's own tools still win), as in .kit/setup.sh.
for d in /opt/homebrew /usr/local; do
  case ":$PATH:" in *":$d/bin:"*) ;; *) [ -d "$d/bin" ] && PATH="$PATH:$d/bin:$d/sbin" ;; esac
done
# Windows: tools winget installed in this session are found too. The shell keeps the PATH it started with,
# so read the saved PATH again; ~/bin holds the python3 shim from .kit/setup.ps1.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*)
  w=$(powershell.exe -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')" 2>/dev/null | tr -d '\r') || w=
  [ -n "$w" ] && PATH="$PATH:$(cygpath -p "$w")"
  [ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH" ;;
esac
export PATH
here="$(cd "$(dirname "$0")" && pwd)"
dir="$(cd "$1" && pwd)"
poster="${2:-0}"
rel="${dir#*/reels/}"; [ "$rel" = "$dir" ] && rel="$(basename "$dir")"
root="$(cd "$here/../../../.." && pwd)"  # the kit folder, 4 levels above this scripts folder
out="${REEL_OUT:-$root/03 - export}/$rel"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"

node "$here/capture.mjs" "$dir" frames "$tmp/frames"
if [ "${REEL_BLUR:-1}" != 0 ]; then
  python3 "$here/blur.py" detect "$tmp/frames" "$tmp/blur.json"
  node "$here/capture.mjs" "$dir" sub "$tmp/blur.json" "$tmp/sub"
  python3 "$here/blur.py" merge "$tmp/frames" "$tmp/sub"
fi
python3 "$here/mix.py" "$dir" "$tmp"

# poster as frame 0, so the idle thumbnail is a settled frame; then one encode
f=$(printf '%05d' "$(python3 -c "print(round($poster*30))")")
cp "$tmp/frames/$f.jpg" "$out/poster.jpg"
cp "$out/poster.jpg" "$tmp/frames/00000.jpg"
ffmpeg -loglevel error -y -framerate 30 -i "$tmp/frames/%05d.jpg" -i "$tmp/audio.wav" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart "$out/reel.mp4"
n=$(find "$tmp/frames" -name '[0-9]*.jpg' | wc -l | tr -d ' ')
m=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nw=1:nk=1 "$out/reel.mp4" | tr -dc 0-9)
if [ "$n" != "$m" ]; then
  echo "Frame count mismatch: captured $n, encoded $m. The sound file may be shorter than the video." >&2; exit 1
fi
cp "$tmp/audio.wav" "$out/audio.wav"
cp "$dir/sfx.json" "$out/sfx.json"
echo "done: $out/reel.mp4"
echo "check: ffmpeg -loglevel error -y -i '$out/reel.mp4' -vf 'fps=1/5,scale=270:-1,tile=6x3' -frames:v 1 '$out/sheet.jpg'"
