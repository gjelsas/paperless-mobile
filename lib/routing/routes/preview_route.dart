import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/features/document_viewer/view/file_viewer.dart';

part 'preview_route.g.dart';

@TypedGoRoute<PreviewRoute>(path: "/preview")
class PreviewRoute extends GoRouteData {
  final FutureOr<Uint8List> $extra;
  final Axis scrollDirection;

  PreviewRoute({
    this.scrollDirection = Axis.horizontal,
    required this.$extra,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FileViewer(
      fileProvider: (context) => $extra,
      scrollDirection: scrollDirection,
    );
  }
}
