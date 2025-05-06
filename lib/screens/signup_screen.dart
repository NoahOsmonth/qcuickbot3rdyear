import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../theme/app_theme.dart'; // Import AppTheme for colors

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true, _obscureConfirm = true;
  // Keep password regex for validation
  final _pwdRegex = RegExp(r'^(?=.*\d)(?=.*[@$!%*#?&.]).{8,}$'); // Added . to symbols

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ref.read(authServiceProvider).signUp(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        // On successful signup, Supabase might automatically sign the user in
        // or require email confirmation depending on your settings.
        // The auth state listener in main.dart will handle navigation.
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Signup successful! Check email for confirmation if needed.')),
           );
           // Optionally navigate back to login or let the listener handle it
           // Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        setState(() {
          // Provide a more user-friendly error message
          if (e.toString().contains('duplicate key value violates unique constraint')) {
             _errorMessage = 'An account with this email already exists.';
          } else {
             _errorMessage = 'Failed to sign up. Please try again.';
          }
          // _errorMessage = 'Failed to sign up: ${e.toString()}'; // Original for debugging
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // No AppBar
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title Section - Using RichText for different styling
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.w500,
                      ),
                      children: <TextSpan>[
                        const TextSpan(text: 'Create\n'), // Line break
                        TextSpan(
                          text: 'ACCOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Bolder for ACCOUNT
                            fontSize: (textTheme.headlineMedium?.fontSize ?? 28) * 1.1, // Slightly larger
                            height: 1.2, // Adjust line height
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48), // Increased spacing

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: Theme.of(context).iconTheme.color),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, size: 20, color: Theme.of(context).iconTheme.color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                           size: 20,
                           color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      // Adding helper text for password requirements
                      helperText: 'Min. 8 characters, with number & symbol (@\$!%*#?&.)',
                      helperMaxLines: 2,
                      helperStyle: textTheme.bodySmall?.copyWith(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) {
                      if (v == null || !_pwdRegex.hasMatch(v)) {
                        return 'Password does not meet requirements'; // Shorter error
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                       prefixIcon: Icon(Icons.lock_outline, size: 20, color: Theme.of(context).iconTheme.color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                           size: 20,
                           color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _signUp(),
                  ),
                  const SizedBox(height: 24), // Space before error/button

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

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.lightText,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 48), // Space before Login link

                  // Login Link
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(
                         "Already have an account? ",
                         style: textTheme.bodySmall?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                       ),
                       TextButton(
                         onPressed: () {
                           Navigator.pushReplacementNamed(context, '/login');
                         },
                         child: const Text("Sign in here"), // Changed text
                          style: TextButton.styleFrom(
                           padding: EdgeInsets.zero,
                           minimumSize: Size.zero,
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                           textStyle: textTheme.bodySmall?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: AppColors.primaryBlue,
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
