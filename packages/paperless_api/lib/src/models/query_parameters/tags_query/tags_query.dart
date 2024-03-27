import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tags_query.g.dart';

sealed class TagsQuery with EquatableMixin {
  const TagsQuery();
  Map<String, String> toQueryParameter();
  bool matches(Iterable<int> ids);

  Map<String, dynamic> toJson();

  factory TagsQuery.fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String;
    switch (type) {
      case 'NotAssignedTagsQuery':
        return const NotAssignedTagsQuery();
      case 'AnyAssignedTagsQuery':
        return AnyAssignedTagsQuery.fromJson(json);
      case 'IdsTagsQuery':
        return IdsTagsQuery.fromJson(json);
      default:
        throw ArgumentError.value(type, 'type', 'Unknown type');
    }
  }
}

class NotAssignedTagsQuery extends TagsQuery {
  const NotAssignedTagsQuery();
  @override
  Map<String, String> toQueryParameter() {
    return {'is_tagged': '0'};
  }

  @override
  bool matches(Iterable<int> ids) => ids.isEmpty;

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => {'_type': runtimeType};
}

@JsonSerializable()
class AnyAssignedTagsQuery extends TagsQuery {
  final Set<int> tagIds;
  const AnyAssignedTagsQuery({
    this.tagIds = const {},
  });

  @override
  Map<String, String> toQueryParameter() {
    if (tagIds.isEmpty) {
      return {'is_tagged': '1'};
    }
    return {'tags__id__in': tagIds.join(',')};
  }

  @override
  bool matches(Iterable<int> ids) => ids.isNotEmpty;

  AnyAssignedTagsQuery copyWith({
    Set<int>? tagIds,
  }) {
    return AnyAssignedTagsQuery(
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  List<Object?> get props => [tagIds];

  factory AnyAssignedTagsQuery.fromJson(Map<String, dynamic> json) =>
      _$AnyAssignedTagsQueryFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ..._$AnyAssignedTagsQueryToJson(this),
        '_type': runtimeType.toString(),
      };
}

@JsonSerializable()
class IdsTagsQuery extends TagsQuery {
  final Set<int> include;
  final Set<int> exclude;

  const IdsTagsQuery({
    this.include = const {},
    this.exclude = const {},
  });

  @override
  Map<String, String> toQueryParameter() {
    final Map<String, String> params = {};
    if (include.isNotEmpty) {
      params.putIfAbsent('tags__id__all', () => include.join(','));
    }
    if (exclude.isNotEmpty) {
      params.putIfAbsent('tags__id__none', () => exclude.join(','));
    }
    return params;
  }

  @override
  bool matches(Iterable<int> ids) {
    return include.toSet().difference(ids.toSet()).isEmpty &&
        exclude.toSet().intersection(ids.toSet()).isEmpty;
  }

  IdsTagsQuery copyWith({
    Set<int>? include,
    Set<int>? exclude,
  }) {
    return IdsTagsQuery(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
    );
  }

  @override
  List<Object?> get props => [include, exclude];
  factory IdsTagsQuery.fromJson(Map<String, dynamic> json) =>
      _$IdsTagsQueryFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ..._$IdsTagsQueryToJson(this),
        '_type': runtimeType.toString(),
      };
}
