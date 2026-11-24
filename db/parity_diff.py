#!/usr/bin/env python3
# One-off parity checker: canonical db/schema.rb vs a raw MySQL dump.
# Usage: python db/parity_diff.py <mysqldump.sql.txt> [db/schema.rb]
import re
import sys


def parse_schema_rb(path):
    text = open(path, encoding="utf-8").read()
    tables = {}
    table = None
    for line in text.splitlines():
        m = re.match(r'\s*create_table "([^"]+)"(.*?)\s+do\s+\|t\|', line)
        if m:
            table = {"options": (m.group(2) or "") + " " + line, "columns": {}}
            tables[m.group(1)] = table
            continue
        cm = re.match(r'\s*t\.(\w+) "([^"]+)"(.*)', line)
        em = re.match(r"\s*end\b", line)
        if cm and table is not None:
            table["columns"][cm.group(2)] = parse_rails_col(cm.group(1), cm.group(3))
        elif em:
            table = None
    return tables


def parse_rails_col(rtype, rest):
    row = {"type": None, "null": None, "default": None, "charset": None,
           "collation": None, "ai": False}

    def val(flag):
        m = re.search(rf'{flag}: ([^,]+)', rest)
        return m.group(1).strip() if m else None

    if rtype == "string":
        limit = val("limit")
        row["type"] = f"varchar({limit})" if limit else "varchar(255)"
    elif rtype == "text":
        row["type"] = {"medium": "mediumtext", "long": "longtext",
                       "tiny": "tinytext", "big": "bigtext"}.get(val("size"), "text")
    elif rtype == "integer":
        row["type"] = {"8": "tinyint", "16": "smallint",
                       "32": "int", "64": "bigint"}.get(val("limit"), "int")
    elif rtype == "bigint":
        row["type"] = "bigint"
    elif rtype == "decimal":
        row["type"] = f"decimal({val('precision') or '10'},{val('scale') or '0'})"
    elif rtype == "float":
        row["type"] = "float"
    elif rtype == "double":
        row["type"] = "double"
    elif rtype == "boolean":
        row["type"] = "tinyint(1)"
    elif rtype in ("date", "datetime", "timestamp", "time"):
        row["type"] = rtype
    else:
        row["type"] = rtype
    m = re.search(r'null: (true|false)', rest)
    if m:
        row["null"] = m.group(1) == "false"
    row["default"] = val("default")
    row["charset"] = val("charset")
    row["collation"] = val("collation")
    return row


def parse_sql_dump(path):
    text = open(path, encoding="utf-8").read()
    tables = {}
    for m in re.finditer(r"CREATE TABLE `([^`]+)` \(", text):
        name = m.group(1)
        depth = 1
        i = m.end()
        while i < len(text) and depth > 0:
            ch = text[i]
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            i += 1
        body = text[m.end():i - 1]
        sem = text.find(";", i)
        tail = text[i - 1:sem if sem != -1 else len(text)]
        charset = collation = None
        cm = re.search(r"DEFAULT CHARSET=(\w+)( COLLATE=([\w_]+))?", tail)
        if cm:
            charset, collation = cm.group(1), cm.group(3)
        t = {"options": tail, "columns": {},
             "charset": charset, "collation": collation}
        for line in body.splitlines():
            cm = re.match(r"`(\w+)` (.*?)(,)?\s*$", line.strip())
            if not cm:
                continue
            row = parse_sql_col(cm.group(2))
            row["charset"] = charset
            row["collation"] = collation
            t["columns"][cm.group(1)] = row
        tables[name] = t
    return tables


def parse_sql_col(spec):
    row = {"type": None, "null": None, "default": None,
           "charset": None, "collation": None, "ai": False}
    tm = re.match(r"(\w+(?:\([^)]*\))?)", spec)
    row["type"] = tm.group(1).lower() if tm else spec
    row["ai"] = "auto_increment" in spec.lower()
    row["null"] = "not null" in spec.lower()
    dm = re.search(r"DEFAULT (NULL|'[^']*'|\d+(?:\.\d+)?)", spec, re.I)
    if dm:
        row["default"] = dm.group(1)
    cm = re.search(r"COLLATE ([\w_]+)", spec)
    if cm:
        row["collation"] = cm.group(1)
    return row


def norm_type(t):
    if not t:
        return None
    t = t.lower().strip()
    if t.startswith("decimal("):
        return t
    t = re.sub(r"\(\d+(?:,\d+)?\)", "", t)
    t = t.replace("integer", "int")
    return t


def main():
    dump_path = sys.argv[1]
    schema_path = sys.argv[2] if len(sys.argv) > 2 else "db/schema.rb"
    canon = parse_schema_rb(schema_path)
    dump = parse_sql_dump(dump_path)

    print(f"canonical tables: {len(canon)}, dump tables: {len(dump)}\n")
    only_canon = sorted(set(canon) - set(dump))
    only_dump = sorted(set(dump) - set(canon))
    print("== Tables only in canonical schema.rb ==")
    print(", ".join(only_canon) or "(none)")
    print("\n== Tables only in dump ==")
    print(", ".join(only_dump) or "(none)")

    print("\n== Column differences (canonical vs dump) ==")
    diffs = 0
    only_diffs = 0
    for tname in sorted(set(canon) & set(dump)):
        cc, dc = canon[tname]["columns"], dump[tname]["columns"]
        for col in sorted(set(cc) | set(dc)):
            if col not in cc or col not in dc:
                print(f"{tname}.{col}: only in "
                      f"{'canonical' if col in cc else 'dump'}")
                only_diffs += 1
                continue
            a, b = cc[col], dc[col]
            issues = []
            if norm_type(a["type"]) != norm_type(b["type"]):
                issues.append(f"type {a['type']} vs {b['type']}")
            if a.get("null") != b.get("null") and not (
                    col == "id" and a.get("null") is None and b.get("null")):
                issues.append(f"null {a.get('null')} vs {b.get('null')}")
            ad, bd = a.get("default"), b.get("default")
            ad_n = None if ad in (None, "nil", "NULL", "null", "false") else ad
            bd_n = None if bd in (None, "NULL", "null") else bd
            if ad_n != bd_n:
                issues.append(f"default {ad!r} vs {bd!r}")
            if issues:
                diffs += 1
                print(f"{tname}.{col}: " + "; ".join(issues))
    print(f"\nTotal column diffs: {diffs} (plus {only_diffs} missing-column diffs)")

    print("\n== Table charset/collation differences ==")
    for tname in sorted(set(canon) & set(dump)):
        co, do = canon[tname]["options"], dump[tname]["options"]
        m1 = re.search(r'charset: "(\w+)"', co)
        m2 = re.search(r"CHARSET=(\w+)", do)
        c1 = m1.group(1) if m1 else None
        c2 = m2.group(1) if m2 else None
        cm1 = re.search(r'collation: "([\w_]+)"', co)
        cm2 = re.search(r"COLLATE=([\w_]+)", do)
        l1 = cm1.group(1) if cm1 else None
        l2 = cm2.group(1) if cm2 else None
        if c1 != c2 or l1 != l2:
            print(f"{tname}: {c1}/{l1} vs {c2}/{l2}")

    print("\n== PK id:integer overrides in canonical (must stay int) ==")
    for tname in sorted(canon):
        if "id: :integer" in canon[tname]["options"]:
            print(tname)


if __name__ == "__main__":
    main()

