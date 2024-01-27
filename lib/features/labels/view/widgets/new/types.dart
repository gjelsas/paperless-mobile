import 'package:flutter/widgets.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';

typedef DisplayOptionBuilder<T> = Widget Function(
  BuildContext context,
  T label,
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

typedef MultiSelectionFilterOptionBuilder<T> = Widget Function(
  BuildContext context,
  T label,
  VoidCallback onSelected,
  bool include,
  bool exclude,
);
