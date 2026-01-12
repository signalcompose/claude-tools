#!/usr/bin/env python3
"""
YPM プロジェクトスキャンスクリプト

~/.ypm/config.ymlで指定された監視対象ディレクトリをスキャンし、
各プロジェクトのGit情報とドキュメント情報を収集してJSON形式で出力する。

使用方法:
    python scripts/scan_projects.py
    python scripts/scan_projects.py --config /path/to/config.yml

出力:
    JSON形式で標準出力に出力
"""

import os
import sys
import json
import yaml
import subprocess
from pathlib import Path
from datetime import datetime
import time
import glob
import argparse


def get_default_config_path():
    """デフォルトの設定ファイルパスを取得"""
    return Path.home() / ".ypm" / "config.yml"


def load_config(config_path=None):
    """config.ymlを読み込み"""
    if config_path is None:
        config_path = get_default_config_path()
    else:
        config_path = Path(config_path)

    if not config_path.exists():
        print(json.dumps({
            "error": f"config.yml not found at {config_path}",
            "hint": "Run /ypm:setup to initialize YPM"
        }), file=sys.stderr)
        sys.exit(1)

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        return config
    except Exception as e:
        print(json.dumps({"error": f"Failed to load config.yml: {e}"}), file=sys.stderr)
        sys.exit(1)


def find_projects(base_dirs, patterns, excludes):
    """
    パターンに基づいてGitリポジトリを検出

    Args:
        base_dirs: 監視対象ディレクトリのリスト
        patterns: プロジェクト検出パターンのリスト
        excludes: 除外パターンのリスト

    Returns:
        プロジェクトパスのリスト
    """
    projects = set()

    for base_dir in base_dirs:
        base_path = Path(base_dir).expanduser()

        if not base_path.exists():
            continue

        for pattern in patterns:
            # パターンに基づいてディレクトリを検索
            search_pattern = str(base_path / pattern)

            for path in glob.glob(search_pattern):
                path_obj = Path(path)

                # ディレクトリかつGitリポジトリか確認
                if path_obj.is_dir() and (path_obj / ".git").exists():
                    # 相対パスに変換
                    try:
                        rel_path = path_obj.relative_to(base_path)
                        rel_path_str = f"./{rel_path}"

                        # 除外パターンに該当するかチェック
                        excluded = False
                        for exclude in excludes:
                            if exclude in rel_path_str:
                                excluded = True
                                break

                        if not excluded:
                            projects.add(str(path_obj))
                    except ValueError:
                        # relative_toが失敗した場合は絶対パスを使用
                        projects.add(str(path_obj))

    return sorted(list(projects))


