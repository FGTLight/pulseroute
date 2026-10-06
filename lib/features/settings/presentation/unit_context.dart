import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/distance_unit.dart';
import 'cubit/settings_cubit.dart';

/// Shortcut for the distance unit chosen in Settings. Rebuilds the caller
/// when the unit changes.
extension UnitContext on BuildContext {
  DistanceUnit get distanceUnit =>
      select<SettingsCubit, DistanceUnit>((c) => c.state.unit);
}
