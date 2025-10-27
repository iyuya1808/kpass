import 'package:json_annotation/json_annotation.dart';
import 'package:kpass/features/auth/domain/entities/auth_state.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';
import 'package:kpass/features/auth/data/models/user_model.dart';

part 'auth_state_model.g.dart';

@JsonSerializable()
class AuthStateModel extends AuthState {
  @JsonKey(name: 'user', fromJson: _userFromJson, toJson: _userToJson)
  final UserModel? userModel;

  const AuthStateModel({
    required super.status,
    this.userModel,
    super.token,
    super.errorMessage,
    super.tokenExpiresAt,
    super.isInitializing,
    super.additionalData,
  }) : super(user: userModel);

  static UserModel? _userFromJson(Map<String, dynamic>? json) {
    return json != null ? UserModel.fromJson(json) : null;
  }

  static Map<String, dynamic>? _userToJson(UserModel? user) {
    return user?.toJson();
  }

  factory AuthStateModel.fromJson(Map<String, dynamic> json) =>
      _$AuthStateModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthStateModelToJson(this);

  /// Convert from domain entity
  factory AuthStateModel.fromEntity(AuthState authState) {
    return AuthStateModel(
      status: authState.status,
      userModel:
          authState.user != null ? UserModel.fromEntity(authState.user!) : null,
      token: authState.token,
      errorMessage: authState.errorMessage,
      tokenExpiresAt: authState.tokenExpiresAt,
      isInitializing: authState.isInitializing,
      additionalData: authState.additionalData,
    );
  }

  /// Convert to domain entity
  AuthState toEntity() {
    return AuthState(
      status: status,
      user: userModel?.toEntity(),
      token: token,
      errorMessage: errorMessage,
      tokenExpiresAt: tokenExpiresAt,
      isInitializing: isInitializing,
      additionalData: additionalData,
    );
  }

  /// Create authenticated state model
  factory AuthStateModel.authenticated({
    required UserModel user,
    required String token,
    DateTime? tokenExpiresAt,
  }) {
    return AuthStateModel(
      status: AuthStatus.authenticated,
      userModel: user,
      token: token,
      tokenExpiresAt: tokenExpiresAt,
      isInitializing: false,
    );
  }

  /// Create unauthenticated state model
  factory AuthStateModel.unauthenticated({String? errorMessage}) {
    return AuthStateModel(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
      isInitializing: false,
    );
  }

  /// Create initial state model
  factory AuthStateModel.initial() {
    return const AuthStateModel(
      status: AuthStatus.initial,
      isInitializing: true,
    );
  }

  /// Create authenticating state model
  factory AuthStateModel.authenticating() {
    return const AuthStateModel(
      status: AuthStatus.authenticating,
      isInitializing: false,
    );
  }

  /// Create failed state model
  factory AuthStateModel.failed({required String errorMessage}) {
    return AuthStateModel(
      status: AuthStatus.failed,
      errorMessage: errorMessage,
      isInitializing: false,
    );
  }

  /// Create token expired state model
  factory AuthStateModel.tokenExpired({UserModel? user}) {
    return AuthStateModel(
      status: AuthStatus.tokenExpired,
      userModel: user,
      errorMessage: 'Token has expired',
      isInitializing: false,
    );
  }

  /// Copy with new values
  @override
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
    DateTime? tokenExpiresAt,
    bool? isInitializing,
    Map<String, dynamic>? additionalData,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      userModel: user != null ? UserModel.fromEntity(user) : userModel,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isInitializing: isInitializing ?? this.isInitializing,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
