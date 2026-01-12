---
description: Manage language auto-detection settings
---

# CVI Language Auto-Detection

CVI（Claude Voice Integration）の言語自動検出を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-auto $ARGUMENTS
```

## 引数

- （引数なし） - 現在の設定を確認
- `on` - 言語自動検出を有効化
- `off` - 言語自動検出を無効化（デフォルト）
- `status` - 詳細ステータス表示

## 言語自動検出の動作

- [VOICE]タグ内のテキストを分析し、日本語/英語を自動判定
- 日本語検出時 → 日本語音声を使用
- 英語検出時 → 英語音声を使用
- 設定言語に関わらず、適切な音声で読み上げ

## 使用例

```bash
# 日本語環境で英語学習
/cvi:lang ja            # フォールバックは日本語
/cvi:voice ja system    # 日本語はシステム音声
/cvi:voice en Zoe       # 英語はZoe（学習用）
/cvi:auto on            # 自動検出ON
```

実行後、結果を報告してください。
