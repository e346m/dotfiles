{ lib
, stdenv
, fetchurl
, glibc
, patchelf
}:

let
  version = "1.0.10";
  # The storage path embeds an opaque build/execution id alongside the version.
  # The update script keeps both in sync from the CLI auto-updater manifest.
  build = "6349723456634880";
  baseUrl = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${build}";

  # Linux only: Antigravity CLI (`agy`) is a cgo Go binary that just needs the
  # glibc interpreter patched for NixOS. macOS is intentionally not packaged.
  platforms = {
    x86_64-linux = {
      sub = "linux-x64";
      file = "cli_linux_x64.tar.gz";
      hash = "sha512-RXgoQPjOFCB+ybi5YuduZPDnTnkgAA8XYYD3IE4PieYcDkdcmitIWcyQ8IwhSEi52QrBw0TvmH95bidoIAeN8Q==";
    };
    aarch64-linux = {
      sub = "linux-arm";
      file = "cli_linux_arm64.tar.gz";
      hash = "sha512-le3F/mw7Rburp2g+dIx+rqXxlQ9k7s8IPNU/O0GWH88T/atoxk1wLX5bdJxj3GOFxbAVmoXtxu0SqdGjI+Ye4A==";
    };
  };

  platformInfo = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  interpreter = if stdenv.hostPlatform.isAarch64
    then "${glibc}/lib/ld-linux-aarch64.so.1"
    else "${glibc}/lib/ld-linux-x86-64.so.2";
in
stdenv.mkDerivation {
  pname = "antigravity";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/${platformInfo.sub}/${platformInfo.file}";
    hash = platformInfo.hash;
    name = "antigravity-cli-${version}-${platformInfo.sub}.tar.gz";
  };

  # Tarball contains a single `antigravity` binary.
  sourceRoot = ".";
  dontStrip = true;  # Go binary with embedded data; stripping risks breakage.

  nativeBuildInputs = [ patchelf ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    # Upstream installs it as `agy`; keep that as the primary command.
    install -m755 antigravity $out/bin/agy

    # Patch the interpreter for NixOS.
    patchelf --set-interpreter "${interpreter}" $out/bin/agy

    runHook postInstall
  '';

  meta = with lib; {
    description = "Antigravity CLI (agy) - Google Antigravity agentic CLI (native build)";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "agy";
  };
}
