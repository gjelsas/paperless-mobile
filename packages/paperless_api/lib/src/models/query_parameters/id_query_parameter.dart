import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/label_model.dart';

part 'id_query_parameter.g.dart';

sealed class IdQueryParameter with EquatableMixin {
  const IdQueryParameter();
  Map<String, String> toQueryParameter(String field);
  bool matches(int? id);

  Map<String, dynamic> toJson();

  bool get isUnset => this is UnsetIdQueryParameter;
  bool get isSet => this is SetIdQueryParameter;
  bool get isOnlyNotAssigned => this is NotAssignedIdQueryParameter;

  factory IdQueryParameter.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'UnsetIdQueryParameter':
        return UnsetIdQueryParameter.fromJson(json);
      case 'NotAssignedIdQueryParameter':
        return NotAssignedIdQueryParameter.fromJson(json);
      case 'SetIdQueryParameter':
        return SetIdQueryParameter.fromJson(json);
      default:
        throw ArgumentError.value(type, 'type', 'Unknown type');
    }
  }
}

@JsonSerializable()
class UnsetIdQueryParameter extends IdQueryParameter {
  const UnsetIdQueryParameter();
  @override
  Map<String, String> toQueryParameter(String field) => {};

  @override
  bool matches(int? id) => true;

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => {"_type": runtimeType};

  factory UnsetIdQueryParameter.fromJson(Map<String, dynamic> json) =>
      _$UnsetIdQueryParameterFromJson(json);
}

@JsonSerializable()
class NotAssignedIdQueryParameter extends IdQueryParameter {
  const NotAssignedIdQueryParameter();

  @override
  Map<String, String> toQueryParameter(String field) {
    return {'${field}__isnull': '1'};
  }

  @override
  bool matches(int? id) => id == null;
  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => {
        "_type": runtimeType.toString(),
      };

  factory NotAssignedIdQueryParameter.fromJson(Map<String, dynamic> json) =>
      _$NotAssignedIdQueryParameterFromJson(json);
}

@JsonEnum()
enum SetIdQueryParameterType { include, exclude }

@JsonSerializable()
class SetIdQueryParameter extends IdQueryParameter {
  final Set<int> ids;
  final SetIdQueryParameterType type;

  const SetIdQueryParameter({
    required this.ids,
    this.type = SetIdQueryParameterType.include,
  });

  @override
  Map<String, String> toQueryParameter(String field) {
    if (ids.isEmpty) {
      return {};
    }
    return switch (type) {
      SetIdQueryParameterType.include => {'${field}__id__in': ids.join(',')},
      SetIdQueryParameterType.exclude => {'${field}__id__none': ids.join(',')},
    };
  }

  @override
  bool matches(int? id) {
    if (ids.isEmpty) {
      return true;
    }
    return switch (type) {
      SetIdQueryParameterType.include => ids.contains(id),
      SetIdQueryParameterType.exclude => !ids.contains(id),
    };
  }

  @override
  List<Object?> get props => [ids, type];

  @override
  Map<String, dynamic> toJson() => {
        "_type": runtimeType,
        "includeIds": ids,
      };

  factory SetIdQueryParameter.fromJson(Map<String, dynamic> json) =>
      _$SetIdQueryParameterFromJson(json);
}
