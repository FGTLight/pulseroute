import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/activity_selector.dart';

/// Edit display name and preferred activity. Expects a [ProfileCubit].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (a, b) => a.status != b.status,
        listener: (context, state) {
          final message = switch (state) {
            ProfileState(status: ProfileStatus.saved) => 'Profile saved',
            ProfileState(errorMessage: final error?) => error,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) => switch (state) {
          ProfileState(status: ProfileStatus.loading) => const LoadingView(),
          ProfileState(profile: final profile?) => _ProfileForm(
            profile: profile,
            saving: state.status == ProfileStatus.saving,
          ),
          _ => ErrorView(
            message: state.errorMessage ?? 'Could not load your profile.',
            onRetry: context.read<ProfileCubit>().load,
          ),
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.profile, required this.saving});

  final UserProfile profile;
  final bool saving;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.displayName);
  late ActivityType _activity = widget.profile.preferredActivity;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    unawaited(
      context.read<ProfileCubit>().save(
        displayName: _name.text,
        preferredActivity: _activity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: Validators.maxDisplayNameLength,
            decoration: const InputDecoration(
              labelText: 'Display name',
              counterText: '',
            ),
            validator: Validators.displayName,
          ),
          const SizedBox(height: 20),
          Text(
            'Preferred activity',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ActivitySelector(
            value: _activity,
            onChanged: (a) => setState(() => _activity = a),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: widget.saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
