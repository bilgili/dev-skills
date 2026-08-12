#!/bin/sh
# Idempotent TLA+ toolchain installer (POSIX: macOS, Linux, Git Bash / WSL).
# Installs: JDK 11+, tla2tools.jar, `tlc`/`sany` PATH wrappers.
# Safe to re-run: each step is skipped when already present.
set -eu

JAR="$HOME/tools/tla2tools.jar"
BIN="$HOME/.local/bin"
JAR_URL="https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar"

echo "== TLA+ toolchain setup =="
OS=$(uname -s 2>/dev/null || echo unknown)

# 1. JDK 11+ (TLC/SANY are Java).
if java -version >/dev/null 2>&1; then
  echo "[ok] java present: $(java -version 2>&1 | head -1)"
else
  case "$OS" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        echo "[..] installing Temurin JDK via Homebrew"; brew install --cask temurin
      else
        echo "[!!] no java, no Homebrew. Install a JDK 11+: https://adoptium.net/" >&2; exit 1
      fi ;;
    Linux)
      if   command -v apt-get >/dev/null 2>&1; then echo "[..] apt"; sudo apt-get update && sudo apt-get install -y default-jdk
      elif command -v dnf     >/dev/null 2>&1; then echo "[..] dnf";  sudo dnf install -y java-latest-openjdk
      elif command -v pacman  >/dev/null 2>&1; then echo "[..] pacman"; sudo pacman -S --noconfirm jdk-openjdk
      elif command -v zypper  >/dev/null 2>&1; then echo "[..] zypper"; sudo zypper install -y java-11-openjdk
      else echo "[!!] no known package manager. Install a JDK 11+ manually." >&2; exit 1; fi ;;
    *)
      echo "[!!] no java. Install a JDK 11+ manually: https://adoptium.net/" >&2; exit 1 ;;
  esac
fi

# 2. tla2tools.jar (TLC + SANY).
if [ -f "$JAR" ]; then
  echo "[ok] jar present: $JAR"
else
  echo "[..] downloading tla2tools.jar"; mkdir -p "$HOME/tools"
  if   command -v curl >/dev/null 2>&1; then curl -fsSL -o "$JAR" "$JAR_URL"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$JAR" "$JAR_URL"
  else echo "[!!] need curl or wget to download the jar." >&2; exit 1; fi
  echo "[ok] jar downloaded: $JAR"
fi

# 3. PATH wrappers.
mkdir -p "$BIN"
if [ -x "$BIN/tlc" ]; then echo "[ok] wrapper present: $BIN/tlc"; else
  cat > "$BIN/tlc" <<'EOF'
#!/bin/sh
exec java -XX:+UseParallelGC -cp "$HOME/tools/tla2tools.jar" tlc2.TLC "$@"
EOF
  chmod +x "$BIN/tlc"; echo "[ok] wrote $BIN/tlc"; fi
if [ -x "$BIN/sany" ]; then echo "[ok] wrapper present: $BIN/sany"; else
  cat > "$BIN/sany" <<'EOF'
#!/bin/sh
exec java -cp "$HOME/tools/tla2tools.jar" tla2sany.SANY "$@"
EOF
  chmod +x "$BIN/sany"; echo "[ok] wrote $BIN/sany"; fi

# 4. PATH sanity.
case ":$PATH:" in
  *":$BIN:"*) : ;;
  *) echo "[!!] $BIN not on PATH. Add: export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2 ;;
esac
echo "== done. verify: tlc -help | head -3 =="
