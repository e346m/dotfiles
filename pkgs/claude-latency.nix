{
  lib,
  writeShellApplication,
  jq,
  duckdb,
  coreutils,
}:
# Claude Code の OTel 出力（OTLP-JSON の JSONL）からレイテンシ分布を出す。
# JSONL の置き場は $CLAUDE_OTEL_DIR、既定 ~/.local/share/otelcol。
writeShellApplication {
  name = "claude-latency";

  runtimeInputs = [
    jq
    duckdb
    coreutils
  ];

  text = builtins.readFile ../scripts/claude-latency.sh;

  meta = with lib; {
    description = "Summarize Claude Code request latency from OTel Collector JSONL";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "claude-latency";
  };
}
