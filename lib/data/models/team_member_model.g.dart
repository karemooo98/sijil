// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamMemberModel _$TeamMemberModelFromJson(Map<String, dynamic> json) =>
    TeamMemberModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      employeeNumber: json['employee_number'] as String,
      teamRole: json['team_role'] as String,
      photo: json['photo'] as String?,
    );

Map<String, dynamic> _$TeamMemberModelToJson(TeamMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'employee_number': instance.employeeNumber,
      'team_role': instance.teamRole,
      'photo': instance.photo,
    };
