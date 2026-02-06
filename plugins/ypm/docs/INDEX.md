# YPM ドキュメント索引

**最終更新**: 2026-01-10

このディレクトリには、YPM (Your Project Manager) の設計・使用方法に関するドキュメントが格納されています。

---

## 📚 ドキュメント一覧

### 必読ドキュメント

| ドキュメント | 説明 | 対象読者 |
|------------|------|---------|
| [../README.md](../README.md) | YPMの概要と使い方 | 全員 |
| [../CLAUDE.md](../CLAUDE.md) | Claude Code向け指示書（英語） | AI開発者 |
| [LANGUAGE_STRATEGY.md](LANGUAGE_STRATEGY.md) | YPMの言語戦略とバイリンガル設計方針（英語） | コントリビューター、国際ユーザー |
| [../config.example.yml](../config.example.yml) | 設定ファイルサンプル（監視対象、検出パターン） | 設定変更者 |
| [../project-bootstrap-prompt.md](../project-bootstrap-prompt.md) | 新規プロジェクト立ち上げガイド（非推奨：`/ypm:project-bootstrap`スキルを使用） | 全員 |

### 開発者向けドキュメント

| ドキュメント | 説明 | 対象読者 |
|------------|------|---------|
| [development/architecture.md](development/architecture.md) | YPMの全体アーキテクチャと設計原則 | コントリビューター、開発者 |
| [development/onboarding-script-spec.md](development/onboarding-script-spec.md) | オンボーディングウィザードの仕様書 | コントリビューター、開発者 |
| [development/ypm-open-spec.md](development/ypm-open-spec.md) | `/ypm:open` コマンドの仕様書 | コントリビューター、開発者 |
| [development/global-export-system.md](development/global-export-system.md) | グローバルエクスポートシステムの設計・使用方法 | コントリビューター、開発者 |

---

## 📖 読む順序

### 初めて使う場合

1. **[README.md](../README.md)** - YPMとは何か、どう使うか
2. **[config.yml](../config.yml)** - 監視対象の設定
3. **[PROJECT_STATUS.md](../PROJECT_STATUS.md)** - 現在のプロジェクト状況を確認

### Claude Codeで開発する場合

1. **[CLAUDE.md](../CLAUDE.md)** - セッション開始時の手順
2. **[docs/INDEX.md](INDEX.md)** - ドキュメント索引

### 設定をカスタマイズする場合

1. **[config.yml](../config.yml)** - 監視対象ディレクトリ、検出パターン、分類基準
2. **[README.md](../README.md)** - カスタマイズ方法の説明

### YPMに貢献する場合

1. **[development/architecture.md](development/architecture.md)** - 全体アーキテクチャを理解する
2. **[CLAUDE.md](../CLAUDE.md)** - DDD原則と開発フロー
3. **[development/onboarding-script-spec.md](development/onboarding-script-spec.md)** - 実装例として参照

---

## 🎯 ドキュメントの目的

### README.md
- **目的**: YPMの使い方を説明する
- **対象**: YPMを使いたい全員
- **含まれる内容**: 概要、特徴、セットアップ、使い方、FAQ

### CLAUDE.md
- **目的**: Claude Codeがタスクを実行できるようにする
- **対象**: AI開発者（Claude Code）
- **含まれる内容**: セッション開始手順、主な機能、PROJECT_STATUS.mdの構造、更新ルール

### config.yml
- **目的**: 監視対象やプロジェクト検出ルールを定義する
- **対象**: YPMを設定する人
- **含まれる内容**: 監視ディレクトリ、除外パターン、検出パターン、分類基準、進捗率推測基準

### PROJECT_STATUS.md
- **目的**: 全プロジェクトの進捗状況を一覧表示する
- **対象**: プロジェクト管理者、開発者
- **含まれる内容**: プロジェクトカテゴリ別一覧、進捗率、次のタスク、最終更新日時


### development/architecture.md
- **目的**: YPMの全体アーキテクチャと設計原則を説明する
- **対象**: コントリビューター、開発者
- **含まれる内容**: DDD原則、ディレクトリ構造、コンポーネント、データフロー、拡張性

### development/onboarding-script-spec.md
- **目的**: オンボーディングウィザードの完全な仕様を提供する
- **対象**: コントリビューター、開発者
- **含まれる内容**: 機能要件、入力仕様、出力仕様、エラーハンドリング、実装スケルトン

---

## 🔄 ドキュメント更新ルール

### いつ更新するか

- **config.yml**: 監視対象や検出ルールを変更する時
- **README.md**: 使い方が変わった時、FAQが増えた時
- **CLAUDE.md**: YPMの機能が追加された時、ルールが変更された時

### 誰が更新するか

- **config.yml**: ユーザーが手動で編集
- **README.md, CLAUDE.md**: 必要に応じて手動で編集

---

## 📝 ドキュメント管理の原則

### 1. ドキュメントは常に最新に

古い情報は即座に更新してください。ドキュメントと実態が乖離すると、YPMの信頼性が損なわれます。

### 2. 簡潔で分かりやすく

冗長な説明は避け、必要最小限の情報を提供してください。

### 3. 具体例を含める

抽象的な説明だけでなく、具体的なコード例や設定例を含めてください。

---

## 🚀 今後の拡張予定

### ドキュメント追加計画

- **設定ガイド** (`docs/config_guide.md`) - config.ymlの詳細説明
- **トラブルシューティング** (`docs/troubleshooting.md`) - よくある問題と解決策
- **自動化ガイド** (`docs/automation.md`) - cron設定やスクリプト化の方法
- **ダッシュボード設計** (`docs/dashboard_design.md`) - Webベースの可視化ツールの設計

---

## 📞 サポート

- **設定の疑問**: [config.example.yml](../config.example.yml)のコメントを参照
- **使い方の疑問**: [README.md](../README.md)を確認
- **開発の疑問**: [CLAUDE.md](../CLAUDE.md)の手順を確認

---

**このドキュメントは、YPMの全体像を把握するための索引です。** 📚
