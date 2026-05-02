#!/usr/bin/env bash
# Update pkgs/claude-code.nix to a target version (default: latest) and run home-manager switch.
# Mechanical part only: fetches manifest, converts hex checksums to SRI, rewrites the nix file, switches.
# Changelog review is intentionally out of scope — do that before calling this.
#
# Usage:
#   update-claude-code.sh                # update to latest, then switch
#   update-claude-code.sh 2.1.126        # update to a specific version, then switch
#   update-claude-code.sh --no-switch    # rewrite nix only
#   update-claude-code.sh -n 2.1.126     # rewrite nix only, specific version

set -euo pipefail

REPO="/home/eiji/.config/home-manager"
NIX_FILE="$REPO/pkgs/claude-code.nix"
BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
FLAKE_TARGET="$REPO#eiji"

DO_SWITCH=1
TARGET=""

while (($#)); do
  case "$1" in
    -n|--no-switch) DO_SWITCH=0 ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  TARGET="$1" ;;
  esac
  shift
done

if [[ -z "$TARGET" ]]; then
  TARGET="$(curl -fsS "$BUCKET/latest")"
fi
echo "target version: $TARGET"

CURRENT="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$NIX_FILE" | head -1)"
echo "current version: $CURRENT"

if [[ "$CURRENT" == "$TARGET" ]]; then
  echo "already at $TARGET — nothing to do"
  exit 0
fi

MANIFEST="$(curl -fsS "$BUCKET/$TARGET/manifest.json")"

hex_to_sri() {
  printf '%s' "$1" | xxd -r -p | base64 | awk '{print "sha256-" $0}'
}

declare -A SRI
for p in linux-x64 linux-arm64 darwin-x64 darwin-arm64; do
  hex="$(printf '%s' "$MANIFEST" | jq -er ".platforms[\"$p\"].checksum")"
  SRI[$p]="$(hex_to_sri "$hex")"
  echo "  $p: ${SRI[$p]}"
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Rewrite the file: bump version, then replace the hash on the line that
# follows each `platform = "<name>";` line.
awk -v ver="$TARGET" \
    -v lx="${SRI[linux-x64]}" \
    -v la="${SRI[linux-arm64]}" \
    -v dx="${SRI[darwin-x64]}" \
    -v da="${SRI[darwin-arm64]}" '
  BEGIN { plat = "" }
  /^[[:space:]]*version = "[^"]*";/ {
    sub(/"[^"]*"/, "\"" ver "\"")
    print; next
  }
  /platform = "linux-x64"/    { plat = "lx"; print; next }
  /platform = "linux-arm64"/  { plat = "la"; print; next }
  /platform = "darwin-x64"/   { plat = "dx"; print; next }
  /platform = "darwin-arm64"/ { plat = "da"; print; next }
  /hash = "sha256-[^"]*";/ && plat != "" {
    h = (plat == "lx") ? lx : (plat == "la") ? la : (plat == "dx") ? dx : da
    sub(/"sha256-[^"]*"/, "\"" h "\"")
    plat = ""
    print; next
  }
  { print }
' "$NIX_FILE" > "$tmp"

# Sanity: every hash and the version must have changed.
new_ver="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$tmp" | head -1)"
if [[ "$new_ver" != "$TARGET" ]]; then
  echo "rewrite failed: version not updated" >&2
  exit 1
fi
for p in linux-x64 linux-arm64 darwin-x64 darwin-arm64; do
  grep -F "${SRI[$p]}" "$tmp" >/dev/null || {
    echo "rewrite failed: missing hash for $p" >&2
    exit 1
  }
done

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
