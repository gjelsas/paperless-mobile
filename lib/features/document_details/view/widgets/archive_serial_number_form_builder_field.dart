import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ArchiveSerialNumberFormBuilderField extends StatefulWidget {
  final String name;
  final bool enabled;
  final int? initialValue;
  final int nextAsn;
  const ArchiveSerialNumberFormBuilderField({
    super.key,
    required this.name,
    required this.enabled,
    this.initialValue,
    required this.nextAsn,
  });

  @override
  State<ArchiveSerialNumberFormBuilderField> createState() =>
      _ArchiveSerialNumberFormBuilderFieldState();
}

class _ArchiveSerialNumberFormBuilderFieldState
    extends State<ArchiveSerialNumberFormBuilderField> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<int>(
      name: widget.name,
      initialValue: widget.initialValue,
      builder: (field) {
        return TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            final parsedValue = int.tryParse(value);
            if (parsedValue != null) {
              field.didChange(parsedValue);
            }
          },
          decoration: InputDecoration(
            labelText: S.of(context)!.archiveSerialNumber,
            prefixIcon: Icon(Icons.archive_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (field.value != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      field.didChange(null);
                    },
                  ),
                if (widget.enabled)
                  IconButton(
                    onPressed: () {
                      field.didChange(widget.nextAsn);
                    },
                    icon: Icon(Icons.plus_one),
                  ),
              ],
            ).padded(),
          ),
        );
      },
    );
  }
}
