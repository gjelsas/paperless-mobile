import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_relative_date_range_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class ExtendedDateRangeDialog extends StatefulWidget {
  final DateRangeQuery initialValue;
  final String Function(DateRangeQuery query) stringTransformer;
  const ExtendedDateRangeDialog({
    super.key,
    required this.initialValue,
    required this.stringTransformer,
  });

  @override
  State<ExtendedDateRangeDialog> createState() =>
      _ExtendedDateRangeDialogState();
}

class _ExtendedDateRangeDialogState extends State<ExtendedDateRangeDialog> {
  static const String _fkAbsoluteBefore = 'absoluteBefore';
  static const String _fkAbsoluteAfter = 'absoluteAfter';
  static const String _fkRelative = 'relative';

  final _formKey = GlobalKey<FormBuilderState>();
  late DateRangeType _selectedDateRangeType;
  @override
  void initState() {
    super.initState();
    _selectedDateRangeType = (widget.initialValue is RelativeDateRangeQuery)
        ? DateRangeType.relative
        : DateRangeType.absolute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select date range"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Hint: You can either specify absolute values by selecting concrete dates, or you can specify a time range relative to today.",
              style: Theme.of(context).textTheme.caption,
            ),
            _buildDateRangeQueryTypeSelection(),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                switch (_selectedDateRangeType) {
                  case DateRangeType.absolute:
                    return _buildAbsoluteDateRangeForm();
                  case DateRangeType.relative:
                    return FormBuilderRelativeDateRangePicker(
                      initialValue:
                          widget.initialValue is RelativeDateRangeQuery
                              ? widget.initialValue as RelativeDateRangeQuery
                              : const RelativeDateRangeQuery(
                                  1,
                                  DateRangeUnit.month,
                                ),
                      name: _fkRelative,
                    );
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(S.of(context).genericActionCancelLabel),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(S.of(context).genericActionSaveLabel),
          onPressed: () {
            _formKey.currentState?.save();
            if (_formKey.currentState?.validate() ?? false) {
              final values = _formKey.currentState!.value;
              final query = _buildQuery(values);
              Navigator.pop(context, query);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeQueryTypeSelection() {
    return Row(
      children: [
        ChoiceChip(
          label: Text('Absolute'),
          selected: _selectedDateRangeType == DateRangeType.absolute,
          onSelected: (value) =>
              setState(() => _selectedDateRangeType = DateRangeType.absolute),
        ).paddedOnly(right: 8.0),
        ChoiceChip(
          label: Text('Relative'),
          selected: _selectedDateRangeType == DateRangeType.relative,
          onSelected: (value) =>
              setState(() => _selectedDateRangeType = DateRangeType.relative),
        ),
      ],
    );
  }

  Widget _buildAbsoluteDateRangeForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        FormBuilderDateTimePicker(
          name: _fkAbsoluteAfter,
          initialDate: widget.initialValue is AbsoluteDateRangeQuery
              ? (widget.initialValue as AbsoluteDateRangeQuery).after
              : null,
          decoration: InputDecoration(
            labelText: S.of(context).extendedDateRangePickerAfterLabel,
          ),
          inputType: InputType.date,
        ),
        FormBuilderDateTimePicker(
          name: _fkAbsoluteBefore,
          initialDate: widget.initialValue is AbsoluteDateRangeQuery
              ? (widget.initialValue as AbsoluteDateRangeQuery).before
              : null,
          inputType: InputType.date,
          decoration: InputDecoration(
            labelText: S.of(context).extendedDateRangePickerBeforeLabel,
          ),
        ),
      ],
    );
  }

  DateRangeQuery? _buildQuery(Map<String, dynamic> values) {
    if (_selectedDateRangeType == DateRangeType.absolute) {
      return AbsoluteDateRangeQuery(
        after: values[_fkAbsoluteAfter],
        before: values[_fkAbsoluteBefore],
      );
    } else {
      return values[_fkRelative] as RelativeDateRangeQuery;
    }
  }
}

enum DateRangeType {
  absolute,
  relative;
}
