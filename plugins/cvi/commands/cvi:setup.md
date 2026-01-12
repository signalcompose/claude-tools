---
description: CVI Setup Command
---

# CVI Setup

CVI（Claude Voice Integration）の初期セットアップを行います。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-setup $ARGUMENTS
```

## 引数

- `global` - グローバルインストール（全プロジェクトで有効）
- `project` - プロジェクトローカル（現在のプロジェクトのみ）
- （引数なし） - ヘルプを表示

## セットアップ内容

- スクリプトのコピーと権限設定
- hooks設定の追加
- 初期設定（速度、言語）
- Siri音声設定の確認

## 使用例

- `/cvi:setup global` - グローバルインストール
- `/cvi:setup project` - プロジェクトローカルインストール

## 注意

プラグインとしてインストールした場合、このセットアップは不要です。
手動インストール時のみ使用してください。

実行後、結果を報告してください。
