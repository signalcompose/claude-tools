#!/bin/bash

# ユーザーが新しい指示を入力した時に実行される
# 現在再生中の全ての音声を即座に停止する

# 全てのafplayプロセスを停止
killall afplay 2>/dev/null

# 一時音声ファイルもクリーンアップ
rm -f /tmp/claude_notify_*.aiff 2>/dev/null
rm -f /tmp/claude_input_*.aiff 2>/dev/null
