import 'package:flutter/widgets.dart';
import 'package:paperless_api/paperless_api.dart';

typedef LabelOptionBuilder<T extends Label> = Widget Function(
  BuildContext context,
  T label,
);
