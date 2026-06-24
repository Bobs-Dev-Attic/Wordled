/// Result of a maintenance action, for surfacing in the UI.
class MaintenanceResult {
  MaintenanceResult(this.success, this.message);
  final bool success;
  final String message;
}
