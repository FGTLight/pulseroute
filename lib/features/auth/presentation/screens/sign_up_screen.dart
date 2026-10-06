import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/activity_selector.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/sign_up_cubit.dart';
import '../widgets/auth_scaffold.dart';

/// Account creation. Expects a [SignUpCubit] above it.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<SignUpCubit>().submit(
        displayName: _name.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FormStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.outcome == SignUpOutcome.confirmEmail) {
          return AuthScaffold(
            title: 'Confirm your email',
            subtitle:
                'We sent a confirmation link to ${_email.text.trim()}. '
                'Open it, then sign in.',
            child: FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Back to sign in'),
            ),
          );
        }

        return AuthScaffold(
          title: 'Create your account',
          subtitle: 'Map your workouts and help others stay safe.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('nameField'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  maxLength: Validators.maxDisplayNameLength,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    counterText: '',
                  ),
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('emailField'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('passwordField'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'At least ${Validators.minPasswordLength} characters',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                Text(
                  'I mostly…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ActivitySelector(
                  value: state.activity,
                  onChanged: context.read<SignUpCubit>().selectActivity,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('signUpButton'),
                  onPressed: state.status.isSubmitting ? null : _submit,
                  child: state.status.isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
