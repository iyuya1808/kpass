// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthStateModel _$AuthStateModelFromJson(Map<String, dynamic> json) =>
    AuthStateModel(
      status: $enumDecode(_$AuthStatusEnumMap, json['status']),
      userModel: AuthStateModel._userFromJson(
        json['user'] as Map<String, dynamic>?,
      ),
      token: json['token'] as String?,
      errorMessage: json['errorMessage'] as String?,
      tokenExpiresAt:
          json['tokenExpiresAt'] == null
              ? null
              : DateTime.parse(json['tokenExpiresAt'] as String),
      isInitializing: json['isInitializing'] as bool? ?? false,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AuthStateModelToJson(AuthStateModel instance) =>
    <String, dynamic>{
      'status': _$AuthStatusEnumMap[instance.status]!,
      'token': instance.token,
      'errorMessage': instance.errorMessage,
      'tokenExpiresAt': instance.tokenExpiresAt?.toIso8601String(),
      'isInitializing': instance.isInitializing,
      'additionalData': instance.additionalData,
      'user': AuthStateModel._userToJson(instance.userModel),
    };

const _$AuthStatusEnumMap = {
  AuthStatus.initial: 'initial',
  AuthStatus.authenticated: 'authenticated',
  AuthStatus.unauthenticated: 'unauthenticated',
  AuthStatus.authenticating: 'authenticating',
  AuthStatus.failed: 'failed',
  AuthStatus.tokenExpired: 'tokenExpired',
};