def run_git_command(project_path, command):
    """
    指定されたプロジェクトでGitコマンドを実行

    Args:
        project_path: プロジェクトパス
        command: Gitコマンド（リスト形式）

    Returns:
        コマンドの出力（文字列）、失敗時はNone
    """
    try:
        result = subprocess.run(
            command,
            cwd=project_path,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None
    except Exception:
        return None


def get_git_info(project_path):
    """
    プロジェクトのGit情報を取得

    Args:
        project_path: プロジェクトパス

    Returns:
        Git情報の辞書
    """
    info = {}

    # ブランチ名
    branch = run_git_command(project_path, ['git', 'rev-parse', '--abbrev-ref', 'HEAD'])
    info['branch'] = branch if branch else 'unknown'

    # 最終コミット（相対時刻とメッセージ）
    last_commit = run_git_command(project_path, ['git', 'log', '-1', '--format=%ar|%s'])
    info['last_commit'] = last_commit if last_commit else 'unknown'

    # 最終コミット日時（Unix timestamp: 分類用）
    last_commit_time = run_git_command(project_path, ['git', 'log', '-1', '--format=%ct'])
    if last_commit_time and last_commit_time.isdigit():
        info['last_commit_timestamp'] = int(last_commit_time)
    else:
        info['last_commit_timestamp'] = 0

    # 変更ファイル数
    status_output = run_git_command(project_path, ['git', 'status', '--short'])
    if status_output:
        info['changed_files'] = len(status_output.split('\n'))
    else:
        info['changed_files'] = 0

    return info


def is_worktree(project_path):
    """
    Git worktreeかどうかを判定

    .gitがファイル → worktree
    .gitがディレクトリ → 通常のリポジトリ

    Args:
        project_path: プロジェクトパス

    Returns:
        bool: worktreeの場合True
    """
    git_path = Path(project_path) / ".git"
    return git_path.is_file()


def run_trufflehog_scan(project_path):
    """
    TruffleHogでプロジェクトをスキャン

    Args:
        project_path: プロジェクトパス

    Returns:
        スキャン結果の辞書
    """
    result = {
        "scanned": False,
        "issues_found": 0,
        "has_secrets": False
    }

    # trufflehogコマンドの存在確認
    try:
        subprocess.run(
            ['which', 'trufflehog'],
            capture_output=True,
            check=True
        )
    except subprocess.CalledProcessError:
        # trufflehogがインストールされていない
        return result

    try:
        # trufflehogスキャン実行
        scan_result = subprocess.run(
            ['trufflehog', 'git', f'file://{project_path}', '--json', '--no-update'],
            capture_output=True,
            text=True,
            timeout=30  # 30秒タイムアウト
        )

        result["scanned"] = True

        # JSON形式の出力をパース
        if scan_result.stdout:
            lines = scan_result.stdout.strip().split('\n')
            issues_count = 0
            for line in lines:
                try:
                    issue = json.loads(line)
                    if issue:
                        issues_count += 1
                except json.JSONDecodeError:
                    continue

            result["issues_found"] = issues_count
            result["has_secrets"] = issues_count > 0

    except subprocess.TimeoutExpired:
        result["scanned"] = True
        result["timeout"] = True
    except Exception:
        # エラーが発生してもスキャンは続行
        pass

    return result


def read_project_docs(project_path):
    """
    プロジェクトのドキュメントを読み込み

    Args:
        project_path: プロジェクトパス

    Returns:
        ドキュメント情報の辞書（読み込めない場合は空辞書）
    """
    docs = {}
    doc_priority = ['CLAUDE.md', 'README.md', 'docs/INDEX.md']

    for doc_name in doc_priority:
        doc_path = Path(project_path) / doc_name
        if doc_path.exists():
            try:
                with open(doc_path, 'r', encoding='utf-8') as f:
                    content = f.read(2000)  # 最初の2000文字のみ読み込み

                    # 簡易的な情報抽出（今後改善可能）
                    if 'Phase' in content or 'phase' in content:
                        # Phaseを探す
                        for line in content.split('\n'):
                            if 'Phase' in line or 'phase' in line:
                                docs['phase_hint'] = line.strip()
                                break

                    # 概要を抽出（最初の数行）
                    lines = content.split('\n')
                    overview_lines = []
                    for line in lines[:10]:
                        if line.strip() and not line.startswith('#'):
                            overview_lines.append(line.strip())
                            if len(overview_lines) >= 3:
                                break

                    if overview_lines:
                        docs['overview'] = ' '.join(overview_lines)[:200]

                    break  # 最初に見つかったドキュメントを使用
            except Exception:
                continue

    return docs


def classify_project(last_commit_timestamp, active_days, inactive_days):
    """
    プロジェクトを分類

    Args:
        last_commit_timestamp: 最終コミット日時（Unix timestamp）
        active_days: アクティブ基準日数
        inactive_days: 休止中基準日数

    Returns:
        分類（"active", "developing", "dormant"）
    """
    if last_commit_timestamp == 0:
        return "unknown"

    now = time.time()
    days_ago = (now - last_commit_timestamp) / (24 * 3600)

    if days_ago <= active_days:
        return "active"
    elif days_ago <= inactive_days:
        return "developing"
    else:
        return "dormant"


def parse_args():
    """コマンドライン引数をパース"""
    parser = argparse.ArgumentParser(description='YPM Project Scanner')
    parser.add_argument(
        '--config', '-c',
        type=str,
        default=None,
        help='Path to config.yml (default: ~/.ypm/config.yml)'
    )
    return parser.parse_args()


def main():
    """メイン処理"""
    args = parse_args()

    # config.yml読み込み
    config = load_config(args.config)

    monitor_config = config.get('monitor', {})
    base_dirs = monitor_config.get('directories', [])
    patterns = monitor_config.get('patterns', ['*'])
    excludes = monitor_config.get('exclude', [])

    classification_config = config.get('classification', {})
    active_days = classification_config.get('active_days', 7)
    inactive_days = classification_config.get('inactive_days', 30)

    # プロジェクト検出
    project_paths = find_projects(base_dirs, patterns, excludes)

    # 各プロジェクトの情報を収集
    projects = []
    categories = {"active": 0, "developing": 0, "dormant": 0, "unknown": 0}

    for project_path in project_paths:
        project_name = Path(project_path).name

        # Git情報取得
        git_info = get_git_info(project_path)

        # 分類
        category = classify_project(
            git_info['last_commit_timestamp'],
            active_days,
            inactive_days
        )
        categories[category] += 1

        # ドキュメント情報取得（アクティブなプロジェクトのみ）
        docs = {}
        if category in ["active", "developing"]:
            docs = read_project_docs(project_path)

        # worktree判定
        is_wt = is_worktree(project_path)

        # TruffleHogセキュリティスキャン
        security_scan = run_trufflehog_scan(project_path)

        # プロジェクト情報を追加
        projects.append({
            "name": project_name,
            "path": project_path,
            "branch": git_info['branch'],
            "last_commit": git_info['last_commit'],
            "changed_files": git_info['changed_files'],
            "category": category,
            "is_worktree": is_wt,
            "docs": docs,
            "security_scan": security_scan
        })

    # 結果をJSON形式で出力
    result = {
        "projects": projects,
        "summary": {
            "total": len(projects),
            "active": categories["active"],
            "developing": categories["developing"],
            "dormant": categories["dormant"],
            "unknown": categories["unknown"]
        },
        "scan_time": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(json.dumps({"error": "Interrupted by user"}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": f"Unexpected error: {e}"}), file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
