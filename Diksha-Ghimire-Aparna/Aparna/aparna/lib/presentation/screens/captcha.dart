import 'package:flutter/material.dart';
import 'package:slider_captcha/slider_captcha.dart';
import '../../main.dart'; // Import AppTheme from main.dart
// import 'package:spicebite/pages/navigationBar.dart';

class captcha extends StatefulWidget {
  final VoidCallback? onCaptchaConfirmed;
  
  const captcha({super.key, this.onCaptchaConfirmed});

  @override
  State<captcha> createState() => _captchaState();
}

class _captchaState extends State<captcha> {
  final SliderController controller = SliderController();
  bool _isVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Human Verification'),
      //   backgroundColor: Colors.deepOrange,
      // ),
      body: Container(
        decoration: const BoxDecoration(
         
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please verify that you are human',
                style: TextStyle(
                  color: const Color.fromARGB(255, 17, 17, 17),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Container(
                width: 300,
                height: 200,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SliderCaptcha(
                  controller: controller,
                  image: Image.asset(
                    'assets/captcha_img.png', 
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.restaurant, size: 50, color: Colors.grey[600]),
                        ),
                  ),
                  colorBar: AppTheme.primaryColor,
                  colorCaptChar: AppTheme.primaryColor,
                  onConfirm: (value) async {
                    // The value parameter is true if the puzzle is aligned, false otherwise.
                    if (value == true) {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                  SizedBox(height: 10),
                                  Text('Verifying...', style: TextStyle(color: AppTheme.primaryColor,fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      
                      await Future.delayed(const Duration(seconds: 2));
                      
                      Navigator.pop(context); // Close loading dialog
                      
                      setState(() {
                        _isVerified = true;
                      });
                      
                      // Wait a bit then proceed
                      await Future.delayed(Duration(seconds: 1));
                      
                      // Pop the captcha dialog, then call the callback (e.g. send OTP for signup)
                      Navigator.pop(context);
                      if (widget.onCaptchaConfirmed != null) {
                        widget.onCaptchaConfirmed!();
                      }

                    }
                   else {
                    // Puzzle piece not aligned properly, show error and do not verify
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Puzzle not aligned properly. Please try again.'),
                          backgroundColor: Colors.red,
                          duration: Duration(milliseconds: 600),
                        ),
                      );
                      // Optionally, you can also reset the slider
                      controller.create();
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
              if (_isVerified)
               
              
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Verified Human',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
