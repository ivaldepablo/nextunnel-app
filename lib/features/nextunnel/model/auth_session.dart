import 'package:dart_mappable/dart_mappable.dart';

part 'auth_session.mapper.dart';

@MappableClass()
class AuthSession with AuthSessionMappable {
  final String userId;
  final String email;
  final String sessionToken;
  final String subscriptionToken;
  final String? planName;
  final DateTime? planExpiresAt;
  final DateTime createdAt;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.sessionToken,
    required this.subscriptionToken,
    this.planName,
    this.planExpiresAt,
    required this.createdAt,
  });

  bool get isExpired {
    final expiry = planExpiresAt;
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  static const fromMap = AuthSessionMapper.fromMap;
  static const fromJson = AuthSessionMapper.fromJson;
}
