---
description: Manage language-specific voice settings
---

# CVI Voice Configuration

CVI（Claude Voice Integration）の音声設定を管理します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi-voice $ARGUMENTS
```

## 引数

- （引数なし） - 現在の音声設定を表示
- `en [VOICE]` - 英語音声を設定（例: `en Zoe`）
- `ja [VOICE]` - 日本語音声を設定（例: `ja Kyoko`）
- `mode auto` - 自動音声選択モード
- `mode fixed` - 固定音声モード
- `fixed [VOICE]` - 全言語で使用する固定音声を設定
- `list` - 利用可能な音声一覧を表示
- `reset` - デフォルト設定に戻す

## 使用例

- `/cvi-voice` - 現在の設定を確認
- `/cvi-voice en Zoe` - 英語音声をZoeに設定
- `/cvi-voice ja Kyoko` - 日本語音声をKyokoに設定
- `/cvi-voice mode auto` - 自動音声選択モード
- `/cvi-voice list` - 利用可能な音声を確認

## 人気の音声

**日本語**:
- `system` - システムデフォルト
- `Kyoko` - 標準日本語（女性）
- `Otoya` - 標準日本語（男性）

**英語**:
- `system` - システムデフォルト
- `Samantha` - 標準的でクリア（女性）
- `Zoe` - プレミアム（女性）
- `Daniel` - イギリス英語（男性）

実行後、結果を報告してください。
