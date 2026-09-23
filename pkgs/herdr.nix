{ lib
, fetchurl
, stdenvNoCC
}:

let
  inherit (stdenvNoCC) hostPlatform;
  version = "0.8.2";
  sources = {
    # Linux builds are static-pie, so no patchelf is needed.
    x86_64-linux = fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
      hash = "sha256-l2FQoU1JDJSyQ+ouGn6y37Z/EuNrGC25CTb2co5q7PQ=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-aarch64";
      hash = "sha256-9VYQZY4cLg0qrvcwtLKriF9/i6AChas3K/sU8uPVtA0=";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-macos-aarch64";
      hash = "sha256-pdT01QTYswnJH4EQUFWTAPq6MSWEJfU8UIUvyW9q5XQ=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "herdr";
  inherit version;

  src = sources.${hostPlatform.system} or (throw "Unsupported platform: ${hostPlatform.system}");

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/herdr

    runHook postInstall
  '';

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://github.com/herdrdev/herdr";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames sources;
    mainProgram = "herdr";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
