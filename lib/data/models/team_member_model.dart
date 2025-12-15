import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/team_member.dart';

part 'team_member_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.name,
    required super.email,
    required super.employeeNumber,
    required super.teamRole,
    super.photo,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pivot = json['pivot'] as Map<String, dynamic>? ?? <String, dynamic>{};
    
    // Check profile_picture first (API uses this)
    String? photoValue;
    if (json['profile_picture'] != null) {
      final dynamic photoData = json['profile_picture'];
      if (photoData is String && photoData.isNotEmpty && photoData != 'null') {
        photoValue = photoData;
      } else if (photoData != null) {
        photoValue = photoData.toString();
      }
    }
    
    // Fallback to photo field
    if ((photoValue == null || photoValue.isEmpty || photoValue == 'null') && json['photo'] != null) {
      final dynamic photoData = json['photo'];
      if (photoData is String && photoData.isNotEmpty && photoData != 'null') {
        photoValue = photoData;
      } else if (photoData != null) {
        photoValue = photoData.toString();
      }
    }
    
    return TeamMemberModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      employeeNumber: json['employee_number']?.toString() ?? '',
      teamRole: pivot['team_role'] as String? ?? 'employee',
      photo: photoValue,
    );
  }

  Map<String, dynamic> toJson() => _$TeamMemberModelToJson(this);
}

