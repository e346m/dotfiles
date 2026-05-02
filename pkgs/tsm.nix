{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "0.6.6";
  baseUrl = "https://github.com/adibhanna/tsm/releases/download/v${version}";

  platforms = {
    x86_64-linux = {
      artifact = "tsm_v${version}_linux_amd64.tar.gz";
      hash = "sha256-Y9vfYwKI+ZnI3dz8+UPF3roY700u664nDQ3tr2668aM=";
    };
    aarch64-linux = {
      artifact = "tsm_v${version}_linux_arm64.tar.gz";
      hash = "sha256-kCOZ6M06ois3vjX2Yv8cnXZ3DBLhO1Fzl3RuVUyX9m0=";
    };
  };

  platformInfo = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "tsm";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/${platformInfo.artifact}";
    hash = platformInfo.hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/tsm
    install -m755 tsm $out/bin/tsm
    cp -P libghostty-vt.so* $out/libexec/tsm/
    patchelf --set-rpath "$out/libexec/tsm" $out/bin/tsm

    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal session manager with libghostty-vt";
    homepage = "https://github.com/adibhanna/tsm";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "tsm";
  };
}
