import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_scaffold.dart';

/// Sign in with email + password or with a magic link.
///
/// Expects a [SignInCubit] above it (provided by the router).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<SignInCubit>().submit(
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInCubit, SignInState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FormStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.magicLinkSentTo != null) {
          return _MagicLinkSent(email: state.magicLinkSentTo!);
        }
        final usePassword = state.method == SignInMethod.password;

        return AuthScaffold(
          title: 'Welcome back',
          subtitle: 'Sign in to track workouts and keep your routes safe.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<SignInMethod>(
                  segments: const [
                    ButtonSegment(
                      value: SignInMethod.password,
                      label: Text('Password'),
                      icon: Icon(Icons.password_rounded),
                    ),
                    ButtonSegment(
                      value: SignInMethod.magicLink,
                      label: Text('Magic link'),
                      icon: Icon(Icons.mark_email_unread_outlined),
                    ),
                  ],
                  selected: {state.method},
                  onSelectionChanged: (s) =>
                      context.read<SignInCubit>().selectMethod(s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('emailField'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: usePassword
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: Validators.email,
                  onFieldSubmitted: usePassword ? null : (_) => _submit(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: usePassword
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _PasswordField(
                            controller: _password,
                            onSubmitted: _submit,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('signInButton'),
                  onPressed: state.status.isSubmitting ? null : _submit,
                  child: state.status.isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(usePassword ? 'Sign in' : 'Email me a link'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push(AppRoutes.signUp),
                  child: const Text('New here? Create an account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('passwordField'),
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: Validators.password,
      onFieldSubmitted: (_) => widget.onSubmitted(),
    );
  }
}

class _MagicLinkSent extends StatelessWidget {
  const _MagicLinkSent({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Check your inbox',
      subtitle:
          'We sent a sign-in link to $email. Open it on this phone to '
          'continue.',
      child: OutlinedButton(
        onPressed: () =>
            context.read<SignInCubit>().selectMethod(SignInMethod.magicLink),
        child: const Text('Use a different email'),
      ),
    );
  }
}
