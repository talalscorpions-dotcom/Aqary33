import 'api_client.dart';

/// Everything behind the AdminShell's Dashboard and Leads tabs. All routes
/// require an admin JWT (requireRole(['admin']) server-side) — ApiClient
/// already attaches whatever token AuthService.adminLogIn stored.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  /// GET /admin/analytics/overview — the stat cards at the top of the
  /// Dashboard tab: signups, logins, leads, approvals, engagement.
  Future<Map<String, dynamic>> fetchOverview() {
    return ApiClient.instance.get('/admin/analytics/overview');
  }

  /// GET /admin/analytics/leads-timeseries — leads created vs. closed,
  /// bucketed by day/week/month, for the trend chart.
  Future<List<Map<String, dynamic>>> fetchLeadsTimeseries({
    required String bucket,
    int days = 30,
  }) async {
    final rows = await ApiClient.instance.getList('/admin/analytics/leads-timeseries', query: {
      'bucket': bucket,
      'days': days,
    });
    return rows.cast<Map<String, dynamic>>();
  }

  /// GET /admin/analytics/listing-clicks — top listings ranked by clicks.
  Future<List<Map<String, dynamic>>> fetchTopListings({int limit = 10}) async {
    final rows = await ApiClient.instance.getList('/admin/analytics/listing-clicks', query: {
      'limit': limit,
    });
    return rows.cast<Map<String, dynamic>>();
  }

  /// GET /admin/leads — the real leads list (viewings + service bookings).
  Future<List<Map<String, dynamic>>> fetchLeads({String? status, int limit = 50}) async {
    final rows = await ApiClient.instance.getList('/admin/leads', query: {
      'status': status,
      'limit': limit,
    });
    return rows.cast<Map<String, dynamic>>();
  }
}
