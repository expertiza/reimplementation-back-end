#!/usr/bin/env python3
# One-off generator: emits MySQL DDL/data SQL that converges the
# legacy-migrated database to the canonical db/schema.rb definition.
#
# Usage:
#   1) mysqldump --no-data reimplementation_development > /tmp/live.sql
#   2) python db/gen_convergence.py /tmp/live.sql > db/legacy_convergence.sql
import re
import sys

CANONICAL = "db/schema.rb"


def parse_schema_rb(path):
    text = open(path, encoding="utf-8").read()
    tables = {}
    cur = None
    for line in text.splitlines():
        m = re.match(r'\s*create_table "([^"]+)"(.*?)\s+do\s+\|t\|', line)
        if m:
            cur = {"options": m.group(2) or "", "columns": {}, "fks": []}
            idm = re.search(r"id: :(\w+)", m.group(2) or "")
            cur["id"] = idm.group(1) if idm else "bigint"
            tables[m.group(1)] = cur
            if "id" not in cur["columns"]:
                cur["columns"]["id"] = {"sql": "bigint" if cur["id"] == "bigint"
                                       else "integer",
                                       "null": False, "raw_default": None,
                                       "char": None, "_synthetic": True}
            continue
        cm = re.match(r'\s*t\.(\w+) "([^"]+)"(.*)', line)
        em = re.match(r"\s*end\b", line)
        if cm and cur is not None:
            cur["columns"][cm.group(2)] = parse_rails_col(cm.group(1), cm.group(3))
        elif em:
            cur = None
        fm = re.match(r'\s*add_foreign_key "([^"]+)"(?:, "([^"]+)"(.*))?', line)
        if fm:
            t, ref, rest = fm.group(1), fm.group(2), fm.group(3) or ""
            colm = re.search(r'column: "([^"]+)"', rest)
            odm = re.search(r'on_delete: :(\w+)', rest)
            if t in tables:
                tables[t]["fks"].append({
                    "table": t, "to": ref,
                    "column": colm.group(1) if colm else None,
                    "on_delete": odm.group(1) if odm else None})
    return tables


def rails_sql_type(rtype, rest):
    def val(flag):
        m = re.search(rf'{flag}: ([^,]+)', rest)
        return m.group(1).strip() if m else None
    if rtype == "string":
        return f"varchar({val('limit') or '255'})"
    if rtype == "text":
        return {"medium": "MEDIUMTEXT", "long": "LONGTEXT",
                "tiny": "TINYTEXT", "big": "BIGTEXT"}.get(val("size"), "TEXT")
    if rtype == "integer":
        return {"8": "TINYINT", "16": "SMALLINT",
                "32": "INT", "64": "BIGINT"}.get(val("limit"), "INT")
    if rtype == "bigint":
        return "BIGINT"
    if rtype == "decimal":
        return f"DECIMAL({val('precision') or '10'},{val('scale') or '0'})"
    if rtype == "boolean":
        return "TINYINT(1)"
    if rtype in ("float", "double", "date", "datetime", "timestamp",
                 "time", "binary"):
        return rtype.upper()
    return rtype.upper()


def parse_rails_col(rtype, rest):
    c = {"sql": rails_sql_type(rtype, rest), "null": None, "default": None,
         "raw_default": None, "char": None}
    m = re.search(r'null: (true|false)', rest)
    if m:
        c["null"] = m.group(1) == "false"
    dm = re.search(r'default: ([^,]+)', rest)
    if dm:
        c["raw_default"] = dm.group(1).strip()
    cm = re.search(r'collation: "([\w_]+)"', rest)
    if cm:
        c["char"] = cm.group(1)
    return c


def parse_sql_dump(path):
    text = open(path, encoding="utf-8").read()
    tables = {}
    for m in re.finditer(r"CREATE TABLE `([^`]+)` \(", text):
        name = m.group(1)
        depth, i = 1, m.end()
        while i < len(text) and depth > 0:
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
            i += 1
        body = text[m.end():i - 1]
        sem = text.find(";", i)
        tail = text[i - 1:sem if sem != -1 else len(text)]
        t = {"columns": {}, "fks": [], "id": None, "charset": None,
             "collation": None, "is_view": False}
        cm = re.search(r"DEFAULT CHARSET=(\w+)( COLLATE=([\w_]+))?", tail)
        if cm:
            t["charset"], t["collation"] = cm.group(1), cm.group(3)
        for line in body.splitlines():
            line = line.strip()
            cfm = re.match(r"`([^`]+)` ([a-zA-Z]+)(\([^)]*\))?(.*)", line)
            if cfm:
                c = {"sql": (cfm.group(2) or "") + (cfm.group(4) or ""),
                     "null": "not null" in line.lower(),
                     "default": None, "ai": "auto_increment" in line.lower(),
                     "char": t["charset"], "collation": t["collation"]}
                dm = re.search(
                    r"DEFAULT (NULL|'[^']*'|\d+(?:\.\d+)?)", line, re.I)
                if dm:
                    c["default"] = (None if dm.group(1).upper() == "NULL"
                                    else dm.group(1))
                t["columns"][cfm.group(1)] = c
                continue
            kfm = re.match(
                r"CONSTRAINT `([^`]+)` FOREIGN KEY \(`(\w+)`\) "
                r"REFERENCES `(\w+)`(?:\(`(\w+)`\))?(?: ON DELETE (\w+))?",
                line)
            if kfm:
                t["fks"].append({"name": kfm.group(1), "column": kfm.group(2),
                                 "to": kfm.group(3), "ref": kfm.group(4),
                                 "on_delete": kfm.group(5)})
                continue
            kfm2 = re.match(
                r"FOREIGN KEY \(`(\w+)`\) REFERENCES `(\w+)`(?:\(`(\w+)`\))?",
                line)
            if kfm2:
                t["fks"].append({"name": None, "column": kfm2.group(1),
                                 "to": kfm2.group(2), "ref": kfm2.group(3),
                                 "on_delete": None})
            pm = re.match(r"PRIMARY KEY \(`(\w+)`\)", line)
            if pm:
                t["id"] = pm.group(1)
        tables[name] = t
    for m in re.finditer(
            r"CREATE (?:ALGORITHM=\S+ )?(?:SQL SECURITY \w+ )?VIEW `([^`]+)`",
            text):
        tables[m.group(1)] = {"columns": {}, "fks": [], "id": None,
                              "charset": None, "collation": None,
                              "is_view": True}
    return tables


