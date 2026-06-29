#!/usr/bin/env python3
"""
SafePoint V1 → V2 Migration
Step 4b: Upload local Storage export to S3-compatible endpoint (Cloud Temple).

Usage:
    S3_ENDPOINT=https://s3.cloud-temple.com \
    S3_ACCESS_KEY=xxx \
    S3_SECRET_KEY=yyy \
    S3_BUCKET=safepoint-prod \
    python import_s3.py --input ./storage_export

Requirements:
    pip install boto3
"""

import argparse
import os
import sys

try:
    import boto3
    from botocore.client import Config
except ImportError:
    print('ERROR: boto3 not installed. Run: pip install boto3')
    sys.exit(1)

S3_ENDPOINT = os.environ.get('S3_ENDPOINT')
S3_ACCESS_KEY = os.environ.get('S3_ACCESS_KEY')
S3_SECRET_KEY = os.environ.get('S3_SECRET_KEY')
S3_BUCKET = os.environ.get('S3_BUCKET', 'safepoint-prod')


def get_client():
    return boto3.client(
        's3',
        endpoint_url=S3_ENDPOINT,
        aws_access_key_id=S3_ACCESS_KEY,
        aws_secret_access_key=S3_SECRET_KEY,
        config=Config(signature_version='s3v4'),
    )


def upload_directory(client, local_dir):
    count = 0
    errors = 0
    for root, _dirs, files in os.walk(local_dir):
        for fname in files:
            local_path = os.path.join(root, fname)
            # S3 key mirrors the local path relative to input dir
            s3_key = os.path.relpath(local_path, local_dir).replace(os.sep, '/')
            try:
                client.upload_file(local_path, S3_BUCKET, s3_key)
                count += 1
                if count % 50 == 0:
                    print(f'  Uploaded {count} files...')
            except Exception as e:
                print(f'[ERROR] {s3_key}: {e}')
                errors += 1
    return count, errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default='./storage_export')
    args = parser.parse_args()

    required = ['S3_ENDPOINT', 'S3_ACCESS_KEY', 'S3_SECRET_KEY']
    missing = [v for v in required if not os.environ.get(v)]
    if missing:
        print(f'ERROR: missing env vars: {", ".join(missing)}')
        sys.exit(1)

    if not os.path.isdir(args.input):
        print(f'ERROR: input directory not found: {args.input}')
        sys.exit(1)

    client = get_client()
    print(f'Uploading to s3://{S3_BUCKET} at {S3_ENDPOINT}')
    count, errors = upload_directory(client, args.input)
    print(f'\nUpload complete: {count} files uploaded, {errors} errors')
    if errors:
        sys.exit(1)


if __name__ == '__main__':
    main()
