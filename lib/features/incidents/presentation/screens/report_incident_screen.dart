import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_draft.dart';
import '../cubit/report_incident_cubit.dart';
import '../incident_style.dart';

/// Form to report an incident at a location. Pops with the created
/// [Incident]. Expects a [ReportIncidentCubit] above it.
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<ReportIncidentCubit>().submit(
        description: _description.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportIncidentCubit, ReportIncidentState>(
      listenWhen: (a, b) =>
          a.status != b.status || a.errorMessage != b.errorMessage,
      listener: (context, state) {
        if (state.status == FormStatus.success && state.created != null) {
          Navigator.pop(context, state.created);
        } else if (state.errorMessage case final message?) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<ReportIncidentCubit>();
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Report an incident')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'At ${state.location.lat.toStringAsFixed(5)}, '
                  '${state.location.lng.toStringAsFixed(5)}',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text('What is the problem?', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in IncidentCategory.values)
                      ChoiceChip(
                        key: Key('category-${c.name}'),
                        avatar: Icon(
                          c.icon,
                          color: state.category == c ? null : c.color,
                        ),
                        label: Text(c.label),
                        selected: state.category == c,
                        onSelected: (_) => cubit.selectCategory(c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('How dangerous is it?', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<IncidentSeverity>(
                  segments: [
                    for (final s in IncidentSeverity.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: {state.severity},
                  onSelectionChanged: (s) => cubit.selectSeverity(s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('descriptionField'),
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: IncidentDraft.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'E.g. "No street lights for 200 m after 8 pm"',
                  ),
                  validator: (v) =>
                      (v?.trim().length ?? 0) >
                          IncidentDraft.maxDescriptionLength
                      ? 'Too long'
                      : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('areaSwitch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Affects an area'),
                  subtitle: const Text('E.g. a dark park or a closed block'),
                  value: state.isArea,
                  onChanged: (v) => cubit.setArea(enabled: v),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: state.isArea
                      ? Row(
                          children: [
                            Expanded(
                              child: Slider(
                                key: const Key('radiusSlider'),
                                value: state.radiusM!.toDouble(),
                                min: IncidentDraft.minRadiusM.toDouble(),
                                max: IncidentDraft.maxRadiusM.toDouble(),
                                divisions: 19,
                                label: '${state.radiusM} m',
                                onChanged: (v) => cubit.setRadius(v.round()),
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text('${state.radiusM} m'),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),
                _PhotoPicker(state: state),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('submitReport'),
                  onPressed: state.status.isSubmitting ? null : _submit,
                  icon: state.status.isSubmitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Report'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.state});

  final ReportIncidentState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportIncidentCubit>();
    final photo = state.photo;

    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              photo,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: cubit.removePhoto,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.pickingPhoto
                ? null
                : () => cubit.pickPhoto(fromCamera: true),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.pickingPhoto
                ? null
                : () => cubit.pickPhoto(fromCamera: false),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }
}
