import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _signInEmailCtrl = TextEditingController();
  final _signInPasswordCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailCtrl.dispose();
    _signInPasswordCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC78EF8), Color(0xFFD7EAFF), Color(0xFFEFF3F7)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.health_and_safety_rounded,
                        size: 44,
                        color: Color(0xFF7A3CF3),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'MedTime',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B1247),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.65),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF7A3CF3),
                          unselectedLabelColor: const Color(0xFF4E4A57),
                          indicatorColor: const Color(0xFF7A3CF3),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (authState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            authState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB00020),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 210,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _AuthForm(
                              emailController: _signInEmailCtrl,
                              passwordController: _signInPasswordCtrl,
                              buttonText: 'Sign In',
                              onSubmit: () async {
                                notifier.clearError();
                                await notifier.signIn(
                                  email: _signInEmailCtrl.text,
                                  password: _signInPasswordCtrl.text,
                                );
                              },
                            ),
                            _AuthForm(
                              emailController: _signUpEmailCtrl,
                              passwordController: _signUpPasswordCtrl,
                              buttonText: 'Sign Up',
                              onSubmit: () async {
                                notifier.clearError();
                                await notifier.signUp(
                                  email: _signUpEmailCtrl.text,
                                  password: _signUpPasswordCtrl.text,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          notifier.clearError();
                          await notifier.signInWithGoogle();
                        },
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Continue with Google'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.emailController,
    required this.passwordController,
    required this.buttonText,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String buttonText;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    const fieldFill = Color(0xFFF6F7FB);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF7A3CF3), width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF7A3CF3), width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7A3CF3),
          ),
          onPressed: onSubmit,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
