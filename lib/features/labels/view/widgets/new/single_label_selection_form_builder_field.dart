import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/labels/view/widgets/fullscreen_multi_selection_label_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

typedef LabelRepositorySelector<T> = Map<int, T> Function(
    LabelRepository repository);
typedef AddLabelCallback = Future<int?> Function(
    BuildContext context, String searchText);

class SingleLabelSelectionFormBuilderField<T extends Label>
    extends StatelessWidget {
  /// The form field identifier
  final String name;
  final int? initialValue;
  final LabelRepositorySelector<T> optionsSelector;
  final LabelOptionBuilder<T> optionBuilder;
  final String searchHintText;
  final String emptySearchMessage;
  final String emptyOptionsMessage;
  final String addNewLabelText;
  final bool enabled;
  final Widget prefixIcon;
  final AddLabelCallback onAddLabel;

  const SingleLabelSelectionFormBuilderField({
    super.key,
    required this.name,
    this.initialValue,
    this.optionBuilder = _defaultOptionsBuilder,
    required this.searchHintText,
    required this.emptySearchMessage,
    required this.emptyOptionsMessage,
    required this.enabled,
    required this.prefixIcon,
    required this.onAddLabel,
    required this.optionsSelector,
    required this.addNewLabelText,
  });

  static Widget _defaultOptionsBuilder(
    BuildContext context,
    Label label,
    VoidCallback onSelected,
  ) {
    final documentCountText =
        S.of(context)!.documentsAssigned(label.documentCount ?? 0);
    return ListTile(
      title: Text(label.name),
      trailing: Text(
        documentCountText,
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.end,
      ),
      onTap: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LabelRepository>();
    final options = optionsSelector(repository);
    return FormBuilderField<int>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        return OpenContainer<int>(
          middleColor: Theme.of(context).colorScheme.background,
          closedColor: Theme.of(context).colorScheme.background,
          openColor: Theme.of(context).colorScheme.background,
          closedShape: InputBorder.none,
          openElevation: 0,
          closedElevation: 0,
          tappable: enabled,
          closedBuilder: (context, openForm) => Container(
            margin: const EdgeInsets.only(top: 6),
            child: TextField(
              controller: TextEditingController(
                text: options[field.value]?.name,
              ),
              onTap: openForm,
              readOnly: true,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: options[field.value]?.name,
                prefixIcon: prefixIcon,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => field.didChange(null),
                ),
              ),
            ),
          ),
          openBuilder: (context, closeForm) {
            return _FullScreenSingleLabelSelectionForm<T>(
              initialValue: field.value,
              optionBuilder: optionBuilder,
              searchHintText: searchHintText,
              emptySearchMessage: emptySearchMessage,
              emptyOptionsMessage: emptyOptionsMessage,
              optionSelector: optionsSelector,
              onAddLabel: onAddLabel,
              addNewLabelText: addNewLabelText,
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

class _FullScreenSingleLabelSelectionForm<T extends Label>
    extends StatefulWidget {
  final int? initialValue;
  final LabelRepositorySelector<T> optionSelector;
  final LabelOptionBuilder<T> optionBuilder;
  final String searchHintText;
  final String emptySearchMessage;
  final String emptyOptionsMessage;
  final String addNewLabelText;
  final AddLabelCallback onAddLabel;
  const _FullScreenSingleLabelSelectionForm({
    super.key,
    this.initialValue,
    required this.optionSelector,
    required this.optionBuilder,
    required this.searchHintText,
    required this.emptySearchMessage,
    required this.emptyOptionsMessage,
    required this.onAddLabel,
    required this.addNewLabelText,
  });

  @override
  State<_FullScreenSingleLabelSelectionForm<T>> createState() =>
      _FullScreenSingleLabelSelectionFormState<T>();
}

class _FullScreenSingleLabelSelectionFormState<T extends Label>
    extends State<_FullScreenSingleLabelSelectionForm<T>> {
  late final TextEditingController _textEditingController;
  @override
  void initState() {
    super.initState();
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
        title: SizedBox(
          height: kToolbarHeight,
          child: TextFormField(
            controller: _textEditingController,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              hintText:
                  options[widget.initialValue]?.name ?? widget.searchHintText,
              suffix: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.clear),
                onPressed: () => _textEditingController.clear(),
              ),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (filteredOptions.isEmpty) {
            return Column(
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
            );
          }
          return ListView.builder(
            itemBuilder: (context, index) {
              final option = filteredOptions.elementAt(index);
              return widget.optionBuilder(
                context,
                option,
                () => context.pop(option.id),
              );
            },
            itemCount: filteredOptions.length,
          );
        },
      ),
    );
  }
}
