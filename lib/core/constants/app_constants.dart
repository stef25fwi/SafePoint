class FirestoreCollections {
  static const organizations = 'organizations';
  static const users = 'users';
  static const refuges = 'refuges';
  static const persons = 'persons';
  static const checkins = 'checkins';
  static const transfers = 'transfers';
  static const alerts = 'alerts';
  static const files = 'files';
  static const auditLogs = 'audit_logs';
  static const crisisEvents = 'crisis_events';
  static const families = 'families';
  static const needs = 'needs';
}

class StoragePaths {
  static String organizations(String orgId) => '/organizations/$orgId';
  static String refuges(String refugeId) => '/refuges/$refugeId';
  static String persons(String personId) => '/persons/$personId';
  static String alerts(String alertId) => '/alerts/$alertId';
  static String reports(String reportId) => '/reports/$reportId';
}

class AppDefaults {
  static const organizationId = 'org_guadeloupe';
  static const territoryId = 'territory_guadeloupe';
  static const systemUserId = 'system';
  static const demoUserId = 'agent_demo';
}

class NotificationTopics {
  static const crisisAlerts = 'crisis_alerts';
  static const refugeUpdates = 'refuge_updates';
}
