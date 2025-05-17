import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../theme/app_theme.dart'; // Import AppTheme for colors

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ref.read(authServiceProvider).signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        // Explicitly navigate after successful sign-in
        if (mounted) { // Check if the widget is still mounted before navigating
           Navigator.pushNamedAndRemoveUntil(context, '/chat', (route) => false);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to sign in. Please check your credentials.'; // More user-friendly message
          // _errorMessage = 'Failed to sign in: ${e.toString()}'; // Original for debugging
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // call when forgot-button tapped
  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter your email address first.');
      return;
    }
    setState(() => _errorMessage = null); // Clear previous errors
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Password reset failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // No AppBar in the new design
      body: SafeArea( // Ensure content doesn't overlap status bar
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title Section
                  Text(
                    'Welcome to',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onBackground, // Use theme color
                      fontWeight: FontWeight.w500, // Slightly less bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'QCUICKBOT!',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryBlue, // Specific blue color
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48), // Increased spacing

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email', // Changed from 'Email or Username' as per request
                      // hintText: 'Enter your email', // Optional hint
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: Theme.of(context).iconTheme.color),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next, // Move focus to password
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      // hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, size: 20, color: Theme.of(context).iconTheme.color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                    textInputAction: TextInputAction.done, // Submit form
                    onFieldSubmitted: (_) => _isLoading ? null : _signIn(), // Allow sign in on enter
                  ),
                  const SizedBox(height: 8), // Space before Forgot Password

                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _onForgotPassword,
                      child: const Text('Forgot Password?'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduce padding
                        textStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Space before error message/button

                  // Error Message Display
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, // Match text size
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.lightText, // Explicit color for indicator
                            ),
                          )
                        : const Text('Log In'), // Changed text
                  ),
                  const SizedBox(height: 48), // Space before Sign Up link

                  // Sign Up Link
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(
                         "Doesn't have an account? ",
                         style: textTheme.bodySmall?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                       ),
                       TextButton(
                         onPressed: () {
                           Navigator.pushReplacementNamed(context, '/signup');
                         },
                         child: const Text("Sign up here"),
                         style: TextButton.styleFrom(
                           padding: EdgeInsets.zero, // Remove extra padding
                           minimumSize: Size.zero, // Allow minimum size
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                           textStyle: textTheme.bodySmall?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: AppColors.primaryBlue, // Explicit color
                           ),
                         ),
                       ),
                     ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
