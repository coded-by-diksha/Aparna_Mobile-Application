import 'package:aparna/presentation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'register.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../../core/di/dependency_injection.dart';
import '../../main.dart'; // Import AppTheme from main.dart
import 'admin/admin_dashboard.dart';
import 'forget_password.dart';
import 'package:aparna/l10n/app_localizations.dart';



class GlobalState {
  Future<void> updateCartCountFromAPI() async {}
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, //vsync is used here to animate the login page 
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _handleLogin() async {
    if (!mounted) return;
    // Validate inputs first
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillAllFields),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    // Use BLoC for login
    context.read<AuthBloc>().add(LoginRequested(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    ));
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    context.read<AuthBloc>().add(const GoogleSignInStarted());
  }

  /// Breakpoints: compact < 600, medium 600–840, expanded > 840
  static double get _breakpointCompact => 600;
  static double get _breakpointMedium => 840;

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _breakpointCompact;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final width = size.width;
    final height = size.height;
    final horizontalPadding = (width * 0.08).clamp(16.0, 48.0);
    final maxFormWidth = width > _breakpointMedium ? 420.0 : double.infinity;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only react to login-related states, ignore registration flow
        return current is AuthAuthenticated || current is AuthError;
      },
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          print('[LOGIN_LISTENER] AuthAuthenticated state received');
          // Get user role from profile
          final userProfile = state.userProfile;
          final userRole = userProfile['role']?.toString().toLowerCase() ?? 'user';
          final sessionUserName =
              (userProfile['username']?.toString().isNotEmpty == true
                      ? userProfile['username'].toString()
                      : userProfile['email']?.toString()) ??
                  _usernameController.text;
          print('[LOGIN_LISTENER] User role: $userRole, username: $sessionUserName');
          // Navigate based on role
          if (userRole == 'admin') {
            // Redirect admin to admin dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(
                  userName: sessionUserName,
                  userProfile: userProfile,
                ),
              ),
            );
          } else {
            // Regular user - navigate to main screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainNavigationScreen(userName: sessionUserName)),
            );
          }
        } else if (state is AuthError) {
          print('[LOGIN_LISTENER] AuthError state received: ${state.message}');
          print('[LOGIN_LISTENER] Status code: ${state.statusCode}');
          if (state.statusCode == 401) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.loginFailed),
                content: Text(AppLocalizations.of(context)!.invalidCredentials),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            );
          } else {
            print('[LOGIN_LISTENER] Showing error snackbar: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.backgroundColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxFormWidth,
                        minHeight: height - MediaQuery.paddingOf(context).vertical,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogo(context),
                            SizedBox(height: height < 600 ? 24 : 48),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return _buildLoginForm(context, isLoading: isLoading);
                              },
                            ),
                            SizedBox(height: height < 600 ? 12 : 16),
                            _buildOrDivider(context),
                            SizedBox(height: height < 600 ? 12 : 16),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading || state is GoogleSignInInProgress;
                                return _buildGoogleSignInButton(context, isLoading: isLoading);
                              },
                            ),
                            SizedBox(height: height < 600 ? 16 : 24),
                            _buildForgotPasswordButton(context),
                            SizedBox(height: height < 600 ? 16 : 24),
                            _buildSignupLink(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Close button positioned at top-left
              Positioned(
                top: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    // decoration: BoxDecoration(
                    //   color: Colors.white.withOpacity(0.2),
                    //   borderRadius: BorderRadius.circular(30),
                    //   border: Border.all(
                    //     color: Colors.white.withOpacity(0.3),
                    //     width: 1,
                    //   ),
                    // ),
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: _isCompact(context) ? 20 : 24,
                      ),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(_isCompact(context) ? 6 : 8),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final logoHeight = height * 0.20; // 13% of screen height
    final logoSpacing = height * 0.02; // 2% of screen height
    return Column(
      children: [
        Image.asset(
          'assets/aparna_logo.png',
          height: logoHeight.clamp(60.0, 140.0),
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.favorite, size: logoHeight.clamp(60.0, 140.0), color: Colors.white),
        ),
        SizedBox(height: logoSpacing.clamp(8.0, 24.0)),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isLoading}) {
    final size = MediaQuery.sizeOf(context);
    final padding = (size.width * 0.05).clamp(12.0, 32.0); // 5% of width
    final spacing = (size.height * 0.015).clamp(8.0, 24.0); // 1.5% of height
    final bottomSpacing = (size.height * 0.03).clamp(12.0, 32.0); // 3% of height
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        // color: Colors.white,
        // borderRadius: BorderRadius.circular(compact ? 12 : 16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     blurRadius: 20,
        //     offset: const Offset(0, 10),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          _buildTextField(
            context: context,
            controller: _usernameController,
            hintText: AppLocalizations.of(context)!.emailOrUsername,
            prefixIcon: Icons.person_outline,
            obscureText: false,
            isPassword: false,
          ),
          SizedBox(height: spacing),
          _buildTextField(
            context: context,
            controller: _passwordController,
            hintText: AppLocalizations.of(context)!.password,
            prefixIcon: Icons.lock_outline,
            obscureText: !_isPasswordVisible,
            isPassword: true,
          ),
          SizedBox(height: bottomSpacing),
          _buildLoginButton(context, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    final compact = _isCompact(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: compact ? 14 : 16, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
        prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor, size: compact ? 20 : 24),
        filled: true,
        fillColor: const Color.fromARGB(255, 245, 249, 249),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.primaryColor,
                  size: compact ? 20 : 24,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, {required bool isLoading}) {
    final size = MediaQuery.sizeOf(context);
    final compact = _isCompact(context);
    final verticalPadding = (size.height * 0.02).clamp(10.0, 24.0); // 2% of height
    final fontSize = (size.width * 0.04).clamp(13.0, 18.0); // 4% of width
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          minimumSize: Size(0, verticalPadding * 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          elevation: 5,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.login.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    final compact = _isCompact(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Text(
            AppLocalizations.of(context)!.orSeparator,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, {required bool isLoading}) {
    final compact = _isCompact(context);
    final iconSize = compact ? 20.0 : 24.0;
    return SizedBox(
      width: double.infinity,
      height: compact ? 48 : 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _handleGoogleSignIn,
        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.grey,
                  strokeWidth: 2,
                ),
              )
            : Container(
                height: iconSize,
                width: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  height: iconSize,
                  width: iconSize,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.login, color: Colors.red, size: iconSize),
                ),
              ),
        label: Text(
          isLoading ? AppLocalizations.of(context)!.signingIn : AppLocalizations.of(context)!.continueWithGoogle,
          style: TextStyle(
            color: Colors.black87,
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    final compact = _isCompact(context);
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => DependencyInjection.createForgotPasswordBloc(),
              child: const ForgetPasswordScreen(),
            ),
          ),
        );
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(
        AppLocalizations.of(context)!.forgotPassword,
        style: TextStyle(color: Colors.white70, fontSize: compact ? 13 : 14),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context) {
    final compact = _isCompact(context);
    final fontSize = compact ? 13.0 : 14.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.dontHaveAccount,
            style: TextStyle(color: Colors.white, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: const RegistrationPage(),
                ),
              ),
            );
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            AppLocalizations.of(context)!.signUp,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
