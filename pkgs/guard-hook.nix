{ lib
, stdenv
}:

let
  version = "0.2.0";

  platforms = {
    x86_64-linux = "linux_amd64";
    aarch64-linux = "linux_arm64";
    x86_64-darwin = "darwin_amd64";
    aarch64-darwin = "darwin_arm64";
  };

  suffix = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "guard-hook";
  inherit version;

  src = ./guard-hook-bin/guard-hook_${suffix};

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 $src $out/bin/guard-hook

    runHook postInstall
  '';

  meta = with lib; {
    description = "Guard hook for Claude Code - command validation tool";
    homepage = "https://github.com/upsidr/vulcan";
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "guard-hook";
  };
}
