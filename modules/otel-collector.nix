{
  config,
  pkgs,
  ...
}:
# Claude Code のレイテンシ計測用に OTel Collector を launchd agent として常駐させる。
# home-manager には services.opentelemetry-collector 相当のモジュールが無い（NixOS 専用）ため
# launchd.agents を直接使う。darwin 専用モジュール。
let
  otelcol = pkgs.opentelemetry-collector-contrib;

  # JSONL とコレクタ自身のログの置き場。
  dataDir = "${config.home.homeDirectory}/.local/share/otelcol";

  # Claude Code は logs にイベント（api_request / tool_result / api_error など）、
  # traces に span（ttft_ms を持つ llm_request）を出す。両方 JSONL に落とす。
  # file exporter は contrib のみ収録なので core ではなく contrib を使う。
  collectorConfig = (pkgs.formats.yaml { }).generate "otelcol-config.yaml" {
    receivers.otlp.protocols.grpc.endpoint = "127.0.0.1:4317";

    processors = {
      batch.timeout = "5s";
      # Claude Code は user.email をログ/スパン/メトリクスの属性に平文で載せる。
      # ローカルの JSONL に個人情報を残す必要はないので落とす。
      # 集計は session.id / prompt.id / request_id で足りる。
      "attributes/redact".actions = [
        {
          key = "user.email";
          action = "delete";
        }
      ];
    };

    exporters = {
      # rotation を設定すると lumberjack 経由になり、既存ファイルを truncate せず追記する。
      # rotation 無しだと append=false（既定）で起動ごとに切り詰められるので必ず付ける。
      "file/logs" = {
        path = "${dataDir}/logs.jsonl";
        format = "json";
        rotation = {
          max_megabytes = 64;
          max_backups = 10;
        };
      };
      "file/traces" = {
        path = "${dataDir}/traces.jsonl";
        format = "json";
        rotation = {
          max_megabytes = 64;
          max_backups = 10;
        };
      };
      "file/metrics" = {
        path = "${dataDir}/metrics.jsonl";
        format = "json";
        rotation = {
          max_megabytes = 32;
          max_backups = 3;
        };
      };
    };

    service = {
      pipelines = {
        logs = {
          receivers = [ "otlp" ];
          processors = [
            "attributes/redact"
            "batch"
          ];
          exporters = [ "file/logs" ];
        };
        traces = {
          receivers = [ "otlp" ];
          processors = [
            "attributes/redact"
            "batch"
          ];
          exporters = [ "file/traces" ];
        };
        metrics = {
          receivers = [ "otlp" ];
          processors = [
            "attributes/redact"
            "batch"
          ];
          exporters = [ "file/metrics" ];
        };
      };
      telemetry = {
        logs.level = "warn";
        # コレクタ自身のメトリクスは 8888 を掴むので無効化する。
        metrics.level = "none";
      };
    };
  };
in
{
  home.packages = [
    otelcol
    pkgs.claude-latency
  ];

  # launchd は StandardOutPath の親ディレクトリを作らないので先に用意する。
  home.file.".local/share/otelcol/.keep".text = "";

  launchd.agents.otelcol = {
    enable = true;
    config = {
      ProgramArguments = [
        "${otelcol}/bin/otelcol-contrib"
        "--config=${collectorConfig}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${dataDir}/otelcol.out.log";
      StandardErrorPath = "${dataDir}/otelcol.err.log";
    };
  };
}
