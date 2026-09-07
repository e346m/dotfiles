# Claude Code の OTel 出力（OTLP-JSON の JSONL）からレイテンシ分布を出す。
# shebang / PATH / CLAUDE_OTEL_DIR は modules/otel-collector.nix の writeShellScriptBin 側で与える。
set -euo pipefail

OTEL_DIR="${CLAUDE_OTEL_DIR:-$HOME/.local/share/otelcol}"
DAYS=""
MODE="report"
CUSTOM_SQL=""

usage() {
  cat <<'USAGE'
claude-latency [options]

  --days N      直近 N 日分に絞る
  --sql SQL     任意の SQL を実行（ビュー ev が使える）
  --shell       duckdb を対話起動（ビュー ev が定義済み）
  --dir PATH    JSONL の置き場（既定: $CLAUDE_OTEL_DIR）
  --raw         フラット化した JSONL を標準出力に流して終了

ビュー ev の主な列:
  ts, kind(log|span), event, model, speed, effort,
  dur_ms, ttft, interaction_ms, in_tok, out_tok, cache_tok, cost,
  prompt_id, session_id, request_id, tool_name, tool_success,
  status_code, attempt, query_source

span (kind='span') には prompt_id が付かないので、
api_request ログとの突き合わせは request_id で行う。
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --sql) MODE="sql"; CUSTOM_SQL="$2"; shift 2 ;;
    --shell) MODE="shell"; shift ;;
    --dir) OTEL_DIR="$2"; shift 2 ;;
    --raw) MODE="raw"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# ローテーション後のファイル名は logs-<timestamp>.jsonl になるのでまとめて拾う。
shopt -s nullglob
files=("$OTEL_DIR"/logs*.jsonl "$OTEL_DIR"/traces*.jsonl)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "OTel の JSONL が見つかりません: $OTEL_DIR" >&2
  echo "コレクタが動いているか確認してください: launchctl list | grep otelcol" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
flat="$workdir/flat.jsonl"

