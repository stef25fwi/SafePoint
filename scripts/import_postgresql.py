#!/usr/bin/env python3
"""
SafePoint V1 → V2 Migration
Step 3: Import CSV files into PostgreSQL (Cloud Temple).

Usage:
    DB_URL=postgresql://user:pass@host:5432/safepoint \
    python import_postgresql.py --input ./sql_import

Requirements:
    pip install psycopg2-binary
"""

import argparse
import csv
import os
import sys

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print('ERROR: psycopg2 not installed. Run: pip install psycopg2-binary')
    sys.exit(1)

DB_URL = os.environ.get('DB_URL')

TABLE_ORDER = [
    'organizations',
    'users',
    'refuges',
    'crisis_events',
    'families',
    'persons',
    'checkins',
    'transfers',
    'alerts',
    'needs',
    'audit_logs',
]


def import_table(conn, table, csv_path):
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    if not rows:
        print(f'[SKIP] {table}: empty')
        return
    columns = rows[0].keys()
    col_str = ', '.join(f'"{c}"' for c in columns)
    values = [tuple(r[c] if r[c] != '' else None for c in columns) for r in rows]
    sql = f'INSERT INTO {table} ({col_str}) VALUES %s ON CONFLICT (id) DO NOTHING'
    with conn.cursor() as cur:
        execute_values(cur, sql, values)
    conn.commit()
    print(f'[OK] {table}: {len(rows)} rows imported')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default='./sql_import')
    args = parser.parse_args()

    if not DB_URL:
        print('ERROR: DB_URL environment variable is required')
        sys.exit(1)

    conn = psycopg2.connect(DB_URL)
    print(f'Connected to PostgreSQL')

    for table in TABLE_ORDER:
        csv_path = os.path.join(args.input, f'{table}.csv')
        if not os.path.exists(csv_path):
            print(f'[SKIP] {csv_path} not found')
            continue
        import_table(conn, table, csv_path)

    conn.close()
    print('\nImport complete.')


if __name__ == '__main__':
    main()
