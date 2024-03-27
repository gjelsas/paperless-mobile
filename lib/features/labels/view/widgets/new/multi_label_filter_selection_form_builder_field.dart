import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/util/list_utils.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/types.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MultiLabelFilterSelectionFormBuilderField<T extends Label>
    extends StatelessWidget {
  /// The form field identifier
  final String name;
  final IdQueryParameter initialValue;
  final LabelRepositorySelector<T> optionsSelector;
  final MultiSelectionFilterOptionBuilder<T> optionBuilder;
  final DisplayOptionBuilder<T> displayOptionBuilder;
  final String labelText;
  final String searchHintText;
  final String emptySearchMessage;
  final String emptyOptionsMessage;
  final bool enabled;
  final Widget prefixIcon;

  const MultiLabelFilterSelectionFormBuilderField({
    super.key,
    required this.name,
    this.initialValue = const UnsetIdQueryParameter(),
    this.optionBuilder = _defaultOptionsBuilder,
    this.displayOptionBuilder = _defaultDisplayOptionBuilder,
    required this.searchHintText,
    required this.emptySearchMessage,
    required this.emptyOptionsMessage,
    required this.enabled,
    required this.prefixIcon,
    required this.optionsSelector,
    required this.labelText,
  });

  static Widget _defaultOptionsBuilder({
    required BuildContext context,
    required Label label,
    required VoidCallback onSelected,
    required SetIdQueryParameterType type,
    required bool selected,
  }) {
    final documentCountText =
        S.of(context)!.documentsAssigned(label.documentCount ?? 0);

    final trailingIcon = switch (type) {
      SetIdQueryParameterType.include => Icon(Icons.check),
      SetIdQueryParameterType.exclude => Icon(Icons.clear),
    };
    final defaultTrailing = selected
        ? trailingIcon
        : Text(
            documentCountText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: label.documentCount == 0
                      ? Theme.of(context).disabledColor
                      : null,
                ),
            textAlign: TextAlign.end,
          );

    return ListTile(
      enabled: label.documentCount != 0,
      title: Text(label.name),
      trailing: defaultTrailing,
      onTap: onSelected,
    );
  }

  static Widget _defaultDisplayOptionBuilder(
    BuildContext context,
    Label label,
    VoidCallback onDelete,
  ) {
    return Chip(
      padding: EdgeInsets.zero,
      label: Text(label.name),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.clear),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LabelRepository>();
    final options = optionsSelector(repository);
    return FormBuilderField<IdQueryParameter>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        final isEmpty = field.value is UnsetIdQueryParameter;
        return OpenContainer<IdQueryParameter>(
          middleColor: Theme.of(context).colorScheme.background,
          closedColor: Theme.of(context).colorScheme.background,
          openColor: Theme.of(context).colorScheme.background,
          closedShape: InputBorder.none,
          openElevation: 0,
          closedElevation: 0,
          tappable: enabled,
          closedBuilder: (context, openForm) => Container(
            margin: const EdgeInsets.only(top: 6),
            child: InputDecorator(
              isEmpty: isEmpty,
              decoration: InputDecoration(
                labelText: labelText,
                contentPadding: const EdgeInsets.all(12),
                prefixIcon: prefixIcon,
                enabled: enabled,
                suffixIcon: field.value is! UnsetIdQueryParameter
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
                  itemBuilder: (context, index) => switch (field.value) {
                    UnsetIdQueryParameter() => null,
                    NotAssignedIdQueryParameter() =>
                      Text(S.of(context)!.notAssigned),
                    SetIdQueryParameter(ids: final includeIds) =>
                      displayOptionBuilder(
                          context, options[includeIds.elementAt(index)]!, () {
                        field.didChange(
                          SetIdQueryParameter(
                            ids: includeIds
                                .toggle(includeIds.elementAt(index))
                                .toSet(),
                          ),
                        );
                      }),
                    null => null,
                  },
                  itemCount: switch (field.value) {
                    SetIdQueryParameter(ids: var ids) => ids.length,
                    _ => 0,
                  },
                ),
              ),
            ),
          ),
          openBuilder: (context, closeForm) {
            return _FullScreenMultiLabelFilterSelection<T>(
              initialValue: field.value,
              optionBuilder: optionBuilder,
              searchHintText: searchHintText,
              emptySearchMessage: emptySearchMessage,
              emptyOptionsMessage: emptyOptionsMessage,
              optionSelector: optionsSelector,
            );
          },
          onClosed: (data) {
            if (data != null) {
              field.didChange(data);
            }
          },
        );
      },
    );
  }
}

