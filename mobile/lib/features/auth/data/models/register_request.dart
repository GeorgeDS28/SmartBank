//lib/features/auth/data/models/register_request.dart

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}
