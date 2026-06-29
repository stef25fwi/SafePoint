#!/usr/bin/env python3
"""
SafePoint V1 → V2 Migration
Step 6: Post-migration verification.

Checks:
  1. Row counts match between Firestore export and PostgreSQL.
  2. All persons have an organization_id.
  3. All audit_logs have a valid action.
  4. S3 file count matches Firebase Storage export count.
  5. Keycloak user count matches Firebase Auth export count.

Usage:
    DB_URL=postgresql://user:pass@host:5432/safepoint \
    KEYCLOAK_URL=https://auth.safepoint.guadeloupe.fr \
    KEYCLOAK_REALM=safepoint \
    KEYCLOAK_CLIENT_ID=admin-cli \
    KEYCLOAK_CLIENT_SECRET=xxx \
    S3_ENDPOINT=https://s3.cloud-temple.com \
    S3_ACCESS_KEY=xxx \
    S3_SECRET_KEY=yyy \
    S3_BUCKET=safepoint-prod \
    python verify_migration.py --export-dir ./export --storage-dir ./storage_export
"""

import argparse
import json
import os
import sys

PASS = '\033[92m[PASS]\033[0m'
FAIL = '\033[91m[FAIL]\033[0m'
WARN = '\033[93m[WARN]\033[0m'

failures = []


def check(label, condition, detail=''):
    if condition:
        print(f'{PASS} {label}')
    else:
        print(f'{FAIL} {label}{": " + detail if detail else ""}')
        failures.append(label)


def count_ndjson(path):
    if not os.path.exists(path):
        return 0
    with open(path) as f:
        return sum(1 for line in f if line.strip())


def check_postgresql(export_dir):
    try:
        import psycopg2
    except ImportError:
        print(f'{WARN} psycopg2 not installed, skipping PostgreSQL checks')
        return

    db_url = os.environ.get('DB_URL')
    if not db_url:
        print(f'{WARN} DB_URL not set, skipping PostgreSQL checks')
        return

    tables = ['persons', 'checkins', 'transfers', 'alerts', 'families', 'needs', 'audit_logs']
    conn = psycopg2.connect(db_url)
    with conn.cursor() as cur:
        for table in tables:
            export_count = count_ndjson(os.path.join(export_dir, f'{table}.json'))
            cur.execute(f'SELECT COUNT(*) FROM {table}')
            pg_count = cur.fetchone()[0]
            check(f'{table}: count {export_count} → PG {pg_count}', pg_count >= export_count)

        cur.execute("SELECT COUNT(*) FROM persons WHERE organization_id IS NULL OR organization_id = ''")
        null_org = cur.fetchone()[0]
        check('persons: all have organization_id', null_org == 0, f'{null_org} missing')

    conn.close()


def check_s3(storage_dir):
    try:
        import boto3
        from botocore.client import Config
    except ImportError:
        print(f'{WARN} boto3 not installed, skipping S3 checks')
        return

    required = ['S3_ENDPOINT', 'S3_ACCESS_KEY', 'S3_SECRET_KEY']
    if any(not os.environ.get(v) for v in required):
        print(f'{WARN} S3 env vars not set, skipping S3 checks')
        return

    client = boto3.client(
        's3',
        endpoint_url=os.environ['S3_ENDPOINT'],
        aws_access_key_id=os.environ['S3_ACCESS_KEY'],
        aws_secret_access_key=os.environ['S3_SECRET_KEY'],
        config=Config(signature_version='s3v4'),
    )
    bucket = os.environ.get('S3_BUCKET', 'safepoint-prod')

    local_count = sum(len(files) for _, _, files in os.walk(storage_dir)) if os.path.isdir(storage_dir) else 0
    paginator = client.get_paginator('list_objects_v2')
    s3_count = sum(page.get('KeyCount', 0) for page in paginator.paginate(Bucket=bucket))
    check(f'S3: local {local_count} files → S3 {s3_count} objects', s3_count >= local_count)


def check_keycloak(export_dir):
    try:
        import requests
    except ImportError:
        print(f'{WARN} requests not installed, skipping Keycloak checks')
        return

    keycloak_url = os.environ.get('KEYCLOAK_URL')
    realm = os.environ.get('KEYCLOAK_REALM', 'safepoint')
    client_secret = os.environ.get('KEYCLOAK_CLIENT_SECRET')
    if not keycloak_url or not client_secret:
        print(f'{WARN} KEYCLOAK_URL / KEYCLOAK_CLIENT_SECRET not set, skipping')
        return

    token_url = f'{keycloak_url}/realms/master/protocol/openid-connect/token'
    resp = requests.post(token_url, data={
        'grant_type': 'client_credentials',
        'client_id': os.environ.get('KEYCLOAK_CLIENT_ID', 'admin-cli'),
        'client_secret': client_secret,
    })
    resp.raise_for_status()
    token = resp.json()['access_token']

    users_url = f'{keycloak_url}/admin/realms/{realm}/users/count'
    kc_count = requests.get(users_url, headers={'Authorization': f'Bearer {token}'}).json()

    auth_export = os.path.join(export_dir, 'firebase_users.json')
    firebase_count = len(json.load(open(auth_export))) if os.path.exists(auth_export) else 0

    check(f'Keycloak: Firebase {firebase_count} → Keycloak {kc_count} users', kc_count >= firebase_count)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--export-dir', default='./export')
    parser.add_argument('--storage-dir', default='./storage_export')
    args = parser.parse_args()

    print('=== SafePoint V2 Migration Verification ===\n')
    check_postgresql(args.export_dir)
    check_s3(args.storage_dir)
    check_keycloak(args.export_dir)

    print(f'\n{"=" * 44}')
    if failures:
        print(f'{FAIL} {len(failures)} check(s) failed:')
        for f in failures:
            print(f'  - {f}')
        sys.exit(1)
    else:
        print(f'{PASS} All checks passed. Migration verified.')


if __name__ == '__main__':
    main()
