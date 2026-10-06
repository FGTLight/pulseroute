import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../domain/app_settings.dart';
import '../cubit/account_cubit.dart';
import '../cubit/settings_cubit.dart';

/// Profile, units, alerts, theme and account.
///
/// Expects [SettingsCubit] (app-wide) and [AccountCubit] above it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<AccountCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Delete your account?'),
        content: const Text(
          'Your profile, workouts, votes and photos will be permanently '
          'deleted. Incidents you reported stay on the map anonymously, so '
          'others stay safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final email = context.select<SessionBloc, String>(
      (bloc) => bloc.state.user?.email ?? '',
    );

    return BlocListener<AccountCubit, AccountState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!))),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profile'),
                subtitle: Text(email),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.profile),
              ),
            ),
            const _Section('Workouts'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _LabeledSegments<DistanceUnit>(
                  label: 'Units',
                  value: settings.unit,
                  options: const {
                    DistanceUnit.km: 'Kilometers',
                    DistanceUnit.mi: 'Miles',
                  },
                  onChanged: cubit.setUnit,
                ),
              ),
            ),
            const _Section('Safety alerts'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Alert me about incidents ahead'),
                    subtitle: const Text('Notification and vibration'),
                    value: settings.alertsEnabled,
                    onChanged: (v) => cubit.setAlertsEnabled(enabled: v),
                  ),
                  if (settings.alertsEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _LabeledSegments<int>(
                        label: 'Alert distance',
                        value: settings.alertRadiusM,
                        options: {
                          for (final m in AppSettings.alertRadiusOptions)
                            m: '$m m',
                        },
                        onChanged: cubit.setAlertRadius,
                      ),
                    ),
                ],
              ),
            ),
            const _Section('Appearance'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _LabeledSegments<ThemeMode>(
                  label: 'Theme',
                  value: settings.themeMode,
                  options: const {
                    ThemeMode.system: 'System',
                    ThemeMode.light: 'Light',
                    ThemeMode.dark: 'Dark',
                  },
                  onChanged: cubit.setThemeMode,
                ),
              ),
            ),
            const _Section('Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign out'),
                    onTap: () => context.read<SessionBloc>().add(
                      const SessionSignOutRequested(),
                    ),
                  ),
                  BlocBuilder<AccountCubit, AccountState>(
                    builder: (context, state) => ListTile(
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      trailing: state.status.isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: state.status.isSubmitting
                          ? null
                          : () => unawaited(_confirmDelete(context)),
                    ),
                  ),
                ],
              ),
            ),
            const _Section('About'),
            const Card(child: _AboutTile()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _LabeledSegments<T extends Object> extends StatelessWidget {
  const _LabeledSegments({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final MapEntry(:key, value: text) in options.entries)
                ButtonSegment(value: key, label: Text(text)),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.route_rounded),
          title: const Text('PulseRoute'),
          subtitle: Text(
            info == null
                ? 'Safer runs and rides'
                : 'Version ${info.version} (${info.buildNumber})',
          ),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'PulseRoute',
            applicationVersion: info?.version,
          ),
        );
      },
    );
  }
}
