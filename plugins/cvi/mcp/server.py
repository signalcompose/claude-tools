#!/usr/bin/env python3
"""
CVI Voice MCP Server — interim TTS server while parrotvox is in development.

Exposes a single `speak` tool that invokes macOS `say` for text-to-speech.
The tool signature deliberately mirrors the planned parrotvox MCP shape so
the migration reduces to swapping the server registration.

This server runs as a subprocess of Claude Code via .mcp.json registration
and communicates over stdio JSON-RPC. Because MCP servers execute outside
the Bash sandbox, `say` works natively without needing
`dangerouslyDisableSandbox: true`. (The notification / Glass-sound pieces
that use `afplay` / `osascript` remain in the bash fallback — this server
focuses on the speak tool only.)

Fallback: if this server fails to start, the bundled bash post-speak.sh
remains the speak path — see plugins/cvi/commands/speak.md.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("cvi-voice")


CVI_CONFIG_PATH = Path.home() / ".cvi" / "config"

# Resolve `say` once at module load. The binary ships with macOS and the path
# is stable for the lifetime of the server process, so per-call PATH lookup
# would be wasted work.
_SAY_PATH = shutil.which("say")

_CONFIG_DEFAULTS: dict[str, str] = {
    "CVI_ENABLED": "on",
    "VOICE_LANG": "en",
    "SPEECH_RATE": "185",
    "VOICE_EN": "Zoe",
    "VOICE_JA": "Kyoko",
    "VOICE_MODE": "auto",
    "VOICE_FIXED": "",
    "AUTO_DETECT_LANG": "true",
}


def _load_config() -> dict[str, str]:
    """Read ~/.cvi/config shell-style KEY=VALUE lines. Missing file → defaults.

    A missing config is a first-run / fresh-machine condition, not a hard
    failure — CVI has no critical setting that requires an explicit value
    to be safe. We warn once to stderr so new users see the path that was
    checked and can run ``/cvi:setup`` if they expected a config file.
    """
    cfg = dict(_CONFIG_DEFAULTS)
    if not CVI_CONFIG_PATH.is_file():
        print(
            f"[cvi-voice] config not found at {CVI_CONFIG_PATH}; "
            "using defaults (CVI_ENABLED=on). Run /cvi:setup to generate one.",
            file=sys.stderr,
        )
        return cfg
    for raw in CVI_CONFIG_PATH.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        cfg[key.strip()] = value.strip().strip('"').strip("'")
    return cfg


def _detect_language(text: str) -> str:
    """Return 'ja' if the text contains any Japanese Unicode range, else 'en'.

    Ranges mirror ``speak-sync.sh`` (regex ``[ぁ-んァ-ヶー一-龠]``). Keep the two
    implementations synchronized — divergence would silently pick different
    voices for the same text across the MCP vs bash fallback paths.
    """
    for ch in text:
        o = ord(ch)
        # Hiragana, Katakana, CJK Unified Ideographs (see docstring above).
        if 0x3040 <= o <= 0x309F or 0x30A0 <= o <= 0x30FF or 0x4E00 <= o <= 0x9FFF:
            return "ja"
    return "en"


def _resolve_voice(cfg: dict[str, str], voice: str | None, lang: str) -> str | None:
    """Resolve the voice name to pass to `say`. `None` → system default (no -v flag)."""
    if voice:
        return None if voice == "system" else voice
    if cfg.get("VOICE_MODE") == "fixed" and cfg.get("VOICE_FIXED"):
        fixed = cfg["VOICE_FIXED"]
        return None if fixed == "system" else fixed
    selected = cfg.get("VOICE_JA" if lang == "ja" else "VOICE_EN", "")
    return None if selected in ("", "system") else selected


@mcp.tool()
def speak(text: str, voice: str | None = None, rate: int | None = None) -> str:
    """
    Speak `text` aloud via macOS `say`.

    Args:
        text: The string to speak. Empty string is an error.
        voice: Optional voice name (e.g. "Zoe", "Kyoko"). "system" = default voice.
            When None, the per-language voice from ~/.cvi/config is used.
        rate: Optional words-per-minute. When None, SPEECH_RATE from config.

    Returns:
        A human-readable confirmation line ("Speaking: ...") compatible with the
        existing hook contract used by plugins/cvi/commands/speak.md.
    """
    if not text.strip():
        raise ValueError("text must be non-empty")

    if _SAY_PATH is None:
        raise RuntimeError("`say` command not found — CVI requires macOS")

    cfg = _load_config()
    if cfg.get("CVI_ENABLED", "on") == "off":
        return "CVI is disabled. Enable with: /cvi:state on"

    detected_lang = _detect_language(text) if cfg.get("AUTO_DETECT_LANG", "true") == "true" else cfg.get("VOICE_LANG", "en")
    effective_rate = str(rate) if rate is not None else cfg.get("SPEECH_RATE", "185")
    effective_voice = _resolve_voice(cfg, voice, detected_lang)

    # Use the cached absolute path so the `_SAY_PATH is None` guard above
    # fully describes resolvability — avoids a second PATH lookup during
    # subprocess.run that could re-resolve under a changed environment.
    cmd: list[str] = [_SAY_PATH, "-r", effective_rate]
    if effective_voice:
        cmd.extend(["-v", effective_voice])
    cmd.append(text)

    # Fire and wait synchronously — callers expect voice to complete before
    # the hook chain continues (matches bash post-speak.sh semantics).
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(f"say exited with status {exc.returncode}") from exc

    return f"Speaking: {text}"


if __name__ == "__main__":
    # Transport defaults to stdio when invoked as a subprocess by Claude Code.
    mcp.run()
