#!/bin/bash
# watch-codex.sh - Watch a Codex companion job for progress, stalls, and external kills.
#
# 🔴 なぜ companion の `status --json` を信用しないか（2026-08-27 実測）
#
#   1. dead pid の回収処理が openai-codex/codex に存在しない。ジョブが外部から kill
#      されても state.json は `"status": "running"` のまま残る。
#      `until status != running` の待機ループは**永久に発火しない**。これで 64 分を失った。
#
#   2. `status --json` の `running[]` は**現在の Claude セッション ID でフィルタされる**
#      （codex-companion.mjs の filterJobsForCurrentClaudeSession）。所有セッション外から
#      監視すると `running: []` が返り、DONE 判定が初回ポーリングで誤発火する。
#
#   よってこのスクリプトは companion を一切呼ばず、state.json を直接読む。
#   生存signal は「自己申告の status」ではなく、以下の2つの事実で判定する:
#     - ログファイルの mtime（実際に書かれているか）
#     - pid の生存（kill -0。ps/pgrep は sandbox で拒否されうるがシェル組み込みは通る）
#
# 出力する行（＝通知される事象）と exit code:
#   MILESTONE …  コマンド完了（exit code つき）             -
#   PHASE     …  editing -> verifying などの遷移            -
#   STALL     …  ログが伸びていない・**プロセスは生存**      2
#   KILLED    …  **pid 消滅・status は running のまま**      3
#   DONE      …  ジョブが running/queued から外れた          0
#   ERROR     …  監視対象を解決できない                      1
#
# STALL と KILLED を分けるのが要点。原因が違えば対処も違う（ハング→原因調査 / kill→再開）。

set -uo pipefail

STALL_SECS=420
INTERVAL=30
KILL_GRACE=10
MAX_QUERY_FAILURES=3
JOB_ID=""
WORKSPACE=""
STATE_ROOT=""

usage() {
  cat <<'USAGE'
Usage: watch-codex.sh [job-id] [options]

Arguments:
  job-id              監視する Codex ジョブ ID（例 task-mtbk39bq-u4v4up）。
                      省略時は対象 workspace で最も新しい running/queued ジョブ。

Options:
  --stall-secs N      ログが N 秒伸びなければ STALL とする（既定 420 = 7分）
  --interval N        ポーリング間隔（既定 30 秒）
  --workspace PATH    対象 workspace（既定: git のルート、無ければ cwd）
  --state-root PATH   Codex の state ルート
                      （既定: $CLAUDE_PLUGIN_DATA/state、無ければ
                        ~/.claude/plugins/data/codex-openai-codex/state）
  -h, --help          このヘルプ

Exit codes: 0=DONE  1=ERROR  2=STALL  3=KILLED
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stall-secs)  STALL_SECS="${2:-}"; shift 2 ;;
    --interval)    INTERVAL="${2:-}";   shift 2 ;;
    --workspace)   WORKSPACE="${2:-}";  shift 2 ;;
    --state-root)  STATE_ROOT="${2:-}"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    -*)            echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)             JOB_ID="$1"; shift ;;
  esac
done

# bash 3.2 (macOS 既定) で動く書き方に限定する。${var,,} などの bash 4 構文は使わない。
require_positive_int() {
  local flag="$1" value="$2"
  case "$value" in
    ''|*[!0-9]*) ;;
    *) if (( value >= 1 )); then return 0; fi ;;
  esac
  echo "ERROR: $flag には 1 以上の整数を指定する（受け取った値: '$value'）" >&2
  exit 1
}

require_positive_int --stall-secs "$STALL_SECS"
require_positive_int --interval "$INTERVAL"

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 が見つからない" >&2; exit 1; }

if [[ -z "$WORKSPACE" ]]; then
  WORKSPACE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd -P)" || {
  echo "ERROR: workspace に到達できない" >&2; exit 1; }

if [[ -z "$STATE_ROOT" ]]; then
  STATE_ROOT="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/codex-openai-codex}/state"
fi

if [[ ! -d "$STATE_ROOT" ]]; then
  echo "ERROR: Codex の state ディレクトリが無い: $STATE_ROOT"
  echo "ERROR: openai-codex/codex プラグインが未導入か、ジョブがまだ1件も走っていない。"
  exit 1
