import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/form_status.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_draft.dart';
import '../../domain/repositories/incident_repository.dart';
import '../../domain/usecases/incident_usecases.dart';

/// State of the report form. The description lives in a text controller and
/// is passed on submit.
final class ReportIncidentState extends Equatable {
  const ReportIncidentState({
    required this.location,
    this.category = IncidentCategory.pothole,
    this.severity = IncidentSeverity.medium,
    this.radiusM,
    this.photo,
    this.pickingPhoto = false,
    this.status = FormStatus.idle,
    this.created,
    this.errorMessage,
  });

  final GeoPoint location;
  final IncidentCategory category;
  final IncidentSeverity severity;

  /// `null` for a point report, otherwise the affected area radius.
  final int? radiusM;
  final Uint8List? photo;
  final bool pickingPhoto;
  final FormStatus status;
  final Incident? created;
  final String? errorMessage;

  bool get isArea => radiusM != null;

  ReportIncidentState copyWith({
    IncidentCategory? category,
    IncidentSeverity? severity,
    Object? radiusM = _keep,
    Object? photo = _keep,
    bool? pickingPhoto,
    FormStatus? status,
    Incident? created,
    String? errorMessage,
  }) {
    return ReportIncidentState(
      location: location,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      radiusM: identical(radiusM, _keep) ? this.radiusM : radiusM as int?,
      photo: identical(photo, _keep) ? this.photo : photo as Uint8List?,
      pickingPhoto: pickingPhoto ?? this.pickingPhoto,
      status: status ?? this.status,
      created: created ?? this.created,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    location,
    category,
    severity,
    radiusM,
    photo?.length,
    pickingPhoto,
    status,
    created,
    errorMessage,
  ];
}

const Object _keep = Object();

/// Business logic of the report form.
class ReportIncidentCubit extends Cubit<ReportIncidentState> {
  ReportIncidentCubit({
    required GeoPoint location,
    required ReportIncident reportIncident,
    required PhotoRepository photos,
  }) : _reportIncident = reportIncident,
       _photos = photos,
       super(
         ReportIncidentState(
           location: location,
           radiusM: IncidentCategory.pothole.defaultRadiusM,
         ),
       );

  final ReportIncident _reportIncident;
  final PhotoRepository _photos;

  /// Picking a category also applies its default shape (point or area).
  void selectCategory(IncidentCategory category) => emit(
    state.copyWith(category: category, radiusM: category.defaultRadiusM),
  );

  void selectSeverity(IncidentSeverity severity) =>
      emit(state.copyWith(severity: severity));

  void setArea({required bool enabled}) => emit(
    state.copyWith(
      radiusM: enabled ? (state.category.defaultRadiusM ?? 100) : null,
    ),
  );

  void setRadius(int meters) {
    if (state.isArea) {
      emit(
        state.copyWith(
          radiusM: meters.clamp(
            IncidentDraft.minRadiusM,
            IncidentDraft.maxRadiusM,
          ),
        ),
      );
    }
  }

  Future<void> pickPhoto({required bool fromCamera}) async {
    emit(state.copyWith(pickingPhoto: true));
    final result = await _photos.pick(fromCamera: fromCamera);
    result.fold(
      (bytes) => emit(
        state.copyWith(pickingPhoto: false, photo: bytes ?? state.photo),
      ),
      (f) => emit(state.copyWith(pickingPhoto: false, errorMessage: f.message)),
    );
  }

  void removePhoto() => emit(state.copyWith(photo: null));

  Future<void> submit({required String description}) async {
    if (state.status.isSubmitting) return;
    emit(state.copyWith(status: FormStatus.submitting));

    final result = await _reportIncident(
      IncidentDraft(
        category: state.category,
        severity: state.severity,
        location: state.location,
        description: description,
        radiusM: state.radiusM,
        photo: state.photo,
      ),
    );
    emit(
      result.fold(
        (incident) =>
            state.copyWith(status: FormStatus.success, created: incident),
        (f) =>
            state.copyWith(status: FormStatus.failure, errorMessage: f.message),
      ),
    );
  }
}
