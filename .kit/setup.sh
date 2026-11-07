#!/usr/bin/env bash
# Free from @barakahraaz on Instagram. Not for sale.
# Reel skill setup checker for Mac. Claude runs this; the user never types it.
#   bash .kit/setup.sh --check             one line per missing tool ("missing: ffmpeg"), or "all ready". Always exits 0.
#   bash .kit/setup.sh --install <tool>    installs one tool. Tools: clt brew brew-terminal chrome ffmpeg node python python-packages obsidian playwright
set -uo pipefail

# Put Homebrew on PATH once, so a fresh install is seen by every later call.
# SETUP_NO_BREW=1 skips this (used by the test that strips PATH).
if [ -z "${SETUP_NO_BREW:-}" ]; then
  for d in /opt/homebrew /usr/local; do
    if [ -x "$d/bin/brew" ]; then
      case ":$PATH:" in *":$d/bin:"*) ;; *) PATH="$PATH:$d/bin:$d/sbin" ;; esac   # appended, so the user's own tools still win
      export PATH
      break
    fi
  done
fi

have() { command -v "$1" >/dev/null 2>&1; }

has_chrome() {
  [ -d "/Applications/Google Chrome.app" ] || [ -d "$HOME/Applications/Google Chrome.app" ] \
    || have google-chrome || have google-chrome-stable
}
has_obsidian() {
  [ -d "/Applications/Obsidian.app" ] || [ -d "$HOME/Applications/Obsidian.app" ]
}
has_clt() { xcode-select -p >/dev/null 2>&1; }
has_python() {
  have python3 || return 1
  # /usr/bin/python3 is a stub that pops a dialog until the Command Line Tools exist. Never run it before then.
  if [ "$(command -v python3)" = "/usr/bin/python3" ] && ! has_clt; then return 1; fi
  python3 -I -c 'import sys' >/dev/null 2>&1
}
# numpy, scipy and pillow for the sound mix, motion blur and checks. No -I here: a --user install lives in the
# user site folder, which -I hides, and the render runs plain python3. Run from / so no local file can shadow a package.
has_python_packages() {
  has_python || return 1
  (cd / && python3 -c "import numpy, scipy, PIL") >/dev/null 2>&1
}
python_packages() {
  has_python || { echo "Install python first." >&2; return 1; }
  local log
  log="$(cd / && python3 -m pip install --user numpy scipy pillow 2>&1)" && return 0
  # Homebrew's Python refuses --user installs (PEP 668, "externally-managed-environment"); only then retry past it.
  if printf '%s\n' "$log" | grep -q 'externally-managed-environment'; then
    (cd / && python3 -m pip install --user --break-system-packages numpy scipy pillow)
    return $?
  fi
  printf '%s\n' "$log" | tail -n 5 >&2
  return 1
}

has_playwright() {
  have npm || return 1
  local root
  root="$(npm root -g 2>/dev/null)" || return 1
  [ -n "$root" ] && [ -d "$root/playwright" ]
}

check() {
  local n=0
  has_clt || { echo "missing: clt"; n=1; }
  have brew || { echo "missing: brew"; n=1; }
  has_chrome || { echo "missing: chrome"; n=1; }
  have ffmpeg && have ffprobe || { echo "missing: ffmpeg"; n=1; }
  have node || { echo "missing: node"; n=1; }
  has_python || { echo "missing: python"; n=1; }
  has_python_packages || { echo "missing: python-packages"; n=1; }
  has_playwright || { echo "missing: playwright"; n=1; }
  has_obsidian || { echo "missing: obsidian"; n=1; }
  [ "$n" -eq 0 ] && echo "all ready"
  return 0
}

brew_terminal() {
  # Fallback: Terminal.app opens and runs the official Homebrew installer. The user types only their Mac password there.
  osascript -e 'tell application "Terminal" to activate' \
            -e 'tell application "Terminal" to do script "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""'
}

brew_pkg() {
  # Official Homebrew .pkg (Apple Silicon only). macOS shows its normal installer and the admin password dialog.
  [ "$(uname -m)" = "arm64" ] || { echo "The .pkg is for Apple Silicon only. Use: --install brew-terminal" >&2; return 1; }
  local d f
  d="$(mktemp -d)" || return 1
  f="$d/Homebrew.pkg"
  curl -fL --retry 2 -o "$f" "https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg" \
    || { echo "Download failed. Use: --install brew-terminal" >&2; return 1; }
  open "$f"
}

install() {
  case "$1" in
    clt)           xcode-select --install 2>&1 || true; return 0 ;;  # normal Mac dialog; check again afterwards
    brew)          brew_pkg; return $? ;;
    brew-terminal) brew_terminal; return $? ;;
    python-packages) python_packages; return $? ;;
    chrome|ffmpeg|node|python|obsidian|playwright) ;;
    *)             echo "Unknown tool: $1" >&2; return 2 ;;
  esac
  have brew || { echo "Homebrew is missing. Run: bash .kit/setup.sh --install brew" >&2; return 1; }
  case "$1" in
    chrome)     brew install --cask google-chrome ;;
    ffmpeg)     brew install ffmpeg ;;
    node)       brew install node ;;
    python)     brew install python ;;
    obsidian)   brew install --cask obsidian ;;
    playwright) have npm || { echo "Install node first." >&2; return 1; }
                npm install -g playwright ;;
  esac
}

case "${1:-}" in
  --check)   check ;;
  --install) [ -n "${2:-}" ] || { echo "usage: setup.sh --install <tool>" >&2; exit 2; }
             install "$2" ;;
  *)         echo "usage: setup.sh --check | --install <tool>" >&2; exit 2 ;;
esac
