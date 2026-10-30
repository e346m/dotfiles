{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "orca-ide";
  version = "1.4.216";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    sha256 = "0liwj23f8kbd6v9640wrg5i4dq00zlc48kw1fy593liyw0z3lr95";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
  ];

  extraInstallCommands = ''
    desktop=$(find ${appimageContents} -name '*.desktop' -print -quit || true)
    if [ -n "$desktop" ]; then
      install -Dm444 "$desktop" "$out/share/applications/orca-ide.desktop"
      sed -i \
        -e 's|^Exec=.*|Exec=orca-ide open %U|' \
        -e 's|^Icon=.*|Icon=orca-ide|' \
        "$out/share/applications/orca-ide.desktop"
    fi

    if [ -d ${appimageContents}/usr/share/icons/hicolor ]; then
      mkdir -p "$out/share/icons/hicolor"
      cp -a ${appimageContents}/usr/share/icons/hicolor/. "$out/share/icons/hicolor/"
      find "$out/share/icons/hicolor" -type f -name '*.png' | while read -r icon; do
        dir=$(dirname "$icon")
        base=$(basename "$icon" .png)
        if [ "$base" != "orca-ide" ]; then
          cp -a "$icon" "$dir/orca-ide.png"
        fi
      done
    fi
  '';

  meta = {
    description = "Orca, an agent development environment for running coding agents in parallel";
    homepage = "https://www.onorca.dev/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "orca-ide";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
