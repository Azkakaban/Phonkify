import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_logo.dart';

import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await _authService.login(
        email:
            _emailController.text.trim(),
        password:
            _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text('Login berhasil!'),
          ),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            'Terjadi kesalahan: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google login gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegisterPage() {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Login untuk melanjutkan '
                  'ke Phonkify.',
                  style: TextStyle(
                    color:
                        Colors.grey.shade400,
                  ),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Email wajib diisi';
                    }

                    if (!value
                        .contains('@')) {
                      return 'Masukkan email yang valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _passwordController,
                  obscureText:
                      _obscurePassword,
                  decoration:
                      InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                    ),
                    border:
                        const OutlineInputBorder(),
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Password wajib diisi';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),


                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    GoogleLogo(size: 24), SizedBox(width: 12), Text('Continue with Google'),
                  ]),
                ),
                const SizedBox(height: 20),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun?',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade400,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _openRegisterPage,
                      child: const Text(
                        'Register',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}