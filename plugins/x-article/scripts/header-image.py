#!/usr/bin/env python3
"""
X Articles ヘッダー画像生成スクリプト

使い方:
  python3 header-image.py --title "Article Title" [--subtitle "サブタイトル"] [--output header.png]
"""

from __future__ import annotations

import argparse
import subprocess
import sys


def ensure_pillow():
    """Pillow が未インストールの場合は自動インストール"""
    try:
        from PIL import Image, ImageDraw, ImageFont  # noqa: F401
    except ImportError:
        print("Pillow が見つかりません。インストールします...", flush=True)
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        print("Pillow のインストール完了", flush=True)


ensure_pillow()

from PIL import Image, ImageDraw, ImageFont  # noqa: E402


# ─── 定数 ────────────────────────────────────────────────

CANVAS_WIDTH = 1200
CANVAS_HEIGHT = 480
BG_COLOR = "#ffffff"
TITLE_COLOR = "#1a1a1a"
SUBTITLE_COLOR = "#0077B6"
TITLE_FONT_SIZE = 72
SUBTITLE_FONT_SIZE = 32
MARGIN_H = 80       # 左右マージン
MARGIN_TOP = 80     # 上マージン
MARGIN_BOTTOM = 60  # 下マージン（X クロップ対策）
LINE_SPACING_TITLE = 1.2
LINE_SPACING_SUBTITLE = 1.3

CONTENT_WIDTH = CANVAS_WIDTH - MARGIN_H * 2
MAX_CONTENT_HEIGHT = CANVAS_HEIGHT - MARGIN_TOP - MARGIN_BOTTOM


# ─── フォント検出 ─────────────────────────────────────────

def find_cjk_font() -> str | None:
    """CJK フォントを fc-list で検索（Linux/macOS）"""
    try:
        result = subprocess.run(
            ["fc-list", ":lang=ja"],
            capture_output=True, text=True, timeout=5
        )
        lines = result.stdout.strip().splitlines()
        for line in lines:
            path = line.split(":")[0].strip()
            if path.endswith((".ttf", ".otf", ".ttc")):
                return path
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None


def try_install_noto_cjk():
    """Noto CJK フォントのインストールを試みる（失敗しても続行）"""
    try:
        subprocess.run(
            ["apt-get", "install", "-y", "fonts-noto-cjk"],
            capture_output=True, timeout=60
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, Exception):
        pass


_noto_install_attempted = False

FALLBACK_FONTS = [
    # macOS
    "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/Library/Fonts/Arial Unicode MS.ttf",
    # Linux
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    # DejaVu（最終フォールバック）
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/dejavu/DejaVuSans.ttf",
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """フォントを検出してロード。見つからなければデフォルトフォントを使用"""
    # 1. fc-list で検索
    cjk_path = find_cjk_font()
    if cjk_path:
        try:
            return ImageFont.truetype(cjk_path, size)
        except Exception:
            pass

    # 2. apt-get でインストール試行（失敗しても続行、1回のみ）
    global _noto_install_attempted
    if not _noto_install_attempted:
        _noto_install_attempted = True
        try_install_noto_cjk()
    cjk_path = find_cjk_font()
    if cjk_path:
        try:
            return ImageFont.truetype(cjk_path, size)
        except Exception:
            pass

    # 3. ハードコードされたパス候補
    for path in FALLBACK_FONTS:
        try:
            return ImageFont.truetype(path, size)
        except (FileNotFoundError, Exception):
            continue

    # 4. Pillow デフォルトフォント（日本語は豆腐になるがエラーにしない）
    print("警告: CJK フォントが見つかりませんでした。デフォルトフォント使用（日本語は豆腐になります）", file=sys.stderr)
    return ImageFont.load_default()


# ─── テキスト折り返し ──────────────────────────────────────

def wrap_text(draw: ImageDraw.ImageDraw, text: str, font, max_width: int) -> list[str]:
    """テキストを max_width に収まるように折り返す"""
    # 日本語は空白なしで折り返せるようにする
    words = []
    current = ""
    for char in text:
        if char == " ":
            if current:
                words.append(current)
                current = ""
            words.append(" ")
        else:
            # CJK 文字は 1 文字単位でも折り返し可能
            if current and _is_cjk(char) and not _is_cjk(current[-1]):
                words.append(current)
                current = char
            elif current and not _is_cjk(char) and _is_cjk(current[-1]):
                words.append(current)
                current = char
            else:
                current += char
    if current:
        words.append(current)

    lines = []
    current_line = ""
    for word in words:
        test = current_line + word
        bbox = draw.textbbox((0, 0), test.strip(), font=font)
        w = bbox[2] - bbox[0]
        if w <= max_width:
            current_line = test
        else:
            if current_line.strip():
                lines.append(current_line.strip())
            current_line = word
    if current_line.strip():
        lines.append(current_line.strip())
    return lines or [text]


def _is_cjk(char: str) -> bool:
    cp = ord(char)
    return (
        0x4E00 <= cp <= 0x9FFF or   # CJK Unified
        0x3040 <= cp <= 0x30FF or   # ひらがな・カタカナ
        0xFF00 <= cp <= 0xFFEF      # 全角
    )


# ─── メイン描画 ───────────────────────────────────────────

def generate_header(title: str, subtitle: str | None, output: str):
    img = Image.new("RGB", (CANVAS_WIDTH, CANVAS_HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)

    title_font = load_font(TITLE_FONT_SIZE)
    subtitle_font = load_font(SUBTITLE_FONT_SIZE) if subtitle else None

    y = MARGIN_TOP

    # タイトル描画
    title_lines = wrap_text(draw, title, title_font, CONTENT_WIDTH)
    for line in title_lines:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        line_height = bbox[3] - bbox[1]
        # 下マージン超えチェック
        if y + line_height > CANVAS_HEIGHT - MARGIN_BOTTOM:
            print("警告: タイトルが下マージンを超えます。フォントサイズを小さくするか、テキストを短くしてください。", file=sys.stderr)
            break
        draw.text((MARGIN_H, y), line, font=title_font, fill=TITLE_COLOR)
        y += int(line_height * LINE_SPACING_TITLE)

    # サブタイトル描画
    if subtitle and subtitle_font:
        y += 24  # タイトルとの間隔
        subtitle_lines = wrap_text(draw, subtitle, subtitle_font, CONTENT_WIDTH)
        for line in subtitle_lines:
            bbox = draw.textbbox((0, 0), line, font=subtitle_font)
            line_height = bbox[3] - bbox[1]
            if y + line_height > CANVAS_HEIGHT - MARGIN_BOTTOM:
                print("警告: サブタイトルが下マージンを超えます。", file=sys.stderr)
                break
            draw.text((MARGIN_H, y), line, font=subtitle_font, fill=SUBTITLE_COLOR)
            y += int(line_height * LINE_SPACING_SUBTITLE)

    img.save(output)
    print(f"✅ ヘッダー画像を保存しました: {output} ({CANVAS_WIDTH}x{CANVAS_HEIGHT}px)")


# ─── CLI ─────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="X Articles ヘッダー画像生成")
    parser.add_argument("--title", required=True, help="英語タイトル（必須）")
    parser.add_argument("--subtitle", default=None, help="日本語サブタイトル（任意）")
    parser.add_argument("--output", default="header.png", help="出力ファイルパス（デフォルト: header.png）")
    args = parser.parse_args()

    generate_header(args.title, args.subtitle, args.output)


if __name__ == "__main__":
    main()
