import 'package:flutter/widgets.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';

typedef DisplayOptionBuilder<T> = Widget Function(
  BuildContext context,
  T label,
  VoidCallback onDelete,
);

typedef LabelMultiOptionBuilder<T> = Widget Function(
  BuildContext context,
  T label,
  VoidCallback onSelected,
  bool selected,
);

typedef LabelRepositorySelector<T> = Map<int, T> Function(
  LabelRepository repository,
);
typedef AddLabelCallback = Future<int?> Function(
  BuildContext context,
  String searchText,
);

typedef MultiSelectionFilterOptionBuilder<T> = Widget Function({
  required BuildContext context,
  required T label,
  required VoidCallback onSelected,
  required SetIdQueryParameterType type,
  required bool selected,
});
