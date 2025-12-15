import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeNumber,
    this.isActive = true,
    this.photo,
    this.phoneNumber,
    this.accountNumber,
    this.walletNumber,
    this.idPicFront,
    this.idPicBack,
    this.residentialIdFront,
    this.residentialIdBack,
    this.weekendDays = const <String>[],
    this.onlineAttendanceMode,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? employeeNumber;
  final bool isActive;
  final String? photo;
  final String? phoneNumber;
  final String? accountNumber;
  final String? walletNumber;
  final String? idPicFront;
  final String? idPicBack;
  final String? residentialIdFront;
  final String? residentialIdBack;
  final List<String> weekendDays;
  final String? onlineAttendanceMode;

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isEmployee => role == 'employee';

  @override
  List<Object?> get props => <Object?>[
        id,
        email,
        role,
        employeeNumber,
        isActive,
        photo,
        phoneNumber,
        accountNumber,
        walletNumber,
        idPicFront,
        idPicBack,
        residentialIdFront,
        residentialIdBack,
        weekendDays,
        onlineAttendanceMode,
      ];
}