def norm_type(sql):
    if not sql:
        return None
    s = sql.lower().strip()
    if s.startswith("decimal("):
        return s
    s = re.sub(r"\(\d+(?:,\d+)?\)", "", s)
    s = s.replace("integer", "int").replace("bool", "tinyint")
    return s


def canon_decl(name, c, is_id=False, cur=None):
    if is_id:
        return f"`{name}` {c['sql'].upper()} NOT NULL AUTO_INCREMENT"
    null = "NOT NULL" if c.get("null") is False else "NULL"
    d = c.get("raw_default")
    ds = ""
    if d and d != "nil":
        if d == "true":
            ds = " DEFAULT 1"
        elif d == "false":
            ds = " DEFAULT 0"
        elif re.match(r"^-?\d+$", d):
            ds = f" DEFAULT {d}"
        elif d.startswith("'") and d.endswith("'"):
            ds = f" DEFAULT {d}"
    return f"`{name}` {c['sql']} {null}{ds}"


def canon_default_key(c):
    d = c.get("raw_default")
    if d is None or d == "nil":
        return None
    if d == "true":
        return "1"
    if d == "false":
        return "0"
    if d.startswith("'") and d.endswith("'"):
        return d.strip("'")
    return d


def live_default_key(c):
    d = c.get("default")
    if d is None:
        return None
    d = d.strip()
    if d.startswith("'") and d.endswith("'"):
        return d.strip("'")
    return d


