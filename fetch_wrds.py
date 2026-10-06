"""Fetch the WRDS data the robot asked for. You run this, not the robot:

    python fetch_wrds.py

It reads each data/wrds-queries-NN.sql the robot wrote that hasn't been fetched yet, asks for your
WRDS username and password (typed here, never stored, never shown to the robot), and connects once:
approve the Duo push on your phone. Each result is saved as data/wrds/<name>.parquet. Row counts and
errors go to data/wrds/FETCH_LOG.md, which the robot reads when it restarts. Only single SELECT
statements are run, in read-only transactions.
"""
import datetime as dt
import getpass
import glob
import os
import re
import sys

try:
    import pandas as pd
    import psycopg2
    import psycopg2.extensions
except ImportError:
    sys.exit("Run this inside the course sandbox: it needs pandas, pyarrow and psycopg2.")

HOST, PORT, DBNAME = "wrds-pgdata.wharton.upenn.edu", 9737, "wrds"
MAX_ROWS = 10_000_000
CHUNK = 200_000
OUT = os.path.join("data", "wrds")
NAME_LINE = re.compile(r"^--\s*name:\s*([a-z0-9_]+)\s*$", re.IGNORECASE)

# NUMERIC columns arrive as floats rather than Python Decimals, so they save cleanly to parquet.
DEC2FLOAT = psycopg2.extensions.new_type(
    psycopg2.extensions.DECIMAL.values, "DEC2FLOAT",
    lambda value, cur: float(value) if value is not None else None)
psycopg2.extensions.register_type(DEC2FLOAT)


def marker(path):
    return os.path.join(OUT, ".fetched-" + os.path.splitext(os.path.basename(path))[0])


def pending_files():
    return [f for f in sorted(glob.glob(os.path.join("data", "wrds-queries-*.sql")))
            if not os.path.exists(marker(f))]


def parse(path):
    """Split a query file into (name, sql) pairs at the '-- name: x' lines."""
    queries, name, lines = [], None, []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = NAME_LINE.match(line.strip())
            if m:
                if name:
                    queries.append((name, "".join(lines)))
                name, lines = m.group(1).lower(), []
            elif name:
                lines.append(line)
    if name:
        queries.append((name, "".join(lines)))
    return queries


def single_select(sql):
    """The statement without comments or a trailing semicolon, or None unless it is one SELECT/WITH."""
    body = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    body = re.sub(r"--[^\n]*", "", body).strip().rstrip(";").strip()
    if ";" in body or not re.match(r"(?is)^(select|with)\b", body):
        return None
    return body


def fetch(conn, name, body):
    """Run one query through a server-side cursor; return (DataFrame, truncated)."""
    chunks, n, cols = [], 0, None
    with conn.cursor(name="fetch_" + name) as cur:
        cur.itersize = CHUNK
        cur.execute(f"SELECT * FROM ({body}) AS q LIMIT {MAX_ROWS + 1}")
        while True:
            part = cur.fetchmany(CHUNK)
            if cols is None:
                cols = [d[0] for d in cur.description]
            if not part:
                break
            chunks.append(pd.DataFrame(part, columns=cols))
            n += len(part)
    conn.rollback()
    df = pd.concat(chunks, ignore_index=True) if chunks else pd.DataFrame(columns=cols)
    return df.iloc[:MAX_ROWS], n > MAX_ROWS


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    files = pending_files()
    if not files:
        print("Nothing to fetch: the robot hasn't asked for WRDS data, or it already has all of it.")
        return
    print("The robot asked for:")
    for f in files:
        for name, _ in parse(f):
            print(f"  {os.path.basename(f)}: {name}")

    user = input("\nWRDS username: ").strip()
    password = getpass.getpass("WRDS password (not shown, not stored): ")
    print("Connecting. Approve the Duo push on your phone ...")
    try:
        conn = psycopg2.connect(host=HOST, port=PORT, dbname=DBNAME, user=user, password=password,
                                sslmode="require", connect_timeout=120)
    except psycopg2.Error as e:
        sys.exit(f"Couldn't connect: {str(e).strip()}")
    del password
    conn.set_session(readonly=True)

    os.makedirs(OUT, exist_ok=True)
    log_path = os.path.join(OUT, "FETCH_LOG.md")
    log = [] if os.path.exists(log_path) else ["# WRDS fetch log\n"]
    log.append(f"\n## Fetched {dt.datetime.now():%Y-%m-%d %H:%M}\n")
    for f in files:
        log.append(f"\n### {os.path.basename(f)}\n")
        queries = parse(f)
        if not queries:
            log.append("- No queries found. Each query must start with a line `-- name: short_name`.\n")
        for name, sql in queries:
            body = single_select(sql)
            if body is None:
                log.append(f"- `{name}`: not run. Only one SELECT (or WITH ... SELECT) statement is allowed.\n")
                print(f"  {name}: not run (not a single SELECT)")
                continue
            try:
                df, truncated = fetch(conn, name, body)
            except psycopg2.Error as e:
                conn.rollback()
                msg = (e.pgerror or str(e)).strip().splitlines()[0]
                log.append(f"- `{name}`: failed. {msg}\n")
                print(f"  {name}: failed")
                continue
            try:
                df.to_parquet(os.path.join(OUT, name + ".parquet"), index=False)
            except Exception as e:  # e.g. two columns with the same name
                log.append(f"- `{name}`: fetched but not saved ({type(e).__name__}: {e}). "
                           "Give every column a unique name.\n")
                print(f"  {name}: not saved")
                continue
            note = f" TRUNCATED at {MAX_ROWS:,} rows: narrow the query." if truncated else ""
            log.append(f"- `{name}`: {len(df):,} rows; columns: {', '.join(df.columns)}.{note}\n")
            print(f"  {name}: {len(df):,} rows")
        open(marker(f), "w").close()
    conn.close()
    with open(log_path, "a", encoding="utf-8") as fh:
        fh.writelines(log)
    print(f"\nDone; details in {log_path}. Now rerun the robot:  bash run-paper.sh")


if __name__ == "__main__":
    main()