class _FullScreenMultiLabelFilterSelection<T extends Label>
    extends StatefulWidget {
  final IdQueryParameter? initialValue;
  final MultiSelectionFilterOptionBuilder<T> optionBuilder;
  final String emptySearchMessage;
  final String searchHintText;
  final String emptyOptionsMessage;
  final LabelRepositorySelector<T> optionSelector;

  const _FullScreenMultiLabelFilterSelection({
    super.key,
    this.initialValue,
    required this.optionBuilder,
    required this.emptySearchMessage,
    required this.searchHintText,
    required this.emptyOptionsMessage,
    required this.optionSelector,
  });

  @override
  State<_FullScreenMultiLabelFilterSelection> createState() =>
      __FullScreenMultiLabelFilterSelectionState();
}

class __FullScreenMultiLabelFilterSelectionState
    extends State<_FullScreenMultiLabelFilterSelection> {
  late final TextEditingController _textEditingController;
  late IdQueryParameter _selection;
  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _selection = widget.initialValue ?? const UnsetIdQueryParameter();
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
        title: SizedBox(
          height: kToolbarHeight,
          child: TextFormField(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              context.pop(_selection);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (filteredOptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(widget.emptySearchMessage),
              ),
            );
          }
          final typeSelectionEnabled = _selection is SetIdQueryParameter;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverToBoxAdapter(
                  child: SegmentedButton<SetIdQueryParameterType>(
                    segments: [
                      ButtonSegment(
                        enabled: typeSelectionEnabled,
                        value: SetIdQueryParameterType.include,
                        label: Text("Include"), //TODO: INTL
                      ),
                      ButtonSegment(
                        enabled: typeSelectionEnabled,
                        value: SetIdQueryParameterType.exclude,
                        label: Text("Exclude"), //TODO: INTL
                      ),
                    ],
                    selected: switch (_selection) {
                      SetIdQueryParameter(:final type) => {type},
                      _ => {SetIdQueryParameterType.include},
                    },
                    multiSelectionEnabled: false,
                    onSelectionChanged: (value) {
                      setState(() {
                        _selection = switch (_selection) {
                          SetIdQueryParameter(:final ids) =>
                            SetIdQueryParameter(
                              ids: ids,
                              type: value.single,
                            ),
                          _ => throw AssertionError(
                              "Cannot include or exclude for types other than SetIdQueryParameter."),
                        };
                      });
                    },
                  ),
                ),
              ),
              SliverList.builder(
                itemBuilder: (context, index) {
                  final option = filteredOptions.elementAt(index);
                  final isSelected = switch (_selection) {
                    SetIdQueryParameter(:final ids) => ids.contains(option.id),
                    _ => false,
                  };
                  final type = switch (_selection) {
                    SetIdQueryParameter(:final type) => type,
                    _ => SetIdQueryParameterType.include,
                  };
                  return widget.optionBuilder(
                    context: context,
                    label: option,
                    onSelected: () {
                      switch (_selection) {
                        case SetIdQueryParameter(:final ids, :final type):
                          final updatedIds = ids.toggle(option.id!).toSet();
                          if (updatedIds.isEmpty) {
                            setState(() {
                              _selection = const UnsetIdQueryParameter();
                            });
                          } else {
                            setState(() {
                              _selection = SetIdQueryParameter(
                                ids: updatedIds,
                                type: type,
                              );
                            });
                          }
                          break;
                        default:
                          setState(() {
                            _selection = SetIdQueryParameter(ids: {option.id!});
                          });
                          break;
                      }
                    },
                    selected: isSelected,
                    type: type,
                  );
                },
                itemCount: filteredOptions.length,
              ),
            ],
          );
        },
      ),
    );
  }
}
