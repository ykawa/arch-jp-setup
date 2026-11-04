#!/usr/bin/env python3
"""Restore the dimensions of existing WezTerm development layouts."""

import argparse
import fcntl
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


QUIET = False


def cli(*args):
    return subprocess.check_output(
        ['wezterm', 'cli', '--no-auto-start', *args], text=True, timeout=10,
        stderr=subprocess.DEVNULL if QUIET else None,
    )


def identify(panes):
    width = max(p['left_col'] + p['size']['cols'] for p in panes)
    height = max(p['top_row'] + p['size']['rows'] for p in panes)
    if min(p['left_col'] for p in panes) or min(p['top_row'] for p in panes):
        raise ValueError('タブ全体のレイアウトを判別できません')
    if len(panes) == 3:
        if all(p['top_row'] == 0 and p['size']['rows'] == height for p in panes):
            return '3', sorted(panes, key=lambda p: p['left_col']), width, height
        main = [p for p in panes if p['left_col'] == 0 and p['size']['rows'] == height]
        if len(main) == 1:
            side = sorted((p for p in panes if p is not main[0]), key=lambda p: p['top_row'])
            if (side[0]['top_row'] == 0
                    and all(p['left_col'] == main[0]['size']['cols'] + 1 for p in side)
                    and side[1]['top_row'] == side[0]['size']['rows'] + 1):
                return 'dev', [main[0], *side], width, height
        main = [p for p in panes if p['top_row'] == 0 and p['size']['cols'] == width]
        if len(main) == 1:
            lower = sorted((p for p in panes if p is not main[0]), key=lambda p: p['left_col'])
            if (lower[0]['left_col'] == 0
                    and all(p['top_row'] == main[0]['size']['rows'] + 1 for p in lower)
                    and lower[1]['left_col'] == lower[0]['size']['cols'] + 1):
                return 'wide', [main[0], *lower], width, height
    if len(panes) == 4:
        columns = {}
        rows = {}
        for pane in panes:
            columns.setdefault(pane['left_col'], []).append(pane)
            rows.setdefault(pane['top_row'], []).append(pane)
        # Each column can have a different horizontal divider after resizing.
        if len(columns) == 2 and all(len(group) == 2 for group in columns.values()):
            left, right = [sorted(columns[x], key=lambda p: p['top_row']) for x in sorted(columns)]
            tl, bl = left
            tr, br = right
            if (tl['left_col'] == 0 and tl['top_row'] == tr['top_row'] == 0
                    and tr['left_col'] == tl['size']['cols'] + 1
                    and all(group[1]['top_row'] == group[0]['size']['rows'] + 1
                            and group[0]['size']['cols'] == group[1]['size']['cols']
                            for group in [left, right])):
                return 'grid', [tl, tr, bl, br], width, height
        # Also handle the equivalent grid built by splitting rows first.
        if len(rows) == 2 and all(len(group) == 2 for group in rows.values()):
            upper, lower = [sorted(rows[y], key=lambda p: p['left_col']) for y in sorted(rows)]
            tl, tr = upper
            bl, br = lower
            if (tl['top_row'] == 0 and tl['left_col'] == bl['left_col'] == 0
                    and bl['top_row'] == tl['size']['rows'] + 1
                    and all(group[1]['left_col'] == group[0]['size']['cols'] + 1
                            and group[0]['size']['rows'] == group[1]['size']['rows']
                            for group in [upper, lower])):
                return 'grid', [tl, tr, bl, br], width, height
    raise ValueError('対応レイアウトは横3列・wezdev・wezwide・wezgridです')


def plan(mode, panes, width, height):
    ids = [p['pane_id'] for p in panes]
    if mode == '3':
        a = (width - 2) // 3
        b = (width - 2 - a) // 2
        c = width - 2 - a - b
        expected = [(a, height), (b, height), (c, height)]
        # Outer panes work with either A|(B|C) or (A|B)|C split trees.
        operations = [(ids[0], 'cols', a, False), (ids[2], 'cols', c, True)]
    elif mode == 'dev':
        a = (width - 1) * 65 // 100
        b = width - 1 - a
        top = (height - 1) // 2
        expected = [(a, height), (b, top), (b, height - 1 - top)]
        operations = [(ids[0], 'cols', a, False), (ids[1], 'rows', top, False)]
    elif mode == 'wide':
        top = (height - 1) * 75 // 100
        lower = height - 1 - top
        left = (width - 1) // 2
        expected = [(width, top), (left, lower), (width - 1 - left, lower)]
        operations = [(ids[0], 'rows', top, False), (ids[1], 'cols', left, False)]
    else:
        left, top = (width - 1) // 2, (height - 1) // 2
        right, bottom = width - 1 - left, height - 1 - top
        expected = [(left, top), (right, top), (left, bottom), (right, bottom)]
        operations = [
            (ids[0], 'cols', left, False), (ids[2], 'cols', left, False),
            (ids[0], 'rows', top, False), (ids[1], 'rows', top, False),
        ]
    if any(min(size) < 1 for size in expected):
        raise ValueError('再調整するにはタブの幅・高さが足りません')
    return dict(zip(ids, expected)), operations


