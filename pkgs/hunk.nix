{ lib
, fetchurl
, stdenv
, autoPatchelfHook
, makeWrapper
}:

let
  inherit (stdenv) hostPlatform;
  version = "0.20.1";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-linux-x64.tar.gz";
      hash = "sha256-iJ4zihsPz91ppezo13bKtY4CIrnvR4Ty+lGa3oe0N8g=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-linux-arm64.tar.gz";
      hash = "sha256-eLD0fcwehI0qJGUd2n6ZhkPCT/iToi5+SA6a6+6oZWU=";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-darwin-arm64.tar.gz";
      hash = "sha256-txCxId81+ayczvG9714hNXR75AS4GHEDE8w9sckPhOY=";
    };
  };
in
stdenv.mkDerivation {
  pname = "hunkdiff";
  inherit version;

  src = sources.${hostPlatform.system} or (throw "Unsupported platform: ${hostPlatform.system}");

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals hostPlatform.isLinux [
    autoPatchelfHook
  ];

  # Bun single-file executables carry their bundle inside the binary; stripping breaks it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -p hunk $out/bin/hunk
    cp -r skills $out/
    wrapProgram $out/bin/hunk --set HUNK_INSTALL_SOURCE nix

    runHook postInstall
  '';

  meta = {
    description = "Terminal diff viewer for agentic changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "hunk";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
