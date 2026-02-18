# ヘッダー画像生成ガイド

X Articles のヘッダー画像は記事の第一印象を決める重要な要素。
`header-image.py` スクリプトを使って 1200×480px の PNG を生成する。

---

## 推奨仕様

| 項目 | 推奨値 |
|------|-------|
| サイズ | 1200 × 480 px |
| フォーマット | PNG |
| 背景 | 白（#ffffff）またはダーク（#1a1a2e） |
| タイトルフォント | 72pt、黒（#1a1a1a） |
| サブタイトルフォント | 32pt、アクセントカラー（#0077B6） |
| 下マージン | 最低 60px（X でクロップされないため） |

**重要**: 下端 60px 以内にテキストを配置しないこと。X のサムネイル表示でクロップされる。

---

## フォント検出のデバッグ手順

### 1. システムフォントの確認

```bash
# CJK フォントを検索
fc-list :lang=ja

# 出力例（macOS + Noto CJK インストール済み）
/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc: Noto Sans CJK JP:style=Regular
```

### 2. フォントが見つからない場合（Linux）

```bash
apt-get install -y fonts-noto-cjk
```

macOS では `fc-list` コマンド自体が存在しない場合があるため、スクリプトはエラーなく DejaVu Sans にフォールバックする（日本語は豆腐文字になるが処理は継続）。

### 3. macOS でのフォントパス

```python
# macOS でよく見られるフォントパス
FONT_CANDIDATES = [
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/Library/Fonts/Arial Unicode MS.ttf",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",  # フォールバック
]
```

---

## テキスト折り返し実装パターン

`PIL.ImageDraw.textbbox()` を使ってピクセル幅を測定し、折り返しを行う:

```python
def wrap_text(draw, text, font, max_width):
    """テキストを max_width に収まるように折り返す"""
    words = text.split()
    lines = []
    current_line = []

    for word in words:
        test_line = ' '.join(current_line + [word])
        bbox = draw.textbbox((0, 0), test_line, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current_line.append(word)
        else:
            if current_line:
                lines.append(' '.join(current_line))
            current_line = [word]

    if current_line:
        lines.append(' '.join(current_line))

    return lines
```

---

## 日英混在レイアウトの推奨値

```
キャンバス: 1200 × 480 px
上余白: 60px
左右余白: 80px（コンテンツ幅: 1040px）

英語タイトル（H1）:
  フォントサイズ: 72pt
  色: #1a1a1a
  行間: 1.2
  上端: 80px（上余白 + タイトル開始）

日本語サブタイトル（H2）:
  フォントサイズ: 32pt
  色: #0077B6
  行間: 1.3
  上端: タイトル下端 + 24px

下マージン確保:
  最後のテキスト下端から画像下端まで: 最低 60px
```

---

## 失敗例

### 失敗例 1: フォントが小さすぎて潰れた

- 原因: サブタイトルを 18pt に設定し、折り返し後に 5 行になった
- 解決: フォントサイズを上げてテキストを短くするか、折り返し幅を広げる

### 失敗例 2: 下端にテキストを配置してクロップされた

- 原因: サブタイトルの末尾が y=450（下端 30px）に達していた
- 解決: `max_content_height = image_height - 60` を上限として設定

### 失敗例 3: Pillow 未インストール

- 解決: スクリプトが自動検出して `pip install Pillow` を実行する（`header-image.py` に実装済み）
