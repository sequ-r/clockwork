#!/usr/bin/env bash
# Sets up a user-local prefix with the tray_manager Linux runtime deps
# (libayatana-appindicator, libayatana-indicator, ayatana-ido) so that
# `flutter build linux` succeeds on machines that don't have those
# packages installed system-wide.
#
# Usage: scripts/setup_linux_build.sh
#
# What it does:
#   1. Creates ~/.local/prefix/ and ~/.local/pc_override/ if missing.
#   2. Downloads the three packages from the configured pacman mirror
#      into ~/.local/build/ if not already present.
#   3. Extracts them into ~/.local/prefix/ (without touching /usr).
#   4. Writes ~/.local/pc_override/*.pc with `prefix=` rewritten to the
#      user prefix so pkg-config finds the headers and libs.
#   5. Patches ~/.pub-cache/hosted/pub.dev/tray_manager-*/linux/CMakeLists.txt
#      to demote libayatana-appindicator 0.6.0's `app_indicator_new`
#      deprecation warning so the build doesn't fail with -Werror.
#
# After running this script, export the printed env vars before invoking
# Flutter:
#
#   eval "$(scripts/setup_linux_build.sh --env)"
#   flutter build linux
#
# Or set them manually (see the bottom of this file).

set -euo pipefail

PREFIX="$HOME/.local/prefix"
PC_OVERRIDE="$HOME/.local/pc_override"
BUILD_DIR="$HOME/.local/build"
MIRROR_BASE="https://mirror.krfoss.org/cachyos/repo/x86_64_v4/cachyos-extra-znver4"

PKGS=(
  "ayatana-ido-0.10.4-1.2"
  "libayatana-indicator-0.9.5-1.1"
  "libayatana-appindicator-0.6.0-1.1"
)

download_and_extract() {
  mkdir -p "$PREFIX" "$PC_OVERRIDE" "$BUILD_DIR"
  for pkg in "${PKGS[@]}"; do
    local archive="$BUILD_DIR/${pkg}-x86_64_v4.pkg.tar.zst"
    if [ ! -f "$archive" ]; then
      echo "Downloading $pkg..." >&2
      curl -sSL -o "$archive" "${MIRROR_BASE}/${pkg}-x86_64_v4.pkg.tar.zst"
    fi
    tar --use-compress-program=unzstd -xf "$archive" -C "$PREFIX/"
  done

  # Rewrite prefix=/usr -> prefix=$PREFIX/usr in each .pc so pkg-config
  # resolves to the user-local install.
  for pc in "$PREFIX/usr/lib/pkgconfig/"*.pc; do
    local name
    name=$(basename "$pc")
    sed \
      -e "s|^prefix=/usr|prefix=$PREFIX/usr|" \
      -e "s|^libdir=/usr/lib|libdir=$PREFIX/usr/lib|" \
      -e "s|^includedir=/usr/include|includedir=$PREFIX/usr/include|" \
      "$pc" > "$PC_OVERRIDE/$name"
  done
}

patch_tray_manager_cmake() {
  local tray_cmake
  tray_cmake=$(ls -d ~/.pub-cache/hosted/pub.dev/tray_manager-*/linux/CMakeLists.txt 2>/dev/null | head -n 1 || true)
  if [ -z "$tray_cmake" ]; then
    echo "tray_manager not in pub cache; run 'flutter pub get' first." >&2
    return 0
  fi
  if grep -q "Wno-error=deprecated-declarations" "$tray_cmake"; then
    return 0
  fi
  echo "Patching $tray_cmake to demote app_indicator_new deprecation..." >&2
  python3 - "$tray_cmake" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()
needle = "apply_standard_settings(${PLUGIN_NAME})\n"
replacement = (
    "apply_standard_settings(${PLUGIN_NAME})\n"
    "# app_indicator_new was deprecated in libayatana-appindicator 0.6.0;\n"
    "# demote to a warning so the build does not fail under -Werror.\n"
    "target_compile_options(${PLUGIN_NAME} PRIVATE -Wno-error=deprecated-declarations)\n"
)
if needle not in src:
    sys.exit("plugin CMakeLists.txt did not match expected layout")
src = src.replace(needle, replacement, 1)
with open(path, "w") as f:
    f.write(src)
PY
}

if [ "${1:-}" = "--env" ]; then
  cat <<EOF
export PKG_CONFIG_PATH="$PC_OVERRIDE:$PREFIX/usr/lib/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="$PREFIX/usr\${CMAKE_PREFIX_PATH:+:\$CMAKE_PREFIX_PATH}"
export LD_LIBRARY_PATH="$PREFIX/usr/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
EOF
  exit 0
fi

download_and_extract
patch_tray_manager_cmake
cat <<EOF

Done.

To build, export these env vars (or run \`eval "\$(scripts/setup_linux_build.sh --env)"\`):

  export PKG_CONFIG_PATH="$PC_OVERRIDE:$PREFIX/usr/lib/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}"
  export CMAKE_PREFIX_PATH="$PREFIX/usr\${CMAKE_PREFIX_PATH:+:\$CMAKE_PREFIX_PATH}"
  export LD_LIBRARY_PATH="$PREFIX/usr/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"

Then:

  flutter build linux

The pub-cache patch is idempotent and survives \`flutter pub get\` as long as
the tray_manager version stays pinned. Re-run this script if the package
cache is rebuilt.
EOF
