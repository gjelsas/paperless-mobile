import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/field_suggestions_widget.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/types.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class MultiLabelSelectionFormBuilderField<T extends Label>
    extends StatelessWidget {
  /// The form field identifier
  final String name;
  final Iterable<int>? initialValue;
  final LabelRepositorySelector<T> optionsSelector;
  final LabelMultiOptionBuilder<T> optionBuilder;
  final DisplayOptionBuilder<T> displayOptionBuilder;
  final String labelText;
  final String searchHintText;
  final String emptySearchMessage;
  final String emptyOptionsMessage;
  final String addNewLabelText;
  final bool enabled;
  final Widget prefixIcon;
  final AddLabelCallback onAddLabel;
  final Iterable<int>? suggestions;
  final bool showSuggestions;

  const MultiLabelSelectionFormBuilderField({
    super.key,
    required this.name,
    this.initialValue,
    this.optionBuilder = _defaultOptionsBuilder,
    this.displayOptionBuilder = _defaultDisplayOptionBuilder,
    required this.searchHintText,
    required this.emptySearchMessage,
    required this.emptyOptionsMessage,
    required this.enabled,
    required this.prefixIcon,
    required this.onAddLabel,
    required this.optionsSelector,
    required this.addNewLabelText,
    required this.labelText,
    this.suggestions,
    this.showSuggestions = false,
  });

  static Widget _defaultOptionsBuilder(
    BuildContext context,
    Label label,
    VoidCallback onSelected,
    bool selected,
  ) {
    final documentCountText =
        S.of(context)!.documentsAssigned(label.documentCount ?? 0);
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(
        label.name,
        style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : ListTileTheme.of(context).textColor),
      ),
      trailing: Text(
        documentCountText,
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.end,
      ),
      onTap: onSelected,
    );
  }

  static Widget _defaultDisplayOptionBuilder(
    BuildContext context,
    Label label,
    VoidCallback onDelete,
  ) {
    return Chip(
      label: Text(label.name),
      padding: EdgeInsets.zero,
      deleteIcon: Icon(Icons.clear),
      onDeleted: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LabelRepository>();
    final options = optionsSelector(repository);
    return FormBuilderField<Iterable<int>>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        final isEmpty = field.value?.isEmpty ?? true;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OpenContainer<Iterable<int>>(
              middleColor: Theme.of(context).colorScheme.background,
              closedColor: Theme.of(context).colorScheme.background,
              openColor: Theme.of(context).colorScheme.background,
              closedShape: InputBorder.none,
              openElevation: 0,
              closedElevation: 0,
              tappable: enabled,
              closedBuilder: (context, openForm) {
                return Container(
                  margin: const EdgeInsets.only(top: 6),
                  child: InputDecorator(
                    isEmpty: isEmpty,
                    decoration: InputDecoration(
                      labelText: labelText,
                      contentPadding: const EdgeInsets.all(12),
                      prefixIcon: prefixIcon,
                      enabled: enabled,
                      suffixIcon: field.value?.isNotEmpty ?? false
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                field.didChange(null);
                              },
                            )
                          : null,
                    ),
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 4),
                        itemBuilder: (context, index) => displayOptionBuilder(
                            context, options[field.value!.elementAt(index)]!,
                            () {
                          final newValue = field.value!.toList()
                            ..removeAt(index);
                          field.didChange(newValue);
                        }),
                        itemCount: field.value?.length ?? 0,
                      ),
                    ),
                  ),
                );
              },
              openBuilder: (context, closeForm) {
                return _FullScreenMultiLabelSelectionForm<T>(
                  initialValue: field.value,
                  optionBuilder: optionBuilder,
                  searchHintText: searchHintText,
                  emptySearchMessage: emptySearchMessage,
                  emptyOptionsMessage: emptyOptionsMessage,
                  optionSelector: optionsSelector,
                  onAddLabel: onAddLabel,
                  addNewLabelText: addNewLabelText,
                  closeForm: (value) => closeForm(returnValue: value),
                );
              },
              onClosed: (data) {
                if (data != null) {
                  field.didChange(data);
                }
              },
            ),
            if (showSuggestions && suggestions?.isNotEmpty == true)
              FieldSuggestionsWidget<int?>(
                suggestions: suggestions!,
                valueTransformer: (suggestion) =>
                    options[suggestion]?.name ?? '',
                onSuggestionSelected: (value) {
                  final current = field.value ?? [];
                  if (value != null) {
                    field.didChange([...current, value]);
                  }
                },
                currentValues: field.value,
              ),
          ],
        );
      },
    );
  }
}

class _FullScreenMultiLabelSelectionForm<T extends Label>
    extends StatefulWidget {
  final Iterable<int>? initialValue;
  final LabelRepositorySelector<T> optionSelector;
  final LabelMultiOptionBuilder<T> optionBuilder;
  final String searchHintText;
  final String emptySearchMessage;
  final String emptyOptionsMessage;
  final String addNewLabelText;
  final AddLabelCallback onAddLabel;
  final void Function(Iterable<int>? returnValue) closeForm;

  const _FullScreenMultiLabelSelectionForm({
    super.key,
    this.initialValue,
    required this.optionSelector,
    required this.optionBuilder,
    required this.searchHintText,
    required this.emptySearchMessage,
    required this.emptyOptionsMessage,
    required this.onAddLabel,
    required this.addNewLabelText,
    required this.closeForm,
  });

  @override
  State<_FullScreenMultiLabelSelectionForm<T>> createState() =>
      _FullScreenMultiLabelSelectionFormState<T>();
}

class _FullScreenMultiLabelSelectionFormState<T extends Label>
    extends State<_FullScreenMultiLabelSelectionForm<T>> {
  late final TextEditingController _textEditingController;

  late List<int> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.initialValue?.toList() ?? [];
    _textEditingController = TextEditingController()
      ..addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LabelRepository>();
    final options = widget.optionSelector(repository);
    final normalizedSearchText =
        removeDiacritics(_textEditingController.text.toLowerCase().trim());
    final filteredOptions = options.values.where((element) {
      final normalizedLabelName =
          removeDiacritics(element.name.toLowerCase().trim());
      return normalizedLabelName.contains(normalizedSearchText);
    }).sortedByCompare((element) => element.name, (a, b) => a.compareTo(b));
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: false,
        title: TextFormField(
          controller: _textEditingController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            hintText: widget.searchHintText,
            suffix: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.clear),
              onPressed: () => _textEditingController.clear(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              widget.closeForm(_selectedOptions);
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (filteredOptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.emptySearchMessage),
                    TextButton(
                      child: Text(widget.addNewLabelText),
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        final selection = await widget.onAddLabel(
                          context,
                          _textEditingController.text,
                        );
                        if (selection != null) {
                          router.pop(selection);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemBuilder: (context, index) {
              final option = filteredOptions.elementAt(index);
              final isSelected = _selectedOptions.contains(option.id);
              return widget.optionBuilder(
                context,
                option,
                () => setState(() {
                  if (isSelected) {
                    _selectedOptions.remove(option.id);
                  } else {
                    _selectedOptions.add(option.id!);
                  }
                }),
                isSelected,
              );
            },
            itemCount: filteredOptions.length,
          );
        },
      ),
    );
  }
}
