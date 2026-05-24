abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    String? displayName,
  });

  Future<Map<String, dynamic>> sendSignupOTP({
    required String email,
    required String username,
    required String phone,
    required String dateOfBirth,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String email,
    required String otp,
  });

  Future<void> logout();
  Future<void> ensureTokenLoaded();
  Future<Map<String, dynamic>> validateToken();

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  bool get isLoggedIn;
  
  Map<String, dynamic> get userProfile;
}