fi

# state.json 群から対象ジョブを1件選ぶ。
# workspace の特定にハッシュ（sha256(realpath(gitroot))[:16]）は再実装しない。
# 各ジョブが workspaceRoot を文字列で持っているので、それで突き合わせる方が
# 上流のハッシュ実装が変わっても壊れない。
query_job() {
  python3 - "$STATE_ROOT" "$WORKSPACE" "$JOB_ID" <<'PY'
import glob, json, os, sys

state_root, workspace, job_id = sys.argv[1], sys.argv[2], sys.argv[3]

def real(path):
    try:
        return os.path.realpath(path)
    except Exception:
        return path

want = real(workspace)
best = None

for state_file in glob.glob(os.path.join(state_root, '*', 'state.json')):
    try:
        with open(state_file, encoding='utf-8') as handle:
            data = json.load(handle)
    except Exception:
        continue
    for job in data.get('jobs') or []:
        if job_id:
            if job.get('id') != job_id:
                continue
        else:
            if real(job.get('workspaceRoot') or '') != want:
                continue
            if job.get('status') not in ('running', 'queued'):
                continue
        if best is None or (job.get('updatedAt') or '') > (best.get('updatedAt') or ''):
            best = job

if best is None:
    sys.exit(4)

fields = [
    best.get('id') or '',
    best.get('status') or '',
    best.get('phase') or '',
    str(best.get('pid') or ''),
    best.get('logFile') or '',
    best.get('updatedAt') or '',
]
print('\t'.join(field.replace('\t', ' ') for field in fields))
PY
}

# 戻り値を潰さないこと。0=取得成功 / 4=該当ジョブなし / その他=クエリ自体の失敗。
# この3つを1つの「失敗」に畳むと、クエリが壊れただけで「ジョブが消えた」と読めてしまう。
read_snapshot() {
  local snapshot rc
  snapshot="$(query_job)"; rc=$?
  if (( rc != 0 )); then
    return "$rc"
  fi
  IFS=$'\t' read -r JOB_ID STATUS PHASE PID LOG UPDATED <<<"$snapshot"
  return 0
}

file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

# ログに ANSI は現状含まれないが、混ざっても行が読めるよう保険で落とす。
strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g'; }

last_command() {
  if [[ -n "$LOG" && -f "$LOG" ]]; then
    strip_ansi < "$LOG" | grep -a "Running command" | tail -1 | cut -c1-200
  else
    echo "(ログ未生成)"
  fi
}

STATUS=""; PHASE=""; PID=""; LOG=""; UPDATED=""

read_snapshot; rc=$?
if (( rc == 4 )); then
  if [[ -n "$JOB_ID" ]]; then
    echo "ERROR: ジョブ '$JOB_ID' が state に見つからない"
  else
    echo "ERROR: $WORKSPACE で running/queued の Codex ジョブが見つからない"
    echo "ERROR: 発注前に監視を起動した場合は、ジョブ開始後に再実行するか job-id を渡す。"
  fi
  exit 1
elif (( rc != 0 )); then
  echo "ERROR: state の読み取り自体に失敗した (rc=$rc)。'$STATE_ROOT' と python3 を確認する。"
  echo "ERROR: これは「ジョブが無い」とは別の事象なので、無いものとして扱わない。"
  exit 1
fi

# 以降は解決した JOB_ID に固定して追う（監視中に別ジョブへ乗り移らないため）。
echo "MILESTONE watching $JOB_ID  workspace=$(basename "$WORKSPACE")  stall=${STALL_SECS}s  interval=${INTERVAL}s"
[[ -n "$LOG" ]] && echo "MILESTONE log=$LOG"

last_phase="$PHASE"
dead_since=0
query_failures=0

# 起動時点の完了済みコマンド数を基準にする。監視は「これから起きる事象」を報告するもので、
# 途中から張り付いた時に過去のマイルストーンを全部読み上げても通知として役に立たない。
last_count=0
if [[ -n "$LOG" && -f "$LOG" ]]; then
  last_count="$(grep -ac "Command completed" "$LOG" 2>/dev/null || true)"
  last_count="${last_count:-0}"
  if (( last_count > 0 )); then
    echo "MILESTONE (既に完了 ${last_count} 件) 直近: $(strip_ansi < "$LOG" | grep -a "Command completed" | tail -1 | cut -c1-200)"
  fi
