import '../repositories/attendance_repository.dart';

class OnlineCheckInUseCase {
  OnlineCheckInUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required double latitude,
    required double longitude,
  }) => _repository.onlineCheckIn(
        latitude: latitude,
        longitude: longitude,
      );
}

