/// The authenticated user, per `POST /auth/log-in` and `POST /auth/sign-up`
/// in aqary_backend. Login responds with `verificationStatus` (camelCase);
/// sign-up's `user` object comes straight from a `RETURNING` clause and is
/// `verification_status` (snake_case) — this accepts either.
class AppUser {
  final String id;
  final String email;
  final String role; // buyer | seller | professional | admin
  final String verificationStatus; // active | pending | rejected

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.verificationStatus,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      verificationStatus:
          (json['verificationStatus'] ?? json['verification_status'] ?? 'active')
              as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'verificationStatus': verificationStatus,
      };
}
