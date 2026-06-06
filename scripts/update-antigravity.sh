#!/usr/bin/env bash
# Update pkgs/antigravity.nix to the latest Antigravity CLI (`agy`) and run home-manager switch.
# Mechanical part only: fetches the CLI auto-updater manifests, converts sha512 hex to SRI,
# rewrites version/build/hash in the nix file, switches. Linux-only (x86_64 + aarch64).
#
# Usage:
#   update-antigravity.sh                # update to latest, then switch
#   update-antigravity.sh --no-switch    # rewrite nix only
#   update-antigravity.sh -n             # same as --no-switch

set -euo pipefail

REPO="/home/eiji/.config/home-manager"
NIX_FILE="$REPO/pkgs/antigravity.nix"
UPDATER="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
FLAKE_TARGET="$REPO#eiji"

DO_SWITCH=1
while (($#)); do
  case "$1" in
    -n|--no-switch) DO_SWITCH=0 ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  echo "unexpected argument: $1" >&2; exit 2 ;;
  esac
  shift
done

hex_to_sri() {
  printf '%s' "$1" | xxd -r -p | base64 -w0 | awk '{print "sha512-" $0}'
}

# Pull the linux manifests. amd64 is canonical for version + build id.
m_amd64="$(curl -fsS "$UPDATER/manifests/linux_amd64.json")"
m_arm64="$(curl -fsS "$UPDATER/manifests/linux_arm64.json")"

TARGET="$(jq -er '.version' <<<"$m_amd64")"
echo "target version: $TARGET"

CURRENT="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$NIX_FILE" | head -1)"
echo "current version: $CURRENT"

amd64_url="$(jq -er '.url' <<<"$m_amd64")"
# Build/execution id is the path segment after "<version>-": .../<version>-<build>/<sub>/<file>
BUILD="$(sed -n "s#.*/antigravity-cli/${TARGET}-\([0-9]*\)/.*#\1#p" <<<"$amd64_url")"
if [[ -z "$BUILD" ]]; then
  echo "could not parse build id from url: $amd64_url" >&2
  exit 1
fi
echo "build id: $BUILD"

SRI_X64="$(hex_to_sri "$(jq -er '.sha512' <<<"$m_amd64")")"
SRI_ARM="$(hex_to_sri "$(jq -er '.sha512' <<<"$m_arm64")")"
echo "  linux-x64:   $SRI_X64"
echo "  linux-arm64: $SRI_ARM"

if [[ "$CURRENT" == "$TARGET" ]]; then
  echo "already at $TARGET — nothing to do"
  exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Rewrite: bump version + build, then replace the hash on the line following each
# `sub = "linux-x64"|"linux-arm";` block marker.
awk -v ver="$TARGET" -v bld="$BUILD" -v hx="$SRI_X64" -v ha="$SRI_ARM" '
  BEGIN { sub_kind = "" }
  /^[[:space:]]*version = "[^"]*";/ { sub(/"[^"]*"/, "\"" ver "\""); print; next }
  /^[[:space:]]*build = "[^"]*";/   { sub(/"[^"]*"/, "\"" bld "\""); print; next }
  /sub = "linux-x64"/ { sub_kind = "x"; print; next }
  /sub = "linux-arm"/ { sub_kind = "a"; print; next }
  /hash = "sha512-[^"]*";/ && sub_kind != "" {
    h = (sub_kind == "x") ? hx : ha
    sub(/"sha512-[^"]*"/, "\"" h "\"")
    sub_kind = ""
    print; next
  }
  { print }
' "$NIX_FILE" > "$tmp"

# Sanity: version, build, and both hashes must be present afterwards.
new_ver="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$tmp" | head -1)"
[[ "$new_ver" == "$TARGET" ]] || { echo "rewrite failed: version not updated" >&2; exit 1; }
grep -F "$BUILD" "$tmp"   >/dev/null || { echo "rewrite failed: build id missing" >&2; exit 1; }
grep -F "$SRI_X64" "$tmp" >/dev/null || { echo "rewrite failed: x64 hash missing" >&2; exit 1; }
grep -F "$SRI_ARM" "$tmp" >/dev/null || { echo "rewrite failed: arm64 hash missing" >&2; exit 1; }

mv "$tmp" "$NIX_FILE"
trap - EXIT
echo "wrote $NIX_FILE"

if (( DO_SWITCH )); then
  echo "running home-manager switch..."
  home-manager switch --flake "$FLAKE_TARGET"
  echo "done: $CURRENT -> $TARGET"
else
  echo "skipped switch (--no-switch); review with: git -C $REPO diff -- $NIX_FILE"
fi
