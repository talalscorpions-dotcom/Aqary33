/// Where the AQARY backend (aqary_backend/) is reachable.
///
/// Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=https://your-codespace-3000.app.github.dev
///
/// The default only works for a simulator/emulator or a desktop/web build
/// running on the same machine as the backend. A physical phone can never
/// resolve "localhost" to the backend's host — it means the phone itself —
/// so testing on a real device requires a real reachable URL, such as a
/// GitHub Codespaces forwarded-port URL (make sure port 3000's visibility
/// is set to "Public" in the Ports tab, or the phone must be authenticated
/// to your GitHub account).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
