"""Compare the LOCAL database with the ONLINE database.
Prints ALTER TABLE lines for every column that exists locally but not online.

Run in PowerShell, in the backend folder (with the .venv active):

    $env:LOCAL_URL='postgresql://USER:PASSWORD@localhost:5432/Attendface'
    $env:ONLINE_URL='postgresql://USER:PASSWORD@db.swyftstack.com:6432/DBNAME?sslmode=require'
    python compare_schema.py

It only READS both databases. It changes nothing.
Passwords are never printed.
"""
import os
import sys

import psycopg2

local_url = os.environ.get("LOCAL_URL")
online_url = os.environ.get("ONLINE_URL")
if not local_url or not online_url:
    sys.exit("Set LOCAL_URL and ONLINE_URL first (see the top of this file).")

# One simple query. Works through connection poolers too.
QUERY = """
SELECT c.relname, a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod)
FROM pg_catalog.pg_attribute a
JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
  AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY c.relname, a.attnum
"""


def read_columns(url, label):
    try:
        conn = psycopg2.connect(url, connect_timeout=30)
    except Exception as e:
        sys.exit(f"Cannot connect to the {label} database: {type(e).__name__}")
    try:
        cur = conn.cursor()
        cur.execute(QUERY)
        result = {}
        for table, column, coltype in cur.fetchall():
            result.setdefault(table, {})[column] = coltype
        return result
    finally:
        conn.close()


local = read_columns(local_url, "LOCAL")
online = read_columns(online_url, "ONLINE")

problems = []
lines = []
for table in sorted(local):
    if table == "alembic_version":
        continue
    if table not in online:
        problems.append(f"TABLE MISSING online: {table}")
        continue
    for column, coltype in local[table].items():
        if column not in online[table]:
            # Added as nullable on purpose: safest for a quick sync.
            lines.append(f'ALTER TABLE "{table}" ADD COLUMN "{column}" {coltype};')

print("---- Problems ----")
print("\n".join(problems) if problems else "none")
print()
print("---- Run these online (one by one, or paste all) ----")
print("\n".join(lines) if lines else "no missing columns")