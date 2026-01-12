# CVI Voice Mapping - 音声マッピング機能

## 概要

CVI Voice Mapping機能は、言語別に異なる音声を使用し、柔軟な読み上げ設定を可能にします。

## 主要機能

### 1. 言語別音声設定

日本語と英語で異なる音声を設定できます：

```bash
# 日本語音声を設定
cvi-voice ja Kyoko     # Kyokoに設定
cvi-voice ja system    # システムデフォルト（日本語Siri）

# 英語音声を設定
cvi-voice en Zoe       # Zoeに設定（Premium）
cvi-voice en Samantha  # Samanthaに設定
```

### 2. 言語自動検出

[VOICE]タグ内の言語を自動判定し、適切な音声を選択します：

```bash
# 自動検出を有効化
cvi-auto on

# 自動検出を無効化
cvi-auto off
```

動作例：
- `[VOICE]タスクが完了しました[/VOICE]` → 日本語音声で読み上げ
- `[VOICE]Task completed[/VOICE]` → 英語音声で読み上げ

### 3. 音声モード

#### Autoモード（デフォルト）
言語に基づいて自動的に音声を選択：

```bash
cvi-voice mode auto
```

- 日本語検出時 → VOICE_JA設定の音声を使用
- 英語検出時 → VOICE_EN設定の音声を使用

#### Fixedモード
全ての言語で同じ音声を使用：

```bash
cvi-voice fixed Zoe  # 全ての言語でZoeを使用
```

## 設定ファイル

`~/.cvi/config`に以下の設定が保存されます：

```bash
CVI_ENABLED=on             # CVI機能の有効/無効
SPEECH_RATE=200            # 読み上げ速度
VOICE_LANG=ja              # フォールバック言語
VOICE_EN=Zoe               # 英語用音声
VOICE_JA=Kyoko             # 日本語用音声
AUTO_DETECT_LANG=false     # 言語自動検出
VOICE_MODE=auto            # 音声モード（auto/fixed）
VOICE_FIXED=Zoe            # Fixed時の音声
```

## 使用例

### シナリオ1: 日本語システムで英語学習

```bash
# 設定
cvi-lang ja            # メッセージは日本語
cvi-voice ja system    # 日本語はシステム音声
cvi-voice en Zoe       # 英語はZoe
cvi-auto on            # 自動検出ON

# 動作
[VOICE]Task completed[/VOICE]  # Zoeで英語読み上げ（学習用）
[VOICE]完了しました[/VOICE]      # システム音声で日本語
```

### シナリオ2: 英語システムで日本語学習

```bash
# 設定
cvi-lang en            # メッセージは英語
cvi-voice en Samantha  # 英語はSamantha
cvi-voice ja Kyoko     # 日本語はKyoko
cvi-auto on            # 自動検出ON

# 動作
[VOICE]タスク完了[/VOICE]       # Kyokoで日本語読み上げ
[VOICE]Task done[/VOICE]       # Samanthaで英語
```

### シナリオ3: 特定の音声で統一

```bash
# 設定
cvi-voice fixed Zoe    # 全てZoeで統一

# 動作
[VOICE]完了しました[/VOICE]     # Zoeが日本語を読む
[VOICE]Completed[/VOICE]       # Zoeが英語を読む
```

## トラブルシューティング

### 日本語が無音になる

**原因**: 英語音声で日本語を読もうとしている

**解決策**:
```bash
# 自動検出を有効化
cvi-auto on

# または日本語対応音声を設定
cvi-voice ja Kyoko
```

### 音声が切り替わらない

**原因**: Fixedモードになっている

**解決策**:
```bash
# Autoモードに変更
cvi-voice mode auto
```

### 設定を確認する

```bash
# 現在の設定を表示
cvi-voice

# 自動検出の状態を確認
cvi-auto status

# 設定ファイルを直接確認
cat ~/.cvi/config
```

## 利用可能な音声

### 日本語音声
- `system` - システムデフォルト（日本語Siri）
- `Kyoko` - 標準日本語音声（女性）
- `Otoya` - 標準日本語音声（男性）

### 英語音声
- `system` - システムデフォルト（英語Siri）
- `Samantha` - US英語（女性）
- `Zoe` - UK英語（女性・Premium）
- `Karen` - オーストラリア英語（女性）
- `Daniel` - UK英語（男性）

全ての音声を表示：
```bash
cvi-voice list      # 全音声
cvi-voice list ja   # 日本語音声のみ
cvi-voice list en   # 英語音声のみ
```

## 推奨設定

### 基本設定（日本語ユーザー）
```bash
cvi-lang ja
cvi-voice ja system
cvi-voice en Zoe
cvi-auto on
```

### 基本設定（英語ユーザー）
```bash
cvi-lang en
cvi-voice en Samantha
cvi-voice ja Kyoko
cvi-auto on
```

### シンプル設定（単一言語）
```bash
cvi-voice reset     # デフォルトにリセット
cvi-lang ja         # 日本語を使用
```