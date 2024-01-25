import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';

typedef LabelOptionBuilder<T extends Label> = Widget Function(
  BuildContext context,
  T label,
  VoidCallback onSelected,
);

class FullscreenMultiSelectionLabelForm<T extends Label>
    extends StatefulWidget {
  final List<T> availableOptions;
  final List<T> initialSelection;
  final LabelOptionBuilder<Label> optionBuilder;

  final String titleText;
  final String searchHintText;
  final String emptySearchMessage;

  const FullscreenMultiSelectionLabelForm({
    super.key,
    required this.optionBuilder,
    required this.availableOptions,
    required this.initialSelection,
    required this.titleText,
    required this.searchHintText,
    required this.emptySearchMessage,
  });

  @override
  State<FullscreenMultiSelectionLabelForm> createState() =>
      _FullscreenMultiSelectionLabelFormState();
}

class _FullscreenMultiSelectionLabelFormState
    extends State<FullscreenMultiSelectionLabelForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleText),
      ),
    );
  }
}
