import 'package:private_gitlab_notifier_dashboard/model/response_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ServerResponse<T> {
  @JsonKey(name: 'type')
  final int rawType;
  final T data;

  const ServerResponse(this.rawType, this.data);

  MRResponseType get type => MRResponseType.fromRawValue(rawType);

  factory ServerResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ServerResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(
    Object? Function(T) toJsonT,
  ) =>
      _$ServerResponseToJson(this, toJsonT);
}