fi

while true; do
  read_snapshot; rc=$?
  if (( rc == 4 )); then
    echo "DONE ジョブ $JOB_ID が state から消えた（履歴上限で削除された可能性）"
    exit 0
  elif (( rc != 0 )); then
    # 🔴 クエリの失敗を DONE として報告しない。
    # 監視ツールが自分の故障を「対象の正常完了」と報告するのが最悪の壊れ方であり、
    # このスクリプトが存在する理由そのもの。数回は一過性として許容し、続くなら ERROR で落とす。
    query_failures=$(( query_failures + 1 ))
    echo "WARN state の読み取りに失敗した (rc=$rc) ${query_failures}/${MAX_QUERY_FAILURES}"
    if (( query_failures >= MAX_QUERY_FAILURES )); then
      echo "ERROR state を連続 ${MAX_QUERY_FAILURES} 回読めなかった。監視を継続できない。"
      echo "ERROR ジョブの生死は不明。DONE ではない。"
      exit 1
    fi
    sleep "$INTERVAL"
    continue
  else
    query_failures=0
  fi

  # --- 進捗: 前回以降に増えた "Command completed" 行をすべて出す ---
  if [[ -n "$LOG" && -f "$LOG" ]]; then
    count="$(grep -ac "Command completed" "$LOG" 2>/dev/null || true)"
    count="${count:-0}"
    if (( count > last_count )); then
      while IFS= read -r line; do
        [[ -n "$line" ]] && echo "MILESTONE $line"
      done < <(strip_ansi < "$LOG" | grep -a "Command completed" \
               | tail -n +"$((last_count + 1))" | cut -c1-200)
      last_count="$count"
    fi
  fi

  # --- フェーズ遷移 ---
  if [[ -n "$PHASE" && "$PHASE" != "$last_phase" ]]; then
    echo "PHASE ${last_phase:-?} -> $PHASE"
    last_phase="$PHASE"
  fi

  # --- 正常終了 ---
  if [[ "$STATUS" != "running" && "$STATUS" != "queued" ]]; then
    echo "DONE ジョブが status=$STATUS になった（phase=${PHASE:-?}）"
    exit 0
  fi

  # --- プロセスの生存を先に確定させる ---
  # kill された場合と単に遅い場合は対処が違うので、まず「どちらなのか」を決める。
  # 順序が要点: pid が死んでいる間は STALL を判定しない。判定してしまうと、
  # 外部 kill された古いジョブが（ログが伸びていないという理由で）STALL と誤報される。
  pid_dead=0
  if [[ -n "$PID" ]] && ! kill -0 "$PID" 2>/dev/null; then
    pid_dead=1
  fi

  if (( pid_dead )); then
    # 正常終了の瞬間は「pid 消滅 → state 書き込み」の順で一瞬 stale に見えるため、
    # KILL_GRACE 秒をまたいで消滅が続いた時だけ KILLED と判定する。
    now="$(date +%s)"
    if (( dead_since == 0 )); then
      dead_since="$now"
    elif (( now - dead_since >= KILL_GRACE )); then
      echo "KILLED pid $PID は消滅しているが state は status=$STATUS のまま（stale）。外部 kill の可能性が高い。"
      echo "KILLED 最終更新=$UPDATED  最後のコマンド: $(last_command)"
      exit 3
    fi
  else
    dead_since=0

    # --- 停滞の検出（プロセスは生きている）---
    if [[ -n "$LOG" && -f "$LOG" ]]; then
      age=$(( $(date +%s) - $(file_mtime "$LOG") ))
      if (( age > STALL_SECS )); then
        if [[ -n "$PID" ]]; then
          echo "STALL ログが ${age}s 伸びていない（pid $PID は生存）。ハングか長時間コマンドの可能性。"
        else
          echo "STALL ログが ${age}s 伸びていない（pid 未記録・status=$STATUS）。"
        fi
        echo "STALL 最後のコマンド: $(last_command)"
        exit 2
      fi
    fi
  fi

  sleep "$INTERVAL"
done
