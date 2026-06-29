#!/usr/bin/env python3
"""
SafePoint V1 → V2 Migration
Step 2: Transform Firestore NDJSON exports into PostgreSQL-compatible CSV files.

Usage:
    python transform_firestore_to_sql.py --input ./export --output ./sql_import

Input:  ./export/<collection>.json  (NDJSON, one doc per line)
Output: ./sql_import/<table>.csv    (CSV with PostgreSQL column names)
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Column mappings: Firestore field → PostgreSQL column (per table)
# ---------------------------------------------------------------------------

PERSON_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'shelter_id',
    'family_id', 'qr_code', 'first_name', 'last_name', 'birth_date',
    'age_approx', 'origin_commune', 'origin_sector', 'phone',
    'emergency_contact_name', 'emergency_contact_phone', 'current_zone',
    'status', 'vulnerability_flags', 'need_flags', 'notes',
    'created_at', 'updated_at', 'created_by', 'updated_by',
    'last_checkin_at', 'is_deleted', 'archived_at', 'deleted_at',
    'visibility_level', 'retention_policy',
]

REFUGE_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'name',
    'address', 'commune', 'latitude', 'longitude', 'capacity',
    'current_count', 'status', 'type', 'responsable_id',
    'agent_ids', 'zones', 'stock_water_liters', 'stock_meals',
    'stock_blankets', 'has_medical', 'has_generator', 'has_wifi',
    'notes', 'created_at', 'updated_at', 'created_by', 'updated_by',
]

CHECKIN_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'shelter_id',
    'person_id', 'family_id', 'type', 'scanned_by', 'created_at',
    'notes', 'created_by',
]

TRANSFER_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id',
    'from_shelter_id', 'from_shelter_name', 'to_shelter_id', 'to_shelter_name',
    'person_ids', 'family_id', 'family_name', 'person_count', 'status',
    'transport_mode', 'departure_planned_at', 'departed_at',
    'arrival_confirmed_at', 'notes', 'created_at', 'updated_at',
    'created_by', 'updated_by',
]

ALERT_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'shelter_id',
    'person_id', 'family_id', 'type', 'severity', 'title', 'description',
    'status', 'assigned_to', 'location', 'created_at', 'updated_at',
    'resolved_at', 'created_by', 'updated_by',
]

FAMILY_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'shelter_id',
    'display_name', 'origin_commune', 'member_ids', 'members_count',
    'assigned_zone', 'is_separated', 'has_children_alone',
    'created_at', 'updated_at', 'created_by', 'updated_by',
]

NEED_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'event_id', 'shelter_id',
    'person_id', 'family_id', 'type', 'urgency', 'status', 'description',
    'created_at', 'updated_at', 'resolved_at', 'created_by', 'updated_by',
]

CRISIS_EVENT_COLUMNS = [
    'id', 'organization_id', 'territory_id', 'name', 'type',
    'description', 'status', 'started_at', 'ended_at',
    'created_at', 'updated_at', 'created_by', 'updated_by',
]

AUDIT_LOG_COLUMNS = [
    'id', 'organization_id', 'user_id', 'role', 'action',
    'target_type', 'target_id', 'timestamp', 'ip_address',
    'device_info', 'result', 'metadata',
]

USER_COLUMNS = [
    'id', 'organization_id', 'email', 'agent_code', 'first_name',
    'last_name', 'role', 'shelter_id', 'territory_id',
    'is_active', 'created_at', 'updated_at', 'last_login_at',
    'keycloak_id',
]


# ---------------------------------------------------------------------------
# Transformers per collection
# ---------------------------------------------------------------------------

def _arr(v):
    """Serialize list to PostgreSQL array literal."""
    if isinstance(v, list):
        return '{' + ','.join(f'"{x}"' for x in v) + '}'
    return ''


def _json(v):
    return json.dumps(v) if v is not None else ''


def transform_persons(docs):
    rows = []
    for d in docs:
        rows.append({
            'id': d.get('id', ''),
            'organization_id': d.get('organizationId', 'org_guadeloupe'),
            'territory_id': d.get('territoryId', ''),
            'event_id': d.get('eventId', ''),
            'shelter_id': d.get('shelterId', ''),
            'family_id': d.get('familyId', ''),
            'qr_code': d.get('qrCode', ''),
            'first_name': d.get('firstName', ''),
            'last_name': d.get('lastName', ''),
            'birth_date': d.get('birthDate', ''),
            'age_approx': d.get('ageApprox', ''),
            'origin_commune': d.get('originCommune', ''),
            'origin_sector': d.get('originSector', ''),
            'phone': d.get('phone', ''),
            'emergency_contact_name': d.get('emergencyContactName', ''),
            'emergency_contact_phone': d.get('emergencyContactPhone', ''),
            'current_zone': d.get('currentZone', ''),
            'status': d.get('status', ''),
            'vulnerability_flags': _arr(d.get('vulnerabilityFlags', [])),
            'need_flags': _arr(d.get('needFlags', [])),
            'notes': d.get('notes', ''),
            'created_at': d.get('createdAt', ''),
            'updated_at': d.get('updatedAt', d.get('createdAt', '')),
            'created_by': d.get('createdBy', ''),
            'updated_by': d.get('updatedBy', ''),
            'last_checkin_at': d.get('lastCheckinAt', ''),
            'is_deleted': d.get('isDeleted', False),
            'archived_at': d.get('archivedAt', ''),
            'deleted_at': d.get('deletedAt', ''),
            'visibility_level': d.get('visibilityLevel', 'organization'),
            'retention_policy': d.get('retentionPolicy', 'standard'),
        })
    return PERSON_COLUMNS, rows


def transform_audit_logs(docs):
    rows = []
    for d in docs:
        rows.append({
            'id': d.get('id', ''),
            'organization_id': d.get('organizationId', 'org_guadeloupe'),
            'user_id': d.get('userId', ''),
            'role': d.get('role', ''),
            'action': d.get('action', ''),
            'target_type': d.get('targetType', ''),
            'target_id': d.get('targetId', ''),
            'timestamp': d.get('timestamp', ''),
            'ip_address': d.get('ipAddress', ''),
            'device_info': d.get('deviceInfo', ''),
            'result': d.get('result', 'success'),
            'metadata': _json(d.get('metadata')),
        })
    return AUDIT_LOG_COLUMNS, rows


TRANSFORMERS = {
    'persons': transform_persons,
    'audit_logs': transform_audit_logs,
    # Additional transformers mirror the same pattern; add as needed.
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def load_ndjson(path):
    docs = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line:
                docs.append(json.loads(line))
    return docs


def write_csv(columns, rows, out_path):
    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=columns, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default='./export')
    parser.add_argument('--output', default='./sql_import')
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)

    for name, transform in TRANSFORMERS.items():
        src = os.path.join(args.input, f'{name}.json')
        if not os.path.exists(src):
            print(f'[SKIP] {src} not found')
            continue
        docs = load_ndjson(src)
        columns, rows = transform(docs)
        out = os.path.join(args.output, f'{name}.csv')
        write_csv(columns, rows, out)
        print(f'[OK] {name}: {len(rows)} rows → {out}')

    print('\nTransformation complete.')


if __name__ == '__main__':
    main()
