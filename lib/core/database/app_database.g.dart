// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalWorkoutsTable extends LocalWorkouts
    with TableInfo<$LocalWorkoutsTable, LocalWorkoutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityMeta = const VerificationMeta(
    'activity',
  );
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeDurationMsMeta = const VerificationMeta(
    'activeDurationMs',
  );
  @override
  late final GeneratedColumn<int> activeDurationMs = GeneratedColumn<int>(
    'active_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resumedAtMeta = const VerificationMeta(
    'resumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resumedAt = GeneratedColumn<DateTime>(
    'resumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<int> segment = GeneratedColumn<int>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevationGainMMeta = const VerificationMeta(
    'elevationGainM',
  );
  @override
  late final GeneratedColumn<double> elevationGainM = GeneratedColumn<double>(
    'elevation_gain_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxSpeedMpsMeta = const VerificationMeta(
    'maxSpeedMps',
  );
  @override
  late final GeneratedColumn<double> maxSpeedMps = GeneratedColumn<double>(
    'max_speed_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _splitsJsonMeta = const VerificationMeta(
    'splitsJson',
  );
  @override
  late final GeneratedColumn<String> splitsJson = GeneratedColumn<String>(
    'splits_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _previewJsonMeta = const VerificationMeta(
    'previewJson',
  );
  @override
  late final GeneratedColumn<String> previewJson = GeneratedColumn<String>(
    'preview_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activity,
    startedAt,
    endedAt,
    status,
    activeDurationMs,
    resumedAt,
    segment,
    distanceM,
    elevationGainM,
    maxSpeedMps,
    splitsJson,
    previewJson,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity')) {
      context.handle(
        _activityMeta,
        activity.isAcceptableOrUnknown(data['activity']!, _activityMeta),
      );
    } else if (isInserting) {
      context.missing(_activityMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('active_duration_ms')) {
      context.handle(
        _activeDurationMsMeta,
        activeDurationMs.isAcceptableOrUnknown(
          data['active_duration_ms']!,
          _activeDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('resumed_at')) {
      context.handle(
        _resumedAtMeta,
        resumedAt.isAcceptableOrUnknown(data['resumed_at']!, _resumedAtMeta),
      );
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
        _elevationGainMMeta,
        elevationGainM.isAcceptableOrUnknown(
          data['elevation_gain_m']!,
          _elevationGainMMeta,
        ),
      );
    }
    if (data.containsKey('max_speed_mps')) {
      context.handle(
        _maxSpeedMpsMeta,
        maxSpeedMps.isAcceptableOrUnknown(
          data['max_speed_mps']!,
          _maxSpeedMpsMeta,
        ),
      );
    }
    if (data.containsKey('splits_json')) {
      context.handle(
        _splitsJsonMeta,
        splitsJson.isAcceptableOrUnknown(data['splits_json']!, _splitsJsonMeta),
      );
    }
    if (data.containsKey('preview_json')) {
      context.handle(
        _previewJsonMeta,
        previewJson.isAcceptableOrUnknown(
          data['preview_json']!,
          _previewJsonMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWorkoutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      activeDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_duration_ms'],
      )!,
      resumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resumed_at'],
      ),
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      elevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_m'],
      )!,
      maxSpeedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed_mps'],
      )!,
      splitsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}splits_json'],
      )!,
      previewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_json'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LocalWorkoutsTable createAlias(String alias) {
    return $LocalWorkoutsTable(attachedDatabase, alias);
  }
}

class LocalWorkoutRow extends DataClass implements Insertable<LocalWorkoutRow> {
  /// UUID generated on the device, reused as the server id.
  final String id;
  final String activity;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// `recording`, `paused` or `finished`.
  final String status;
  final int activeDurationMs;
  final DateTime? resumedAt;
  final int segment;
  final double distanceM;
  final double elevationGainM;
  final double maxSpeedMps;

  /// JSON list of split durations in milliseconds.
  final String splitsJson;

