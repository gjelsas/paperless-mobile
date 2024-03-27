import 'dart:convert';
import 'dart:typed_data';

import 'package:paperless_api/paperless_api.dart';

const _labelType = 'LabelType';
const _documentModel = 'DocumentModel';
const _documentFilter = 'DocumentFilter';
const _savedView = 'SavedView';
const _uint8List = 'Uint8List';

class ExtraCodec extends Codec<Object?, Object?> {
  const ExtraCodec();
  @override
  Converter<Object?, Object?> get decoder => const _ExtraDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _ExtraEncoder();
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  const _ExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    final List<Object?> inputAsList = input as List<Object?>;
    final name = inputAsList.first;
    final data = inputAsList.last;
    switch (name) {
      case _labelType:
        return LabelType.values.byName(data as String);
      case _documentModel:
        return DocumentModel.fromJson(data as Map<String, dynamic>);
      case _savedView:
        return SavedView.fromJson(data as Map<String, dynamic>);
      case _uint8List:
        return Uint8List.fromList(data as List<int>);
      case _documentFilter:
        return DocumentFilter.fromJson(data as Map<String, dynamic>);
    }
    throw FormatException('Unable tp parse input: $input');
  }
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();
  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    switch (input) {
      case LabelType():
        return <Object?>[
          _labelType,
          input.name,
        ];
      case DocumentModel():
        return <Object?>[
          _documentModel,
          input.toJson(),
        ];

      case SavedView():
        return <Object?>[
          _savedView,
          input.toJson(),
        ];
      case Uint8List():
        return <Object?>[
          _uint8List,
          input.toList(),
        ];
      default:
        throw FormatException(
          'Cannot encode type ${input.runtimeType}. '
          'Did you forget to register it in ExtraCodec?',
        );
    }
  }
}