# OTLP-JSON は resourceLogs / resourceSpans の深い入れ子なので、
# 1 レコード = 1 行の固定スキーマに落としてから SQL で触る。
# 固定スキーマにするのは、属性が欠けた回で列が消えて SQL が壊れるのを防ぐため。
jq -c '
  def val(v):
    if v.stringValue != null then v.stringValue
    elif v.intValue != null then v.intValue
    elif v.doubleValue != null then v.doubleValue
    elif v.boolValue != null then v.boolValue
    else null end;

  def attrs: [ .attributes[]? | { key: .key, value: val(.value) } ] | from_entries;

  # 実測では eventName フィールドは null で、イベント名は event.name 属性と
  # body.stringValue の両方に入る。どこに来ても拾えるようにしておく。
  def evname:
    if .eventName != null then .eventName
    else ([ .attributes[]? | select(.key == "event.name") | .value.stringValue ] | first)
         // .body.stringValue
    end;

  if has("resourceLogs") then
    .resourceLogs[]? | .scopeLogs[]? | .logRecords[]?
    | . as $r | (attrs) as $a
    | {
        kind: "log",
        ts_ns: ($r.observedTimeUnixNano // $r.timeUnixNano),
        event: ($r | evname),
        model: $a.model,
        speed: $a.speed,
        effort: $a.effort,
        duration_ms: $a.duration_ms,
        ttft_ms: null,
        interaction_ms: null,
        input_tokens: $a.input_tokens,
        output_tokens: $a.output_tokens,
        cache_read_tokens: $a.cache_read_tokens,
        cost_usd: $a.cost_usd,
        prompt_id: $a["prompt.id"],
        session_id: $a["session.id"],
        request_id: $a.request_id,
        tool_name: $a.tool_name,
        tool_success: $a.success,
        status_code: $a.status_code,
        attempt: $a.attempt,
        query_source: $a.query_source
      }
  elif has("resourceSpans") then
    .resourceSpans[]? | .scopeSpans[]? | .spans[]?
    | . as $s | (attrs) as $a
    | {
        kind: "span",
        ts_ns: $s.startTimeUnixNano,
        event: $s.name,
        model: $a.model,
        speed: $a.speed,
        effort: $a.effort,
        # llm_request span は duration_ms 属性を自前で持つ。無い span だけ
        # start/end の差から埋める。
        duration_ms: ($a.duration_ms
          // ((($s.endTimeUnixNano | tonumber) - ($s.startTimeUnixNano | tonumber)) / 1000000 | floor)),
        ttft_ms: $a.ttft_ms,
        interaction_ms: $a["interaction.duration_ms"],
        input_tokens: $a.input_tokens,
        output_tokens: $a.output_tokens,
        cache_read_tokens: $a.cache_read_tokens,
        cost_usd: $a.cost_usd,
        prompt_id: $a["prompt.id"],
        session_id: $a["session.id"],
        request_id: $a.request_id,
        tool_name: $a.tool_name,
        tool_success: $a.success,
        status_code: null,
        attempt: $a.attempt,
        query_source: $a.query_source
      }
  else empty end
' "${files[@]}" > "$flat"

if [ ! -s "$flat" ]; then
  echo "レコードが 0 件でした。claude を一度起動してリクエストを投げてから再実行してください。" >&2
  exit 1
fi

if [ "$MODE" = "raw" ]; then
  cat "$flat"
  exit 0
fi

where_days="TRUE"
if [ -n "$DAYS" ]; then
  where_days="ts >= now() - INTERVAL '$DAYS days'"
fi

init="$workdir/init.sql"
cat > "$init" <<SQL
-- 型は必ず明示する。属性が 1 レコードも現れないと（例: haiku だけ使った日の
-- effort）duckdb がその列を JSON 型と推論し、coalesce(effort, '-') が
-- 「Malformed JSON」で落ちる。jq 側が固定スキーマを吐くので列指定できる。
CREATE OR REPLACE VIEW ev_all AS
SELECT
  to_timestamp(ts_ns / 1e9) AS ts,
  kind,
  event,
  model,
  speed,
  effort,
  duration_ms      AS dur_ms,
  ttft_ms          AS ttft,
  interaction_ms,
  input_tokens     AS in_tok,
  output_tokens    AS out_tok,
  cache_read_tokens AS cache_tok,
  cost_usd         AS cost,
  prompt_id,
  session_id,
  request_id,
  tool_name,
  tool_success,
  status_code,
  attempt,
  query_source
FROM read_json('$flat', format='newline_delimited', columns={
  kind: 'VARCHAR',
  ts_ns: 'DOUBLE',
  event: 'VARCHAR',
  model: 'VARCHAR',
  speed: 'VARCHAR',
  effort: 'VARCHAR',
  duration_ms: 'DOUBLE',
  ttft_ms: 'DOUBLE',
  interaction_ms: 'DOUBLE',
  input_tokens: 'DOUBLE',
  output_tokens: 'DOUBLE',
  cache_read_tokens: 'DOUBLE',
  cost_usd: 'DOUBLE',
  prompt_id: 'VARCHAR',
  session_id: 'VARCHAR',
  request_id: 'VARCHAR',
  tool_name: 'VARCHAR',
  tool_success: 'VARCHAR',
  status_code: 'VARCHAR',
  attempt: 'VARCHAR',
  query_source: 'VARCHAR'
});

CREATE OR REPLACE VIEW ev AS SELECT * FROM ev_all WHERE $where_days;
SQL

case "$MODE" in
  shell)
    exec duckdb -init "$init"
    ;;
  sql)
    exec duckdb -init "$init" -c "$CUSTOM_SQL"
    ;;
esac

report="$workdir/report.sql"
cat > "$report" <<'SQL'
.print
.print ── 集計対象 ─────────────────────────────────────────
SELECT count(*) AS records, min(ts) AS "from", max(ts) AS "to",
       count(DISTINCT session_id) AS sessions
FROM ev;

.print
.print ── 体感待ち時間 (claude_code.interaction span, 送信→完了) ──
SELECT
  count(*)                                    AS interactions,
  round(quantile_cont(interaction_ms, 0.50))  AS p50_ms,
  round(quantile_cont(interaction_ms, 0.90))  AS p90_ms,
  round(quantile_cont(interaction_ms, 0.99))  AS p99_ms,
  round(max(interaction_ms))                  AS max_ms
