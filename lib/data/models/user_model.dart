import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.employeeNumber,
    super.isActive = true,
    super.photo,
    super.phoneNumber,
    super.accountNumber,
    super.walletNumber,
    super.idPicFront,
    super.idPicBack,
    super.residentialIdFront,
    super.residentialIdBack,
    super.weekendDays = const <String>[],
    super.onlineAttendanceMode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle photo field - check multiple possible field names
    String? photoValue;
    
    print('🔍 UserModel.fromJson - checking photo fields...');
    print('🔍 json keys: ${json.keys.toList()}');
    print('🔍 json[\'profile_picture\']: ${json['profile_picture']} (type: ${json['profile_picture'].runtimeType})');
    print('🔍 json[\'photo\']: ${json['photo']} (type: ${json['photo'].runtimeType})');
    
    // Check profile_picture first (API uses this)
    if (json['profile_picture'] != null) {
      final dynamic photoData = json['profile_picture'];
      print('🔍 Found profile_picture: $photoData');
      if (photoData is String && photoData.isNotEmpty && photoData != 'null') {
        photoValue = photoData;
        print('✅ Using profile_picture as String: $photoValue');
      } else if (photoData != null) {
        photoValue = photoData.toString();
        print('✅ Using profile_picture as toString: $photoValue');
      }
    }
    
    // Fallback to photo field if profile_picture not found
    if ((photoValue == null || photoValue.isEmpty || photoValue == 'null') && json['photo'] != null) {
      final dynamic photoData = json['photo'];
      print('🔍 Found photo: $photoData');
      if (photoData is String && photoData.isNotEmpty && photoData != 'null') {
        photoValue = photoData;
        print('✅ Using photo as String: $photoValue');
      } else if (photoData != null) {
        photoValue = photoData.toString();
        print('✅ Using photo as toString: $photoValue');
      }
    }
    
    print('🔍 Final photoValue: $photoValue');
    
    // Parse weekend days
    List<String> weekendDaysList = <String>[];
    if (json['weekend_days'] != null) {
      if (json['weekend_days'] is List) {
        weekendDaysList = List<String>.from(
          (json['weekend_days'] as List).map((dynamic e) => e.toString()),
        );
      }
    }
    
    return UserModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        employeeNumber: json['employee_number']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
      photo: photoValue,
      phoneNumber: json['phone_number']?.toString(),
      accountNumber: json['account_number']?.toString(),
      walletNumber: json['wallet_number']?.toString(),
      idPicFront: json['id_pic_front']?.toString(),
      idPicBack: json['id_pic_back']?.toString(),
      residentialIdFront: json['residential_id_front']?.toString(),
      residentialIdBack: json['residential_id_back']?.toString(),
      weekendDays: weekendDaysList,
      onlineAttendanceMode: json['online_attendance_mode']?.toString(),
      );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'employee_number': employeeNumber,
        'is_active': isActive,
        'photo': photo,
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'wallet_number': walletNumber,
        'id_pic_front': idPicFront,
        'id_pic_back': idPicBack,
        'residential_id_front': residentialIdFront,
        'residential_id_back': residentialIdBack,
        'weekend_days': weekendDays,
        'online_attendance_mode': onlineAttendanceMode,
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? employeeNumber,
    bool? isActive,
    String? photo,
    String? phoneNumber,
    String? accountNumber,
    String? walletNumber,
    String? idPicFront,
    String? idPicBack,
    String? residentialIdFront,
    String? residentialIdBack,
    List<String>? weekendDays,
    String? onlineAttendanceMode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      isActive: isActive ?? this.isActive,
      photo: photo ?? this.photo,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      walletNumber: walletNumber ?? this.walletNumber,
      idPicFront: idPicFront ?? this.idPicFront,
      idPicBack: idPicBack ?? this.idPicBack,
      residentialIdFront: residentialIdFront ?? this.residentialIdFront,
      residentialIdBack: residentialIdBack ?? this.residentialIdBack,
      weekendDays: weekendDays ?? this.weekendDays,
      onlineAttendanceMode: onlineAttendanceMode ?? this.onlineAttendanceMode,
    );
  }
}




