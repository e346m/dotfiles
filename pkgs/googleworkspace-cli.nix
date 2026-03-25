{ lib
, stdenv
, fetchurl
}:

let
  version = "0.22.0";
  baseUrl = "https://github.com/googleworkspace/cli/releases/download/v${version}";

  platforms = {
    x86_64-linux = {
      artifact = "google-workspace-cli-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-JZRWbrZV2kW0a6qByg+bXbg0MIycfave88SwacztbEY=";
    };
    aarch64-linux = {
      artifact = "google-workspace-cli-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-JXL8XER9bSehQuFr4UolYYBYM28ycoIJ9JX0O0r0dFA=";
    };
    x86_64-darwin = {
      artifact = "google-workspace-cli-x86_64-apple-darwin.tar.gz";
      hash = "sha256-KbgZCKoQXzA1IrpayJdfFdH1ZpkeNtQBjDaxwSvCd/4=";
    };
    aarch64-darwin = {
      artifact = "google-workspace-cli-aarch64-apple-darwin.tar.gz";
      hash = "sha256-bsxKfJp6kYvr2sXtlm23gE2uRGOb4QlIsw6v1nyiwiE=";
    };
  };

  platformInfo = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "googleworkspace-cli";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/${platformInfo.artifact}";
    hash = platformInfo.hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 google-workspace-cli-*/gws $out/bin/gws

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Workspace CLI - command-line interface for Google Workspace APIs";
    homepage = "https://github.com/googleworkspace/cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "gws";
  };
}
