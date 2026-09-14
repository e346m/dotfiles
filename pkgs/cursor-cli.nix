{ lib
, fetchurl
, stdenv
, autoPatchelfHook
, zlib
}:

let
  inherit (stdenv) hostPlatform;
  # Version slug from https://cursor.com/install (lab channel).
  slug = "2026.09.02-c22c1a3";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/lab/${slug}/linux/x64/agent-cli-package.tar.gz";
      hash = "sha256-tztZhUdiU1wPwg18zFHDtaNWqFFJEIjWCjYr5IdQ9Tw=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/lab/${slug}/linux/arm64/agent-cli-package.tar.gz";
      hash = "sha256-+3vGNb5hcuvPaPkH/ZIX42FNpRkWRVxtf9tmaQmXiEw=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/lab/${slug}/darwin/arm64/agent-cli-package.tar.gz";
      hash = "sha256-PYFIYb4yJfyMOL4yD7IuNE2PcRokJ58fkRnnsxPqUec=";
    };
  };
in
stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "0-unstable-2026-09-02";

  src = sources.${hostPlatform.system} or (throw "Unsupported platform: ${hostPlatform.system}");

  buildInputs = lib.optionals hostPlatform.isLinux [
    zlib
  ];

  nativeBuildInputs = lib.optionals hostPlatform.isLinux [
    autoPatchelfHook
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/cursor-agent
    cp -r * $out/share/cursor-agent/
    ln -s $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent

    runHook postInstall
  '';

  meta = {
    description = "Cursor CLI (cursor-agent)";
    homepage = "https://cursor.com/cli";
    license = lib.licenses.unfree;
    platforms = builtins.attrNames sources;
    mainProgram = "cursor-agent";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
