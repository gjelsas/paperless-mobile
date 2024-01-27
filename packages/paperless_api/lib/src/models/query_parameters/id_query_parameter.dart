import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:paperless_api/config/hive/hive_type_ids.dart';

// part 'id_query_parameter.g.dart';

sealed class IdQueryParameter with EquatableMixin {
  const IdQueryParameter();
  Map<String, String> toQueryParameter(String field);
  bool matches(int? id);

  bool get isUnset => this is UnsetIdQueryParameter;
  bool get isSet => this is SetIdQueryParameter;
  bool get isOnlyNotAssigned => this is NotAssignedIdQueryParameter;
  bool get isOnlyAssigned => this is AnyAssignedIdQueryParameter;
}

// @HiveType(typeId: PaperlessApiHiveTypeIds.unsetIdQueryParameter)
class UnsetIdQueryParameter extends IdQueryParameter {
  const UnsetIdQueryParameter();
  @override
  Map<String, String> toQueryParameter(String field) => {};

  @override
  bool matches(int? id) => true;

  @override
  List<Object?> get props => [];
}

// @HiveType(typeId: PaperlessApiHiveTypeIds.notAssignedIdQueryParameter)
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
}

class AnyAssignedIdQueryParameter extends IdQueryParameter {
  const AnyAssignedIdQueryParameter();
  @override
  Map<String, String> toQueryParameter(String field) {
    return {'${field}__isnull': '0'};
  }

  @override
  bool matches(int? id) => id != null;
  @override
  List<Object?> get props => [];
}

class SetIdQueryParameter extends IdQueryParameter with EquatableMixin {
  final List<int> includeIds;
  final List<int> excludeIds;

  const SetIdQueryParameter({
    required this.includeIds,
    this.excludeIds = const [],
  });

  @override
  Map<String, String> toQueryParameter(String field) {
    if (includeIds.isEmpty) {
      return {};
    }
    return {'${field}__id__in': includeIds.join(',')};
  }

  @override
  bool matches(int? id) => includeIds.contains(id);

  @override
  List<Object?> get props => [includeIds.sorted((a, b) => a.compareTo(b))];
}

/// Custom Adapters

// class UnsetIdQueryParameterAdapter extends TypeAdapter<UnsetIdQueryParameter> {
//   @override
//   final int typeId = 116;

//   @override
//   UnsetIdQueryParameter read(BinaryReader reader) {
//     reader.readByte();
//     return const UnsetIdQueryParameter();
//   }

//   @override
//   void write(BinaryWriter writer, UnsetIdQueryParameter obj) {
//     writer.writeByte(0);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is UnsetIdQueryParameterAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }

// class NotAssignedIdQueryParameterAdapter
//     extends TypeAdapter<NotAssignedIdQueryParameter> {
//   @override
//   final int typeId = 117;

//   @override
//   NotAssignedIdQueryParameter read(BinaryReader reader) {
//     reader.readByte();
//     return const NotAssignedIdQueryParameter();
//   }

//   @override
//   void write(BinaryWriter writer, NotAssignedIdQueryParameter obj) {
//     writer.writeByte(0);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is NotAssignedIdQueryParameterAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }

// class AnyAssignedIdQueryParameterAdapter
//     extends TypeAdapter<AnyAssignedIdQueryParameter> {
//   @override
//   final int typeId = 118;

//   @override
//   AnyAssignedIdQueryParameter read(BinaryReader reader) {
//     reader.readByte();
//     return const AnyAssignedIdQueryParameter();
//   }

//   @override
//   void write(BinaryWriter writer, AnyAssignedIdQueryParameter obj) {
//     writer.writeByte(0);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AnyAssignedIdQueryParameterAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