  /// Simplified route (`[[lat, lng], ...]`) for history thumbnails, so the
  /// list never loads thousands of points. Added in schema version 2.
  final String previewJson;
  final bool synced;
  const LocalWorkoutRow({
    required this.id,
    required this.activity,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.activeDurationMs,
    this.resumedAt,
    required this.segment,
    required this.distanceM,
    required this.elevationGainM,
    required this.maxSpeedMps,
    required this.splitsJson,
    required this.previewJson,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity'] = Variable<String>(activity);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['status'] = Variable<String>(status);
    map['active_duration_ms'] = Variable<int>(activeDurationMs);
    if (!nullToAbsent || resumedAt != null) {
      map['resumed_at'] = Variable<DateTime>(resumedAt);
    }
    map['segment'] = Variable<int>(segment);
    map['distance_m'] = Variable<double>(distanceM);
    map['elevation_gain_m'] = Variable<double>(elevationGainM);
    map['max_speed_mps'] = Variable<double>(maxSpeedMps);
    map['splits_json'] = Variable<String>(splitsJson);
    map['preview_json'] = Variable<String>(previewJson);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutsCompanion(
      id: Value(id),
      activity: Value(activity),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      activeDurationMs: Value(activeDurationMs),
      resumedAt: resumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resumedAt),
      segment: Value(segment),
      distanceM: Value(distanceM),
      elevationGainM: Value(elevationGainM),
      maxSpeedMps: Value(maxSpeedMps),
      splitsJson: Value(splitsJson),
      previewJson: Value(previewJson),
      synced: Value(synced),
    );
  }

