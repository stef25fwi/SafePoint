#!/usr/bin/env python3
"""
SafePoint V1 → V2 Migration
Step 5b: Import users into Keycloak (realm safepoint).

Maps Firebase Auth uid + Firestore /users role to Keycloak users with
the corresponding realm role (UPPER_SNAKE_CASE, e.g. REFUGE_MANAGER).

Usage:
    KEYCLOAK_URL=https://auth.safepoint.guadeloupe.fr \
    KEYCLOAK_REALM=safepoint \
    KEYCLOAK_CLIENT_ID=admin-cli \
    KEYCLOAK_CLIENT_SECRET=xxx \
    python import_keycloak_users.py \
        --auth-export ./export/firebase_users.json \
        --users-export ./export/users.json

Requirements:
    pip install requests
"""

import argparse
import json
import os
import sys

try:
    import requests
except ImportError:
    print('ERROR: requests not installed. Run: pip install requests')
    sys.exit(1)

KEYCLOAK_URL = os.environ.get('KEYCLOAK_URL', 'https://auth.safepoint.guadeloupe.fr')
REALM = os.environ.get('KEYCLOAK_REALM', 'safepoint')
CLIENT_ID = os.environ.get('KEYCLOAK_CLIENT_ID', 'admin-cli')
CLIENT_SECRET = os.environ.get('KEYCLOAK_CLIENT_SECRET')

# Role mapping: Flutter enum name → Keycloak role name
ROLE_MAP = {
    'superAdmin': 'SUPER_ADMIN',
    'prefectureAdmin': 'PREFECTURE_ADMIN',
    'regionAdmin': 'REGION_ADMIN',
    'communeAdmin': 'COMMUNE_ADMIN',
    'refugeManager': 'REFUGE_MANAGER',
    'agent': 'AGENT',
    'readOnlyObserver': 'READ_ONLY_OBSERVER',
    'crisisCell': 'CRISIS_CELL',
    'auditor': 'AUDITOR',
}


def get_admin_token():
    url = f'{KEYCLOAK_URL}/realms/master/protocol/openid-connect/token'
    resp = requests.post(url, data={
        'grant_type': 'client_credentials',
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
    })
    resp.raise_for_status()
    return resp.json()['access_token']


def create_user(token, email, display_name, firebase_uid, disabled):
    url = f'{KEYCLOAK_URL}/admin/realms/{REALM}/users'
    payload = {
        'username': email,
        'email': email,
        'firstName': display_name.split(' ')[0] if display_name else '',
        'lastName': ' '.join(display_name.split(' ')[1:]) if display_name else '',
        'enabled': not disabled,
        'emailVerified': True,
        'attributes': {'firebase_uid': [firebase_uid]},
    }
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    resp = requests.post(url, json=payload, headers=headers)
    if resp.status_code == 409:
        return None  # already exists
    resp.raise_for_status()
    location = resp.headers.get('Location', '')
    return location.split('/')[-1]  # Keycloak user id


def assign_role(token, kc_user_id, role_name):
    # Get role representation
    url = f'{KEYCLOAK_URL}/admin/realms/{REALM}/roles/{role_name}'
    headers = {'Authorization': f'Bearer {token}'}
    resp = requests.get(url, headers=headers)
    if resp.status_code == 404:
        print(f'  [WARN] Role {role_name} not found in Keycloak realm')
        return
    resp.raise_for_status()
    role = resp.json()

    # Assign to user
    url2 = f'{KEYCLOAK_URL}/admin/realms/{REALM}/users/{kc_user_id}/role-mappings/realm'
    resp2 = requests.post(url2, json=[role], headers={**headers, 'Content-Type': 'application/json'})
    resp2.raise_for_status()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--auth-export', default='./export/firebase_users.json')
    parser.add_argument('--users-export', default='./export/users.json')
    args = parser.parse_args()

    if not CLIENT_SECRET:
        print('ERROR: KEYCLOAK_CLIENT_SECRET env var required')
        sys.exit(1)

    with open(args.auth_export, 'r') as f:
        auth_users = json.load(f)

    # Build uid → Firestore user doc lookup
    fs_users = {}
    with open(args.users_export, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                doc = json.loads(line)
                fs_users[doc.get('id', '')] = doc

    token = get_admin_token()
    print(f'Authenticated with Keycloak realm: {REALM}')

    created = skipped = errors = 0
    for au in auth_users:
        uid = au['uid']
        fs_doc = fs_users.get(uid, {})
        role_name = ROLE_MAP.get(fs_doc.get('role', ''), 'AGENT')

        try:
            kc_id = create_user(token, au['email'], au.get('displayName', ''), uid, au.get('disabled', False))
            if kc_id is None:
                skipped += 1
                continue
            assign_role(token, kc_id, role_name)
            created += 1
        except Exception as e:
            print(f'[ERROR] {au["email"]}: {e}')
            errors += 1

    print(f'\nDone: {created} created, {skipped} skipped (already exist), {errors} errors')


if __name__ == '__main__':
    main()
