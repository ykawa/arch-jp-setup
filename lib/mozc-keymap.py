#!/usr/bin/env python3
"""キーマップ（TSV）と Mozc の config1.db を相互変換する。

    python3 -I mozc-keymap.py import <キーマップ> <config1.db> [--if-unset] [番号=値 ...]
    python3 -I mozc-keymap.py export <config1.db> <キーマップ>

Mozc はカスタムキーマップを config1.db（protobuf）の custom_keymap_table に持つ。
    session_keymap = 41（CUSTOM = 0） / custom_keymap_table = 42（bytes）

import はこの 2 つだけを書き換え、既存の config1.db のほかの設定は残す（変更するときは .backup.<日時> に退避）。
--if-unset    … カスタムキーマップが設定済みなら何もしない
番号=値       … そのフィールド（整数）が無いときだけ書く（例: 110=5 は候補の数）
"""

import os
import shutil
import sys
import time

SESSION_KEYMAP, CUSTOM_KEYMAP_TABLE = 41, 42
CUSTOM = 0
VARINT, FIXED64, LEN, FIXED32 = 0, 1, 2, 5


def read_varint(buf, i):
    result = shift = 0
    while True:
        byte = buf[i]
        i += 1
        result |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            return result, i


def varint(value):
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def parse(buf):
    """[(フィールド番号, 値, 元のバイト列)]。読めないデータなら中止する"""
    fields, i = [], 0
    try:
        while i < len(buf):
            start = i
            key, i = read_varint(buf, i)
            wire = key & 7
            value = None
            if wire == VARINT:
                value, i = read_varint(buf, i)
            elif wire == LEN:
                length, i = read_varint(buf, i)
                value = buf[i:i + length]
                i += length
            elif wire in (FIXED64, FIXED32):
                i += 8 if wire == FIXED64 else 4
            else:
                raise ValueError(f"wire type {wire}")
            if i > len(buf):
                raise IndexError("途中で終わっています")
            fields.append((key >> 3, value, buf[start:i]))
    except (IndexError, ValueError) as e:
        sys.exit(f"error: config1.db を読めません: {e}")
    return fields


def read_fields(path):
    if not os.path.exists(path):
        return []
    with open(path, "rb") as f:
        return parse(f.read())


def last_value(fields, number):
    value = None
    for n, v, _ in fields:
        if n == number:
            value = v
    return value


def check_keymap(keymap):
    lines = keymap.split(b"\n")
    if lines[0].split(b"\t") != [b"status", b"key", b"command"]:
        sys.exit("error: キーマップの 1 行目が status, key, command ではありません")
    for lineno, line in enumerate(lines[1:], 2):
        if not line or line.startswith(b"#"):
            continue
        columns = line.split(b"\t")
        if len(columns) != 3 or b"" in columns:
            sys.exit(f"error: キーマップの {lineno} 行目が status, key, command の 3 列ではありません")


def import_keymap(keymap_path, db_path, args):
    if_unset = "--if-unset" in args
    defaults = [tuple(map(int, a.split("="))) for a in args if a != "--if-unset"]

    with open(keymap_path, "rb") as f:
        keymap = f.read()
    if not keymap.endswith(b"\n"):
        keymap += b"\n"
    check_keymap(keymap)

    fields = read_fields(db_path)
    current = last_value(fields, CUSTOM_KEYMAP_TABLE)
    is_custom = last_value(fields, SESSION_KEYMAP) == CUSTOM and bool(current)
    missing = [(n, v) for n, v in defaults if last_value(fields, n) is None]
    if is_custom and (if_unset or (current == keymap and not missing and not os.path.islink(db_path))):
        print(f"unchanged: {db_path}")
        return

    message = b"".join(raw for n, _, raw in fields if n not in (SESSION_KEYMAP, CUSTOM_KEYMAP_TABLE))
    message += varint(SESSION_KEYMAP << 3 | VARINT) + varint(CUSTOM)
    message += varint(CUSTOM_KEYMAP_TABLE << 3 | LEN) + varint(len(keymap)) + keymap
    for number, value in missing:
        message += varint(number << 3 | VARINT) + varint(value)

    os.makedirs(os.path.dirname(os.path.abspath(db_path)), mode=0o700, exist_ok=True)
    if os.path.exists(db_path):
        shutil.copy2(db_path, f"{db_path}.backup.{time.strftime('%Y%m%d-%H%M%S')}")
    tmp = db_path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(message)
    os.chmod(tmp, 0o600)
    os.replace(tmp, db_path)
    print(f"imported keymap → {db_path}")


def export_keymap(db_path, keymap_path):
    fields = read_fields(db_path)
    keymap = last_value(fields, CUSTOM_KEYMAP_TABLE)
    if last_value(fields, SESSION_KEYMAP) != CUSTOM or not keymap:
        sys.exit(f"error: カスタムキーマップがありません: {db_path}")
    if not keymap.endswith(b"\n"):
        keymap += b"\n"
    check_keymap(keymap)
    with open(keymap_path, "wb") as f:
        f.write(keymap)
    print(f"exported keymap → {keymap_path}")


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == "import":
        import_keymap(sys.argv[2], sys.argv[3], sys.argv[4:])
    elif len(sys.argv) == 4 and sys.argv[1] == "export":
        export_keymap(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
