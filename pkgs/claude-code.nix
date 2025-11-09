{ lib
, stdenv
, fetchurl
, nodejs
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "2.0.35";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-WTbUW++l0ZyfD5OTM90e+lKIWAGCYJ7vDmDBXN0TtOw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib/node_modules/claude-code

    # Copy the npm package contents
    cp -r . $out/lib/node_modules/claude-code/

    # Create wrapper scripts for both claude and claude-code
    makeWrapper ${nodejs}/bin/node $out/bin/claude \
      --add-flags "$out/lib/node_modules/claude-code/cli.js"

    makeWrapper ${nodejs}/bin/node $out/bin/claude-code \
      --add-flags "$out/lib/node_modules/claude-code/cli.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI-powered code assistant";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.all;
    mainProgram = "claude-code";
  };
}
