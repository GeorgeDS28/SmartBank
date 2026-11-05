//lib/features/user/data/models/user_profile.dart

class UserProfile {
  final String message;

  UserProfile({required this.message});

  factory UserProfile.fromResponse(dynamic response) {
    return UserProfile(message: response.toString());
  }
}
