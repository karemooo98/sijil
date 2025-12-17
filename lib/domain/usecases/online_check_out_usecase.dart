import '../repositories/attendance_repository.dart';

class OnlineCheckOutUseCase {
  OnlineCheckOutUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required double latitude,
    required double longitude,
  }) => _repository.onlineCheckOut(
        latitude: latitude,
        longitude: longitude,
      );
}