def main():
    live = parse_sql_dump(sys.argv[1])
    canon = parse_schema_rb(CANONICAL)
    out = ["SET FOREIGN_KEY_CHECKS = 0;"]

    keep = {"schema_migrations", "ar_internal_metadata", "score_views"}
    only_live = sorted(set(live) - set(canon) - keep)
    for t in only_live:
        kind = "VIEW" if live[t]["is_view"] else "TABLE"
        out.append(f"DROP {kind} IF EXISTS `{t}`;")

    for t in sorted(set(canon) - set(live)):
        ct = canon[t]
        cols = [canon_decl("id", ct["columns"]["id"], True, {})]
        for n, c in ct["columns"].items():
            if n != "id":
                cols.append(canon_decl(n, c))
        # An AUTO_INCREMENT column must be a key; always declare the PK
        # explicitly (MySQL has no implicit PK, so omitting it for integer
        # ids raises "there can be only one auto column and it must be a key").
        cols.append("PRIMARY KEY (`id`)")
        out.append(f"CREATE TABLE IF NOT EXISTS `{t}` (\n"
                   + ",\n".join(cols) + "\n) "
                   "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 "
                   "COLLATE=utf8mb4_general_ci;")

    common = [t for t in sorted(set(canon) & set(live))
              if not live[t]["is_view"]]

    for t in common:
        for fk in live[t]["fks"]:
            name = fk["name"] or f"fk_{t}_{fk['column']}"
            out.append(f"ALTER TABLE `{t}` DROP FOREIGN KEY `{name}`;")

    for t in common:
        ct, lt = canon[t], live[t]
        mods = []
        idname = lt.get("id") or "id"
        cid = ct["columns"].get("id")
        if cid:
            cur = lt["columns"].get(idname)
            want = norm_type(cid["sql"])
            have = norm_type((cur or {}).get("sql"))
            if want and have and want != have:
                mods.append("MODIFY COLUMN "
                            f"{canon_decl(idname, cid, True, cur)}")
        for col in sorted(set(ct["columns"]) | set(lt["columns"])):
            if col == idname or col == ct["id"]:
                continue
            cc, lc = ct["columns"].get(col), lt["columns"].get(col)
            if cc and not lc:
                mods.append(f"ADD COLUMN {canon_decl(col, cc)}")
            elif lc and not cc:
                mods.append(f"DROP COLUMN `{col}`")
            else:
                want = norm_type(cc["sql"])
                have = norm_type(lc["sql"])
                wnull = cc.get("null") is False
                hnull = lc.get("null") is False
                if (want != have or wnull != hnull
                        or canon_default_key(cc) != live_default_key(lc)):
                    mods.append(
                        f"MODIFY COLUMN {canon_decl(col, cc, cur=lc)}")
        if mods:
            out.append(f"ALTER TABLE `{t}`\n" + ",\n".join(mods) + ";")

    for t in common:
        ct, lt = canon[t], live[t]
        opts = ct.get("options", "")
        m1 = re.search(r'charset: "(\w+)"', opts)
        m2 = re.search(r'collation: "([\w_]+)"', opts)
        c1 = m1.group(1) if m1 else "utf8mb4"
        l1 = m2.group(1) if m2 else f"{c1}_0900_ai_ci"
        c2 = lt.get("charset") or "utf8mb4"
        l2 = lt.get("collation") or f"{c2}_0900_ai_ci"
        if c1.lower() != c2.lower() or l1.lower() != l2.lower():
            out.append(f"ALTER TABLE `{t}` CONVERT TO CHARACTER SET "
                       f"{c1} COLLATE {l1};")

    if "signed_up_teams" in live and not live["signed_up_teams"]["is_view"]:
        out.append("UPDATE `signed_up_teams` SET project_topic_id = NULL "
                   "WHERE project_topic_id = 0;")
        out.append("UPDATE `signed_up_teams` SET team_id = NULL "
                   "WHERE team_id = 0;")
    for t in ("questionnaires", "questionnaire_types"):
        if t in live and not live[t]["is_view"]:
            cols = live[t]["columns"]
            if "min_question_score" in cols:
                out.append(f"UPDATE `{t}` SET min_question_score = 0 "
                           "WHERE min_question_score IS NOT NULL "
                           "AND min_question_score < 0;")
            if "max_question_score" in cols:
                out.append(f"UPDATE `{t}` SET max_question_score = 0 "
                           "WHERE max_question_score IS NOT NULL "
                           "AND max_question_score < 0;")

    seen = set()
    for t in common:
        for fk in canon[t]["fks"]:
            if (fk["table"], fk["to"], fk["column"]) in seen:
                continue
            seen.add((fk["table"], fk["to"], fk["column"]))
            col = fk["column"] or fk["to"].rstrip("s") + "_id"
            if col not in live[t]["columns"]:
                continue
            od = (f" ON DELETE {fk['on_delete'].upper()}"
                  if fk.get("on_delete") else "")
            out.append(f"ALTER TABLE `{t}` "
                       f"ADD CONSTRAINT `fk_canon_{t}_{col}` "
                       f"FOREIGN KEY (`{col}`) "
                       f"REFERENCES `{fk['to']}` (`id`){od};")

    # Re-assert the canonical score_views view. The legacy score_views
    # references the pre-bridge table name (questions); after the bridge and
    # this convergence the quiz table is `items`, so the legacy view is stale.
    # 20261101000003 is guarded out on a legacy source, so the convergence
    # re-creates the canonical definition itself to be self-contained.
    out.append("DROP VIEW IF EXISTS `score_views`;")
    out.append(
        "CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW "
        "`score_views` AS\n"
        "SELECT ques.`weight` AS `question_weight`,\n"
        "       ques.`type` AS `type`,\n"
        "       q1.`id` AS `q1_id`,\n"
        "       q1.`name` AS `q1_name`,\n"
        "       q1.`instructor_id` AS `q1_instructor_id`,\n"
        "       q1.`private` AS `q1_private`,\n"
        "       q1.`min_question_score` AS `q1_min_question_score`,\n"
        "       q1.`max_question_score` AS `q1_max_question_score`,\n"
        "       q1.`created_at` AS `q1_created_at`,\n"
        "       q1.`updated_at` AS `q1_updated_at`,\n"
        "       q1.`type` AS `q1_type`,\n"
        "       q1.`display_type` AS `q1_display_type`,\n"
        "       ques.`id` AS `ques_id`,\n"
        "       ques.`questionnaire_id` AS `ques_questionnaire_id`,\n"
        "       s.`id` AS `s_id`,\n"
        "       s.`item_id` AS `s_question_id`,\n"
        "       s.`answer` AS `s_score`,\n"
        "       s.`comments` AS `s_comments`,\n"
        "       s.`response_id` AS `s_response_id`\n"
        "FROM ((`items` `ques` LEFT JOIN `questionnaires` `q1` "
        "ON ((`ques`.`questionnaire_id` = `q1`.`id`)))\n"
        "      LEFT JOIN `answers` `s` ON ((`ques`.`id` = `s`.`item_id`)));\n")

    out.append("SET FOREIGN_KEY_CHECKS = 1;")
    print("\n".join(out))
    print(f"-- generated: drops={len(only_live)} creates="
          f"{len(set(canon) - set(live))} tables_touched="
          f"{len(common)} fks={len(seen)}", file=sys.stderr)


if __name__ == "__main__":
    main()