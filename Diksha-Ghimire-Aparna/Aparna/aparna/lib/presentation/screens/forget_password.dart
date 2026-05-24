import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forgot_password/forgot_password_bloc.dart';
import '../bloc/forgot_password/forgot_password_event.dart';
import '../bloc/forgot_password/forgot_password_state.dart';
import 'package:aparna/l10n/app_localizations.dart';
import 'otp_verification_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.06).clamp(20.0, 32.0);
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is OTPSentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Capture the bloc before navigation
          final bloc = context.read<ForgotPasswordBloc>();
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: OTPVerificationScreen(email: state.email),
              ),
            ),
          );
        } else if (state is ForgotPasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8A5A5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Back Button and Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF8B3A3A),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.forgotPassword,
                      style: const TextStyle(
                        color: Color(0xFF8B3A3A),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset('assets/aparna_logo.png', width: 100, height: 100),
              ),
              const SizedBox(height: 5),
              const Text(
                'Aparna',
                style: TextStyle(
                  color: Color(0xFF8B3A3A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
                // White Card Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        AppLocalizations.of(context)!.forgotPassword,
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Subtitle
                      Text(
                        AppLocalizations.of(context)!.forgotPasswordSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Email/Username Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.emailOrUsername,
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Send OTP Button
                      BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: state is ForgotPasswordLoading
                                  ? null
                                  : _handleSendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A3333),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: state is ForgotPasswordLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.sendOTP,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      )
    );
  }

  void _handleSendOTP() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterEmailOrUsername),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterValidEmail),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dispatch event to bloc
    context.read<ForgotPasswordBloc>().add(SendOTPEvent(email: email));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

// Custom painter for the flower logo
class FlowerLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double petalSize = size.width / 2.2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Top-left petal (coral/salmon)
    final paint1 = Paint()..color = const Color(0xFFE8A598);
    canvas.drawCircle(
      Offset(centerX - petalSize / 2, centerY - petalSize / 2),
      petalSize / 2,
      paint1,
    );

    // Top-right petal (dark red/maroon)
    final paint2 = Paint()..color = const Color(0xFF8B3A3A);
    canvas.drawCircle(
      Offset(centerX + petalSize / 2, centerY - petalSize / 2),
      petalSize / 2,
      paint2,
    );

    // Bottom-left petal (dark red/maroon)
    final paint3 = Paint()..color = const Color(0xFF8B3A3A);
    canvas.drawCircle(
      Offset(centerX - petalSize / 2, centerY + petalSize / 2),
      petalSize / 2,
      paint3,
    );

    // Bottom-right petal (pink)
    final paint4 = Paint()..color = const Color(0xFFF8A5A5);
    canvas.drawCircle(
      Offset(centerX + petalSize / 2, centerY + petalSize / 2),
      petalSize / 2,
      paint4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
