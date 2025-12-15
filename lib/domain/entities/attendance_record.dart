import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.date,
    this.id,
    this.userEmail,
    this.userEmployeeNumber,
    this.userPhoto,
    this.firstCheckIn,
    this.lastCheckOut,
    this.totalHours,
    this.workedHours,
    this.missingHours,
    this.overtimeHours,
    this.overtimeAmountIqd,
    this.status,
    this.isLocked,
  });

  final int? id;
  final int userId;
  final String userName;
  final String? userEmail;
  final String? userEmployeeNumber;
  final String? userPhoto;
  final String date;
  final String? firstCheckIn;
  final String? lastCheckOut;
  final double? totalHours;
  final double? workedHours;
  final double? missingHours;
  final double? overtimeHours;
  final int? overtimeAmountIqd;
  final String? status;
  final bool? isLocked;

  @override
  List<Object?> get props => <Object?>[
        id,
        userId,
        userName,
        date,
        firstCheckIn,
        lastCheckOut,
        totalHours,
        workedHours,
        missingHours,
        overtimeHours,
        overtimeAmountIqd,
        status,
        isLocked,
        userPhoto,
      ];
}




