import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulseroute/features/auth/domain/repositories/profile_repository.dart';
import 'package:pulseroute/features/settings/domain/settings_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository;

class MockProfileRepository extends Mock implements ProfileRepository;

class MockSettingsRepository extends Mock implements SettingsRepository;
