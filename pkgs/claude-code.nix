{ lib
, stdenv
, fetchurl
, glibc
, patchelf
}:

let
  version = "2.1.27";
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}";

  platforms = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-JN+R3SULbX9qD4slav+rbHpL3vpksezorKMjXV9eQEQ=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-YWao7rguukELlgMKtLEzCifCi9vcTjE9tF5b/MJdHmY=";
    };
    x86_64-darwin = {
      platform = "darwin-x64";
      hash = "sha256-z8GtVQGumiy0sbLjdV5XNLL2thFPZx5ScDjUgyf7iIw=";
    };
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-RX3DlYE5o1bu/yNxEHTEXTk/s8guhou3oVZat6V4bww=";
    };
  };

  platformInfo = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/${platformInfo.platform}/claude";
    hash = platformInfo.hash;
    name = "claude-${version}-${platformInfo.platform}";
  };

  dontUnpack = true;
  dontStrip = true;  # Bun binaries contain embedded data that must not be stripped

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ patchelf ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 $src $out/bin/claude

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      # Patch the interpreter for NixOS
      patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $out/bin/claude
    ''}

    # Create symlink for claude-code
    ln -s $out/bin/claude $out/bin/claude-code

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI-powered code assistant (native build)";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "claude";
  };
}
