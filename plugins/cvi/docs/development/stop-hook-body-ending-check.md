# Stop hook の本文終端チェック

## 入力

`check-body-ending.sh` は Stop hook の標準入力から JSON を受け取る。利用するフィールドは
`transcript_path`（Claude Code の transcript JSONL へのパス）と
`stop_hook_active`（直前の Stop hook による再試行か）である。transcript は 1 行 1 JSON
オブジェクトで、`type`、`message.content`、必要に応じて `toolUseResult` と `isMeta` を持つ
Claude Code の記録を前提とする。

## ターン内の assistant text ブロック

最後の「実ユーザープロンプト」より後を現在のターンとする。`type == "user"` でも、
`toolUseResult` を持つ行、`isMeta == true` の行、または `message.content` に
`tool_result` ブロックを含む行はターン境界にしない。現在のターンにある assistant の
`message.content` を順に調べ、`type == "text"` のブロックを**すべて結合**して検査対象とする
（最後の1ブロックだけではない）。

日本語モードでは、コードフェンスとインラインコードを除いた散文を次の二条件で検査する。

1. ターン全体を通して日本語文字が一箇所もない場合は違反とする。
2. 日本語文字がターンのどこかにある場合でも、最後の非空行が日本語文字を含まず、かつ
   `^[[:space:]]*\**[Vv]oice\**[[:space:]]*:` にマッチする Voice 行でもなければ違反とする。

CVI のルールは「日本語＝本文表示、英語＝ヒアリング用の概要」という役割分担があり、本文と
Voice 行の表示順序は問わない。したがって日本語本文が Voice 行より先でも後でもよく、末尾は
日本語の散文または Voice 行のどちらでもよい（issue #289）。一方、ターン途中に日本語があっても、
無関係な英語散文で応答を終えることは許可しない。

## コードのみの例外

コードブロックのみで構成され、コードを除くと散文が空になる応答は許可する。コードそのものへ
日本語を混入させると成果物の正確性を損ねる可能性があり、意図的にコードだけを返す要求にも
不要な説明を加えることになるためである。

## speak hook との同時違反

どちらの本文違反時も transcript 内の `tool_use` と、`cvi:speak` Skill または対応する speak MCP
ツール名の組み合わせを `check-speak-called.sh` と同じ条件で確認する。speak 済みなら二重再生を
避けるため再呼び出しを禁止し、本文だけの修正を求める。未呼び出しなら、日本語本文への修正と
`/cvi:speak` の呼び出しを同時に求める。これにより、実行順が未規定の二つの Stop hook が
同時に block しても指示は矛盾しない。

## fail-open 条件

以下では block decision を出さず、終了コード 0 で停止を許可する。

- `jq` が利用できない
- hook 入力が不正な JSON
- `stop_hook_active` が true
- `scripts/lib/config.sh` の source または `load_cvi_config` が失敗する
- CVI が無効
- `transcript_path` が空、存在しない、読めない、または空ファイル
- transcript JSONL が解析できない
- 現在のターンに assistant text ブロックがない
