---
description: Manage language-specific voice settings
---

# CVI Voice Selection

CVI（Claude Voice Integration）の音声を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-voice $ARGUMENTS
```

## 引数

- （引数なし） - 現在の設定を確認
- `en [VOICE]` - 英語音声を設定
- `ja [VOICE]` - 日本語音声を設定
- `mode auto` - 自動音声選択モード（デフォルト）
- `mode fixed` - 固定音声モード
- `fixed [VOICE]` - 全言語で使用する音声を設定
- `list` - 利用可能な音声一覧
- `reset` - デフォルトに戻す

## 人気の音声

### 日本語
- **system**: システムデフォルト（日本語Siri）
- **Kyoko**: 標準日本語音声（女性）
- **Otoya**: 標準日本語音声（男性）

### 英語
- **system**: システムデフォルト（英語Siri）
- **Samantha** (US): 標準的でクリアな女性の声
- **Zoe** (UK): プレミアム女性音声
- **Daniel** (UK): イギリス英語、男性

## 使用例

- `/cvi:voice` - 現在の設定を確認
- `/cvi:voice en Zoe` - 英語音声をZoeに設定
- `/cvi:voice ja Kyoko` - 日本語音声をKyokoに設定
- `/cvi:voice list` - 利用可能な音声一覧

実行後、結果を報告してください。