  factory LocalWorkoutRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutRow(
      id: serializer.fromJson<String>(json['id']),
      activity: serializer.fromJson<String>(json['activity']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      activeDurationMs: serializer.fromJson<int>(json['activeDurationMs']),
      resumedAt: serializer.fromJson<DateTime?>(json['resumedAt']),
      segment: serializer.fromJson<int>(json['segment']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      elevationGainM: serializer.fromJson<double>(json['elevationGainM']),
      maxSpeedMps: serializer.fromJson<double>(json['maxSpeedMps']),
      splitsJson: serializer.fromJson<String>(json['splitsJson']),
      previewJson: serializer.fromJson<String>(json['previewJson']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activity': serializer.toJson<String>(activity),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(status),
      'activeDurationMs': serializer.toJson<int>(activeDurationMs),
      'resumedAt': serializer.toJson<DateTime?>(resumedAt),
      'segment': serializer.toJson<int>(segment),
      'distanceM': serializer.toJson<double>(distanceM),
      'elevationGainM': serializer.toJson<double>(elevationGainM),
      'maxSpeedMps': serializer.toJson<double>(maxSpeedMps),
      'splitsJson': serializer.toJson<String>(splitsJson),
      'previewJson': serializer.toJson<String>(previewJson),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalWorkoutRow copyWith({
    String? id,
    String? activity,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? status,
    int? activeDurationMs,
    Value<DateTime?> resumedAt = const Value.absent(),
    int? segment,
    double? distanceM,
    double? elevationGainM,
    double? maxSpeedMps,
    String? splitsJson,
    String? previewJson,
    bool? synced,
  }) => LocalWorkoutRow(
    id: id ?? this.id,
    activity: activity ?? this.activity,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    activeDurationMs: activeDurationMs ?? this.activeDurationMs,
    resumedAt: resumedAt.present ? resumedAt.value : this.resumedAt,
    segment: segment ?? this.segment,
    distanceM: distanceM ?? this.distanceM,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
    splitsJson: splitsJson ?? this.splitsJson,
    previewJson: previewJson ?? this.previewJson,
    synced: synced ?? this.synced,
  );
  LocalWorkoutRow copyWithCompanion(LocalWorkoutsCompanion data) {
    return LocalWorkoutRow(
      id: data.id.present ? data.id.value : this.id,
      activity: data.activity.present ? data.activity.value : this.activity,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      activeDurationMs: data.activeDurationMs.present
          ? data.activeDurationMs.value
          : this.activeDurationMs,
      resumedAt: data.resumedAt.present ? data.resumedAt.value : this.resumedAt,
      segment: data.segment.present ? data.segment.value : this.segment,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
      maxSpeedMps: data.maxSpeedMps.present
          ? data.maxSpeedMps.value
          : this.maxSpeedMps,
      splitsJson: data.splitsJson.present
          ? data.splitsJson.value
          : this.splitsJson,
      previewJson: data.previewJson.present
          ? data.previewJson.value
          : this.previewJson,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutRow(')
          ..write('id: $id, ')
          ..write('activity: $activity, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('activeDurationMs: $activeDurationMs, ')
          ..write('resumedAt: $resumedAt, ')
          ..write('segment: $segment, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('splitsJson: $splitsJson, ')
          ..write('previewJson: $previewJson, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activity,
    startedAt,
    endedAt,
    status,
    activeDurationMs,
    resumedAt,
    segment,
    distanceM,
    elevationGainM,
    maxSpeedMps,
    splitsJson,
    previewJson,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutRow &&
          other.id == this.id &&
          other.activity == this.activity &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.activeDurationMs == this.activeDurationMs &&
          other.resumedAt == this.resumedAt &&
          other.segment == this.segment &&
          other.distanceM == this.distanceM &&
          other.elevationGainM == this.elevationGainM &&
          other.maxSpeedMps == this.maxSpeedMps &&
          other.splitsJson == this.splitsJson &&
          other.previewJson == this.previewJson &&
          other.synced == this.synced);
}

class LocalWorkoutsCompanion extends UpdateCompanion<LocalWorkoutRow> {
  final Value<String> id;
  final Value<String> activity;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> status;
  final Value<int> activeDurationMs;
  final Value<DateTime?> resumedAt;
  final Value<int> segment;
  final Value<double> distanceM;
  final Value<double> elevationGainM;
  final Value<double> maxSpeedMps;
  final Value<String> splitsJson;
  final Value<String> previewJson;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalWorkoutsCompanion({
    this.id = const Value.absent(),
    this.activity = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.activeDurationMs = const Value.absent(),
    this.resumedAt = const Value.absent(),
    this.segment = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.splitsJson = const Value.absent(),
    this.previewJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutsCompanion.insert({
    required String id,
    required String activity,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String status,
    this.activeDurationMs = const Value.absent(),
    this.resumedAt = const Value.absent(),
    this.segment = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.maxSpeedMps = const Value.absent(),
    this.splitsJson = const Value.absent(),
    this.previewJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activity = Value(activity),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<LocalWorkoutRow> custom({
    Expression<String>? id,
    Expression<String>? activity,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<int>? activeDurationMs,
    Expression<DateTime>? resumedAt,
    Expression<int>? segment,
    Expression<double>? distanceM,
    Expression<double>? elevationGainM,
    Expression<double>? maxSpeedMps,
    Expression<String>? splitsJson,
    Expression<String>? previewJson,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activity != null) 'activity': activity,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (activeDurationMs != null) 'active_duration_ms': activeDurationMs,
      if (resumedAt != null) 'resumed_at': resumedAt,
      if (segment != null) 'segment': segment,
      if (distanceM != null) 'distance_m': distanceM,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
      if (maxSpeedMps != null) 'max_speed_mps': maxSpeedMps,
      if (splitsJson != null) 'splits_json': splitsJson,
      if (previewJson != null) 'preview_json': previewJson,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? activity,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? status,
    Value<int>? activeDurationMs,
    Value<DateTime?>? resumedAt,
    Value<int>? segment,
    Value<double>? distanceM,
    Value<double>? elevationGainM,
    Value<double>? maxSpeedMps,
    Value<String>? splitsJson,
    Value<String>? previewJson,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LocalWorkoutsCompanion(
      id: id ?? this.id,
      activity: activity ?? this.activity,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      activeDurationMs: activeDurationMs ?? this.activeDurationMs,
      resumedAt: resumedAt ?? this.resumedAt,
      segment: segment ?? this.segment,
      distanceM: distanceM ?? this.distanceM,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      splitsJson: splitsJson ?? this.splitsJson,
      previewJson: previewJson ?? this.previewJson,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (activeDurationMs.present) {
      map['active_duration_ms'] = Variable<int>(activeDurationMs.value);
    }
    if (resumedAt.present) {
      map['resumed_at'] = Variable<DateTime>(resumedAt.value);
    }
    if (segment.present) {
      map['segment'] = Variable<int>(segment.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (elevationGainM.present) {
      map['elevation_gain_m'] = Variable<double>(elevationGainM.value);
    }
    if (maxSpeedMps.present) {
      map['max_speed_mps'] = Variable<double>(maxSpeedMps.value);
    }
    if (splitsJson.present) {
      map['splits_json'] = Variable<String>(splitsJson.value);
    }
    if (previewJson.present) {
      map['preview_json'] = Variable<String>(previewJson.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('activity: $activity, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('activeDurationMs: $activeDurationMs, ')
          ..write('resumedAt: $resumedAt, ')
          ..write('segment: $segment, ')
          ..write('distanceM: $distanceM, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('maxSpeedMps: $maxSpeedMps, ')
          ..write('splitsJson: $splitsJson, ')
          ..write('previewJson: $previewJson, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTrackPointsTable extends LocalTrackPoints
    with TableInfo<$LocalTrackPointsTable, LocalTrackPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<int> segment = GeneratedColumn<int>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    segment,
    lat,
    lng,
    accuracyM,
    altitudeM,
    speedMps,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrackPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrackPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrackPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $LocalTrackPointsTable createAlias(String alias) {
    return $LocalTrackPointsTable(attachedDatabase, alias);
  }
}

class LocalTrackPointRow extends DataClass
    implements Insertable<LocalTrackPointRow> {
  final int id;
  final String workoutId;
  final int segment;
  final double lat;
  final double lng;
  final double accuracyM;
  final double? altitudeM;
  final double? speedMps;
  final DateTime recordedAt;
  const LocalTrackPointRow({
    required this.id,
    required this.workoutId,
    required this.segment,
    required this.lat,
    required this.lng,
    required this.accuracyM,
    this.altitudeM,
    this.speedMps,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['segment'] = Variable<int>(segment);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['accuracy_m'] = Variable<double>(accuracyM);
    if (!nullToAbsent || altitudeM != null) {
      map['altitude_m'] = Variable<double>(altitudeM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  LocalTrackPointsCompanion toCompanion(bool nullToAbsent) {
    return LocalTrackPointsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      segment: Value(segment),
      lat: Value(lat),
      lng: Value(lng),
      accuracyM: Value(accuracyM),
      altitudeM: altitudeM == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      recordedAt: Value(recordedAt),
    );
  }

  factory LocalTrackPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrackPointRow(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      segment: serializer.fromJson<int>(json['segment']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      accuracyM: serializer.fromJson<double>(json['accuracyM']),
      altitudeM: serializer.fromJson<double?>(json['altitudeM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'segment': serializer.toJson<int>(segment),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'accuracyM': serializer.toJson<double>(accuracyM),
      'altitudeM': serializer.toJson<double?>(altitudeM),
      'speedMps': serializer.toJson<double?>(speedMps),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  LocalTrackPointRow copyWith({
    int? id,
    String? workoutId,
    int? segment,
    double? lat,
    double? lng,
    double? accuracyM,
    Value<double?> altitudeM = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    DateTime? recordedAt,
  }) => LocalTrackPointRow(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    segment: segment ?? this.segment,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    accuracyM: accuracyM ?? this.accuracyM,
    altitudeM: altitudeM.present ? altitudeM.value : this.altitudeM,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  LocalTrackPointRow copyWithCompanion(LocalTrackPointsCompanion data) {
    return LocalTrackPointRow(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      segment: data.segment.present ? data.segment.value : this.segment,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrackPointRow(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('segment: $segment, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    segment,
    lat,
    lng,
    accuracyM,
    altitudeM,
    speedMps,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrackPointRow &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.segment == this.segment &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.accuracyM == this.accuracyM &&
          other.altitudeM == this.altitudeM &&
          other.speedMps == this.speedMps &&
          other.recordedAt == this.recordedAt);
}

class LocalTrackPointsCompanion extends UpdateCompanion<LocalTrackPointRow> {
  final Value<int> id;
  final Value<String> workoutId;
  final Value<int> segment;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> accuracyM;
  final Value<double?> altitudeM;
  final Value<double?> speedMps;
  final Value<DateTime> recordedAt;
  const LocalTrackPointsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.segment = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  LocalTrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required String workoutId,
    required int segment,
    required double lat,
    required double lng,
    required double accuracyM,
    this.altitudeM = const Value.absent(),
    this.speedMps = const Value.absent(),
    required DateTime recordedAt,
  }) : workoutId = Value(workoutId),
       segment = Value(segment),
       lat = Value(lat),
       lng = Value(lng),
       accuracyM = Value(accuracyM),
       recordedAt = Value(recordedAt);
  static Insertable<LocalTrackPointRow> custom({
    Expression<int>? id,
    Expression<String>? workoutId,
    Expression<int>? segment,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? accuracyM,
    Expression<double>? altitudeM,
    Expression<double>? speedMps,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (segment != null) 'segment': segment,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  LocalTrackPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? workoutId,
    Value<int>? segment,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? accuracyM,
    Value<double?>? altitudeM,
    Value<double?>? speedMps,
    Value<DateTime>? recordedAt,
  }) {
    return LocalTrackPointsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      segment: segment ?? this.segment,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      altitudeM: altitudeM ?? this.altitudeM,
      speedMps: speedMps ?? this.speedMps,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (segment.present) {
      map['segment'] = Variable<int>(segment.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('segment: $segment, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalWorkoutsTable localWorkouts = $LocalWorkoutsTable(this);
  late final $LocalTrackPointsTable localTrackPoints = $LocalTrackPointsTable(
    this,
  );
  late final Index trackPointsWorkoutIdx = Index(
    'track_points_workout_idx',
    'CREATE INDEX track_points_workout_idx ON track_points (workout_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localWorkouts,
    localTrackPoints,
    trackPointsWorkoutIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_points', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LocalWorkoutsTableCreateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      required String id,
      required String activity,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String status,
      Value<int> activeDurationMs,
      Value<DateTime?> resumedAt,
      Value<int> segment,
      Value<double> distanceM,
      Value<double> elevationGainM,
      Value<double> maxSpeedMps,
      Value<String> splitsJson,
      Value<String> previewJson,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LocalWorkoutsTableUpdateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      Value<String> id,
      Value<String> activity,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> status,
      Value<int> activeDurationMs,
      Value<DateTime?> resumedAt,
      Value<int> segment,
      Value<double> distanceM,
      Value<double> elevationGainM,
      Value<double> maxSpeedMps,
      Value<String> splitsJson,
      Value<String> previewJson,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$LocalWorkoutsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LocalWorkoutsTable, LocalWorkoutRow> {
  $$LocalWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalTrackPointsTable, List<LocalTrackPointRow>>
  _localTrackPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localTrackPoints,
    aliasName: 'workouts__id__track_points__workout_id',
  );

  $$LocalTrackPointsTableProcessedTableManager get localTrackPointsRefs {
    final manager = $$LocalTrackPointsTableTableManager(
      $_db,
      $_db.localTrackPoints,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localTrackPointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeDurationMs => $composableBuilder(
    column: $table.activeDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resumedAt => $composableBuilder(
    column: $table.resumedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewJson => $composableBuilder(
    column: $table.previewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localTrackPointsRefs(
    Expression<bool> Function($$LocalTrackPointsTableFilterComposer f) f,
  ) {
    final $$LocalTrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTrackPoints,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.localTrackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeDurationMs => $composableBuilder(
    column: $table.activeDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resumedAt => $composableBuilder(
    column: $table.resumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewJson => $composableBuilder(
    column: $table.previewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get activeDurationMs => $composableBuilder(
    column: $table.activeDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resumedAt =>
      $composableBuilder(column: $table.resumedAt, builder: (column) => column);

  GeneratedColumn<int> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSpeedMps => $composableBuilder(
    column: $table.maxSpeedMps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewJson => $composableBuilder(
    column: $table.previewJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  Expression<T> localTrackPointsRefs<T extends Object>(
    Expression<T> Function($$LocalTrackPointsTableAnnotationComposer a) f,
  ) {
    final $$LocalTrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTrackPoints,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.localTrackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWorkoutsTable,
          LocalWorkoutRow,
          $$LocalWorkoutsTableFilterComposer,
          $$LocalWorkoutsTableOrderingComposer,
          $$LocalWorkoutsTableAnnotationComposer,
          $$LocalWorkoutsTableCreateCompanionBuilder,
          $$LocalWorkoutsTableUpdateCompanionBuilder,
          (LocalWorkoutRow, $$LocalWorkoutsTableReferences),
          LocalWorkoutRow,
          PrefetchHooks Function({bool localTrackPointsRefs})
        > {
  $$LocalWorkoutsTableTableManager(_$AppDatabase db, $LocalWorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> activeDurationMs = const Value.absent(),
                Value<DateTime?> resumedAt = const Value.absent(),
                Value<int> segment = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
                Value<double> maxSpeedMps = const Value.absent(),
                Value<String> splitsJson = const Value.absent(),
                Value<String> previewJson = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion(
                id: id,
                activity: activity,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                activeDurationMs: activeDurationMs,
                resumedAt: resumedAt,
                segment: segment,
                distanceM: distanceM,
                elevationGainM: elevationGainM,
                maxSpeedMps: maxSpeedMps,
                splitsJson: splitsJson,
                previewJson: previewJson,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String activity,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String status,
                Value<int> activeDurationMs = const Value.absent(),
                Value<DateTime?> resumedAt = const Value.absent(),
                Value<int> segment = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
                Value<double> maxSpeedMps = const Value.absent(),
                Value<String> splitsJson = const Value.absent(),
                Value<String> previewJson = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion.insert(
                id: id,
                activity: activity,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                activeDurationMs: activeDurationMs,
                resumedAt: resumedAt,
                segment: segment,
                distanceM: distanceM,
                elevationGainM: elevationGainM,
                maxSpeedMps: maxSpeedMps,
                splitsJson: splitsJson,
                previewJson: previewJson,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalWorkoutsTable, LocalWorkoutRow>(table),
                  $$LocalWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localTrackPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localTrackPointsRefs) db.localTrackPoints,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localTrackPointsRefs)
                    await $_getPrefetchedData<
                      LocalWorkoutRow,
                      $LocalWorkoutsTable,
                      LocalTrackPointRow
                    >(
                      currentTable: table,
                      referencedTable: $$LocalWorkoutsTableReferences
                          ._localTrackPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalWorkoutsTableReferences(
                            db,
                            table,
                            p0,
                          ).localTrackPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.workoutId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWorkoutsTable,
      LocalWorkoutRow,
      $$LocalWorkoutsTableFilterComposer,
      $$LocalWorkoutsTableOrderingComposer,
      $$LocalWorkoutsTableAnnotationComposer,
      $$LocalWorkoutsTableCreateCompanionBuilder,
      $$LocalWorkoutsTableUpdateCompanionBuilder,
      (LocalWorkoutRow, $$LocalWorkoutsTableReferences),
      LocalWorkoutRow,
      PrefetchHooks Function({bool localTrackPointsRefs})
    >;
typedef $$LocalTrackPointsTableCreateCompanionBuilder =
    LocalTrackPointsCompanion Function({
      Value<int> id,
      required String workoutId,
      required int segment,
      required double lat,
      required double lng,
      required double accuracyM,
      Value<double?> altitudeM,
      Value<double?> speedMps,
      required DateTime recordedAt,
    });
typedef $$LocalTrackPointsTableUpdateCompanionBuilder =
    LocalTrackPointsCompanion Function({
      Value<int> id,
      Value<String> workoutId,
      Value<int> segment,
      Value<double> lat,
      Value<double> lng,
      Value<double> accuracyM,
      Value<double?> altitudeM,
      Value<double?> speedMps,
      Value<DateTime> recordedAt,
    });

final class $$LocalTrackPointsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalTrackPointsTable,
          LocalTrackPointRow
        > {
  $$LocalTrackPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.localWorkouts.createAlias('track_points__workout_id__workouts__id');

  $$LocalWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$LocalWorkoutsTableTableManager(
      $_db,
      $_db.localWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalTrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutsTableFilterComposer get workoutId {
    final $$LocalWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutsTableOrderingComposer get workoutId {
    final $$LocalWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$LocalWorkoutsTableAnnotationComposer get workoutId {
    final $$LocalWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.localWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTrackPointsTable,
          LocalTrackPointRow,
          $$LocalTrackPointsTableFilterComposer,
          $$LocalTrackPointsTableOrderingComposer,
          $$LocalTrackPointsTableAnnotationComposer,
          $$LocalTrackPointsTableCreateCompanionBuilder,
          $$LocalTrackPointsTableUpdateCompanionBuilder,
          (LocalTrackPointRow, $$LocalTrackPointsTableReferences),
          LocalTrackPointRow,
          PrefetchHooks Function({bool workoutId})
        > {
  $$LocalTrackPointsTableTableManager(
    _$AppDatabase db,
    $LocalTrackPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<int> segment = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => LocalTrackPointsCompanion(
                id: id,
                workoutId: workoutId,
                segment: segment,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
                speedMps: speedMps,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workoutId,
                required int segment,
                required double lat,
                required double lng,
                required double accuracyM,
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                required DateTime recordedAt,
              }) => LocalTrackPointsCompanion.insert(
                id: id,
                workoutId: workoutId,
                segment: segment,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
                speedMps: speedMps,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTrackPointsTable, LocalTrackPointRow>(
                    table,
                  ),
                  $$LocalTrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workoutId,
                        referencedTable: $$LocalTrackPointsTableReferences
                            ._workoutIdTable(db),
                        referencedColumn: $$LocalTrackPointsTableReferences
                            ._workoutIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalTrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTrackPointsTable,
      LocalTrackPointRow,
      $$LocalTrackPointsTableFilterComposer,
      $$LocalTrackPointsTableOrderingComposer,
      $$LocalTrackPointsTableAnnotationComposer,
      $$LocalTrackPointsTableCreateCompanionBuilder,
      $$LocalTrackPointsTableUpdateCompanionBuilder,
      (LocalTrackPointRow, $$LocalTrackPointsTableReferences),
      LocalTrackPointRow,
      PrefetchHooks Function({bool workoutId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalWorkoutsTableTableManager get localWorkouts =>
      $$LocalWorkoutsTableTableManager(_db, _db.localWorkouts);
  $$LocalTrackPointsTableTableManager get localTrackPoints =>
      $$LocalTrackPointsTableTableManager(_db, _db.localTrackPoints);
}
