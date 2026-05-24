import 'package:flutter/material.dart';
import 'captcha.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../main.dart'; // Import AppTheme and navigatorKey from main.dart
import 'signup_otp_verification_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isCaptchaDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
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
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showCaptchaDialogAndRegister({required Future<void> Function() onCaptchaConfirmed}) async {
    if (_isCaptchaDialogOpen) return;
    _isCaptchaDialogOpen = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: SizedBox(
            width: 430,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.all(Radius.circular(50.0)),
              ),
              child: Stack(
                children: [
                  captcha(
                    onCaptchaConfirmed: () async {
                      // Note: captcha already pops the dialog before calling this callback
                      _isCaptchaDialogOpen = false;
                      await onCaptchaConfirmed();
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _isCaptchaDialogOpen = false;
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Color.fromARGB(255, 43, 42, 42),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _isCaptchaDialogOpen = false;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format date as YYYY-MM-DD for better database compatibility
        final year = picked.year.toString();
        final month = picked.month.toString().padLeft(2, '0');
        final day = picked.day.toString().padLeft(2, '0');
        _dateOfBirthController.text = "$year-$month-$day";
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // Show CAPTCHA first, then send OTP for email verification
    await _showCaptchaDialogAndRegister(onCaptchaConfirmed: _sendSignupOTP);
  }

  Future<void> _sendSignupOTP() async {
    if (!mounted) return;
    context.read<AuthBloc>().add(SendSignupOTPRequested(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.08).clamp(24.0, 48.0);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else if (state is OTPSentForSignup) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(milliseconds: 1500),
            ),
          );
          final email = _emailController.text.trim();
          final username = _usernameController.text.trim();
          final phone = _phoneController.text.trim();
          final dateOfBirth = _dateOfBirthController.text.trim();
          final password = _passwordController.text;
          final authBloc = context.read<AuthBloc>();
          final route = MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: authBloc,
              child: SignupOTPVerificationScreen(
                email: email,
                username: username,
                phone: phone,
                dateOfBirth: dateOfBirth,
                password: password,
              ),
            ),
          );
          // Use navigatorKey + addPostFrameCallback to ensure reliable navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigator = navigatorKey.currentState;
            if (navigator != null && mounted) {
              navigator.pushAndRemoveUntil(route, (r) => r.isFirst);
            }
          });
        } else if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 500),
            ),
          );
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 32),
                          _buildRegistrationForm(),
                          const SizedBox(height: 24),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              // Close button positioned at top-left
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/aparna_logo.png',
          height: 100,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.favorite, size: 100, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.createAccount,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.joinCommunity,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(16),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.1),
        //       blurRadius: 20,
        //       offset: const Offset(0, 10),
        //     ),
        //   ],
        // ),
        child: Column(
          children: [
            _buildTextField(
              controller: _usernameController,
              hintText: AppLocalizations.of(context)!.username,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterUsername;
                }
                if (value.length < 3) {
                  return AppLocalizations.of(context)!.usernameTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              hintText: AppLocalizations.of(context)!.email,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterEmail;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              hintText: AppLocalizations.of(context)!.phoneNumber,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPhone;
                }
                if (value.length < 10) {
                  return AppLocalizations.of(context)!.phoneTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hintText: AppLocalizations.of(context)!.password,
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              isPassword: true,
              isConfirmPassword: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPassword;
                }
                if (value.length < 6) {
                  return AppLocalizations.of(context)!.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: AppLocalizations.of(context)!.confirmPassword,
              prefixIcon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              isPassword: true,
              isConfirmPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseConfirmPassword;
                }
                if (value != _passwordController.text) {
                  return AppLocalizations.of(context)!.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    if (isConfirmPassword) {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    } else {
                      _isPasswordVisible = !_isPasswordVisible;
                    }
                  });
                },
                icon: Icon(
                  (isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible) 
                      ? Icons.visibility 
                      : Icons.visibility_off,
                  color: AppTheme.primaryColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateOfBirthController,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectDOB;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.dateOfBirth,
        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
        filled: true,
        fillColor: const Color.fromARGB(255, 249, 248, 247).withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.register.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.alreadyHaveAccount,
          style: const TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Text(
            AppLocalizations.of(context)!.login,
            style: const TextStyle(
              color: Colors.white,
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