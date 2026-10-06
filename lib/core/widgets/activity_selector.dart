import 'package:flutter/material.dart';

import '../domain/activity_type.dart';

/// Icon for each [ActivityType].
extension ActivityTypeIcon on ActivityType {
  IconData get icon => switch (this) {
    ActivityType.run => Icons.directions_run_rounded,
    ActivityType.bike => Icons.directions_bike_rounded,
  };
}

/// Run / ride toggle.
class ActivitySelector extends StatelessWidget {
  const ActivitySelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ActivityType value;
  final ValueChanged<ActivityType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ActivityType>(
        segments: [
          for (final a in ActivityType.values)
            ButtonSegment(value: a, label: Text(a.label), icon: Icon(a.icon)),
        ],
        selected: {value},
        onSelectionChanged: onChanged == null
            ? null
            : (s) => onChanged!(s.first),
      ),
    );
  }
}