FROM ev
WHERE interaction_ms IS NOT NULL;

.print
.print ── API リクエスト所要時間 (claude_code.api_request) ──
SELECT
  model,
  coalesce(speed, '-')  AS speed,
  coalesce(effort, '-') AS effort,
  count(*)                             AS n,
  round(quantile_cont(dur_ms, 0.50))   AS p50_ms,
  round(quantile_cont(dur_ms, 0.90))   AS p90_ms,
  round(quantile_cont(dur_ms, 0.99))   AS p99_ms,
  round(max(dur_ms))                   AS max_ms,
  round(avg(out_tok))                  AS avg_out_tok
FROM ev
WHERE event LIKE '%api_request' AND dur_ms IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY n DESC;

.print
.print ── TTFT (トレース span の ttft_ms) ───────────────────
SELECT
  model,
  coalesce(speed, '-') AS speed,
  count(*)                           AS n,
  round(quantile_cont(ttft, 0.50))   AS p50_ms,
  round(quantile_cont(ttft, 0.90))   AS p90_ms,
  round(quantile_cont(ttft, 0.99))   AS p99_ms,
  round(max(ttft))                   AS max_ms
FROM ev
WHERE ttft IS NOT NULL
GROUP BY 1, 2
ORDER BY n DESC;

.print
.print ── プロンプト単位の待ち時間内訳 (モデル時間 vs ツール時間) ──
WITH per_prompt AS (
  SELECT
    prompt_id,
    sum(CASE WHEN event LIKE '%api_request'  THEN dur_ms END) AS api_ms,
    sum(CASE WHEN event LIKE '%tool_result' THEN dur_ms END)  AS tool_ms,
    count(CASE WHEN event LIKE '%api_request'  THEN 1 END)     AS n_api,
    count(CASE WHEN event LIKE '%tool_result' THEN 1 END)      AS n_tool
  FROM ev
  WHERE prompt_id IS NOT NULL AND kind = 'log'
  GROUP BY 1
)
SELECT
  count(*)                                        AS prompts,
  round(quantile_cont(coalesce(api_ms, 0), 0.50))  AS p50_api_ms,
  round(quantile_cont(coalesce(api_ms, 0), 0.90))  AS p90_api_ms,
  round(quantile_cont(coalesce(tool_ms, 0), 0.50)) AS p50_tool_ms,
  round(quantile_cont(coalesce(tool_ms, 0), 0.90)) AS p90_tool_ms,
  round(avg(n_api), 1)                             AS avg_api_calls,
  round(avg(n_tool), 1)                            AS avg_tool_calls
FROM per_prompt;

.print
.print ── ツール別所要時間 (上位 15) ────────────────────────
SELECT
  tool_name,
  count(*)                           AS n,
  sum(CASE WHEN tool_success = 'false' THEN 1 ELSE 0 END) AS failures,
  round(quantile_cont(dur_ms, 0.50)) AS p50_ms,
  round(quantile_cont(dur_ms, 0.90)) AS p90_ms,
  round(sum(dur_ms) / 1000)          AS total_s
FROM ev
WHERE event LIKE '%tool_result' AND tool_name IS NOT NULL
GROUP BY 1
ORDER BY total_s DESC NULLS LAST
LIMIT 15;

.print
.print ── API エラー / リトライ ─────────────────────────────
SELECT
  model,
  status_code,
  attempt,
  count(*)                           AS n,
  round(quantile_cont(dur_ms, 0.50)) AS p50_ms
FROM ev
WHERE event LIKE '%api_error'
GROUP BY 1, 2, 3
ORDER BY n DESC;

.print
.print ── 日別 ─────────────────────────────────────────────
SELECT
  ts::DATE                           AS day,
  count(*)                           AS requests,
  round(quantile_cont(dur_ms, 0.50)) AS p50_ms,
  round(quantile_cont(dur_ms, 0.90)) AS p90_ms,
  round(sum(cost), 3)                AS cost_usd
FROM ev
WHERE event LIKE '%api_request'
GROUP BY 1
ORDER BY 1;
SQL

exec duckdb -init "$init" -f "$report"