def fit_tab(panes, layout='auto', quiet=False):
    if any(p.get('is_zoomed') for p in panes):
        raise ValueError('ペインのズームを解除してから実行してください')
    mode, ordered, width, height = identify(panes)
    if layout != 'auto' and layout != mode:
        raise ValueError(f'現在の配置は {mode} です。指定した配置へは作り替えません')
    tab_id = panes[0]['tab_id']
    expected, operations = plan(mode, ordered, width, height)

    def snapshot():
        result = {p['pane_id']: p for p in json.loads(cli('list', '--format', 'json'))
                  if p['tab_id'] == tab_id and not p.get('is_floating')}
        if result.keys() != expected.keys():
            raise ValueError('調整中にペイン構成が変わりました。もう一度実行してください')
        return result

    def complete(state):
        return all((state[pid]['size']['cols'], state[pid]['size']['rows']) == size
                   for pid, size in expected.items())

    # Refresh after each change because ancestor splits can resize neighbours.
    for _ in range(4):
        if complete(snapshot()):
            if not quiet:
                print(f'wezfit: {mode} を現在のサイズ（{width}×{height}）に再調整しました')
            return
        for pid, axis, target, second in operations:
            delta = target - snapshot()[pid]['size'][axis]
            if not delta:
                continue
            negative, positive = ('Left', 'Right') if axis == 'cols' else ('Up', 'Down')
            direction = positive if (delta > 0) != second else negative
            cli('adjust-pane-size', '--pane-id', str(pid), '--amount', str(abs(delta)), direction)
    if not complete(snapshot()):
        raise ValueError('再調整を完了できませんでした。ズームやウィンドウサイズ変更を止めて再実行してください')
    if not quiet:
        print(f'wezfit: {mode} を現在のサイズ（{width}×{height}）に再調整しました')


def main():
    global QUIET
    parser = argparse.ArgumentParser(description='既存ペインを現在のタブサイズに合わせて再調整します')
    parser.add_argument('layout', nargs='?', default='auto', choices=['auto', '3', 'dev', 'wide', 'grid'])
    parser.add_argument('--window-id', type=int, help='指定ウィンドウ内の対応タブをすべて調整')
    parser.add_argument('--quiet', action='store_true', help='自動調整用。結果表示を抑制')
    args = parser.parse_args()
    QUIET = args.quiet

    # Serialize resize handlers so that successive window events cannot fight.
    endpoint = os.environ.get('WEZTERM_UNIX_SOCKET', 'default')
    key = hashlib.sha256(endpoint.encode()).hexdigest()[:24]
    lock_dir = Path(os.environ.get('XDG_RUNTIME_DIR', tempfile.gettempdir())) / f'wezterm-layouts-{os.getuid()}'
    lock_dir.mkdir(mode=0o700, exist_ok=True)
    with (lock_dir / f'{key}.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if lock.tell() == 0:
            lock.write('\n')
            lock.flush()
        all_panes = json.loads(cli('list', '--format', 'json'))
        if args.window_id is not None:
            tabs = {}
            for pane in all_panes:
                if pane['window_id'] == args.window_id and not pane.get('is_floating'):
                    tabs.setdefault(pane['tab_id'], []).append(pane)
            for panes in tabs.values():
                try:
                    fit_tab(panes, args.layout, quiet=args.quiet)
                except ValueError:
                    # Unsupported layouts, zoomed tabs, and concurrent changes
                    # are intentionally ignored by automatic window fitting.
                    continue
            return

        pane_id = os.environ.get('WEZTERM_PANE')
        if not pane_id:
            raise ValueError('WezTermの通常ペイン内で実行してください')
        current = next((p for p in all_panes if str(p['pane_id']) == pane_id), None)
        if not current or current.get('is_floating'):
            raise ValueError('実行元の通常ペインが見つかりません')
        panes = [p for p in all_panes if p['tab_id'] == current['tab_id'] and not p.get('is_floating')]
        fit_tab(panes, args.layout, quiet=args.quiet)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, subprocess.SubprocessError, OSError) as error:
        if not QUIET:
            print(f'wezfit: {error}', file=sys.stderr)
        sys.exit(1)
