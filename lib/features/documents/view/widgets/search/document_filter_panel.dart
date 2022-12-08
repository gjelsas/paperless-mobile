import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/query_type_form_field.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/util.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

enum DateRangeSelection { before, after }

class DocumentFilterPanel extends StatefulWidget {
  final PanelController panelController;
  final ScrollController scrollController;

  final DocumentFilter initialFilter;

  final void Function(DocumentFilter filter) onFilterChanged;
  const DocumentFilterPanel({
    Key? key,
    required this.panelController,
    required this.scrollController,
    required this.onFilterChanged,
    required this.initialFilter,
  }) : super(key: key);

  @override
  State<DocumentFilterPanel> createState() => _DocumentFilterPanelState();
}

class _DocumentFilterPanelState extends State<DocumentFilterPanel> {
  static const fkCorrespondent = DocumentModel.correspondentKey;
  static const fkDocumentType = DocumentModel.documentTypeKey;
  static const fkStoragePath = DocumentModel.storagePathKey;
  static const fkQuery = "query";
  static const fkCreatedAt = DocumentModel.createdKey;
  static const fkAddedAt = DocumentModel.addedKey;

  final _formKey = GlobalKey<FormBuilderState>();

  DateTimeRange? _dateTimeRangeOfNullable(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return null;
    }
    if (start != null && end != null) {
      return DateTimeRange(start: start, end: end);
    }
    assert(start != null || end != null);
    final singleDate = (start ?? end)!;
    return DateTimeRange(start: singleDate, end: singleDate);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _buildDragLine(),
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label:
                        Text(S.of(context).documentsFilterPageResetFilterLabel),
                    onPressed: () => _resetFilter(context),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).documentsFilterPageTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _onApplyFilter,
                  child:
                      Text(S.of(context).documentsFilterPageApplyFilterLabel),
                ),
              ],
            ).padded(),
            const SizedBox(
              height: 16.0,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: ListView(
                  controller: widget.scrollController,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(S.of(context).documentsFilterPageSearchLabel),
                    ).padded(const EdgeInsets.only(left: 8.0)),
                    _buildQueryFormField(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text(S.of(context).documentsFilterPageAdvancedLabel),
                    ).padded(const EdgeInsets.only(left: 8.0, top: 8.0)),
                    _buildCreatedDateRangePickerFormField().padded(),
                    _buildAddedDateRangePickerFormField().padded(),
                    _buildCorrespondentFormField().padded(),
                    _buildDocumentTypeFormField().padded(),
                    _buildStoragePathFormField().padded(),
                    TagFormField(
                      name: DocumentModel.tagsKey,
                      initialValue: widget.initialFilter.tags,
                      allowCreation: false,
                    ).padded(),
                    // Required in order for the storage path field to be visible when typing
                    const SizedBox(
                      height: 150,
                    ),
                  ],
                ).padded(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilter(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await BlocProvider.of<DocumentsCubit>(context).updateFilter();
    BlocProvider.of<SavedViewCubit>(context).resetSelection();
    if (!widget.panelController.isPanelClosed) {
      widget.panelController.close();
    }
  }

  //TODO: Check if the blocs can be found in the context, otherwise just provide repository and create new bloc inside LabelFormField!
  Widget _buildDocumentTypeFormField() {
    return BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
      builder: (context, state) {
        return LabelFormField<DocumentType, DocumentTypeQuery>(
          formBuilderState: _formKey.currentState,
          name: fkDocumentType,
          state: state.labels,
          label: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: widget.initialFilter.documentType,
          queryParameterIdBuilder: DocumentTypeQuery.fromId,
          queryParameterNotAssignedBuilder: DocumentTypeQuery.notAssigned,
          prefixIcon: const Icon(Icons.description_outlined),
        );
      },
    );
  }

  Widget _buildCorrespondentFormField() {
    return BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
      builder: (context, state) {
        return LabelFormField<Correspondent, CorrespondentQuery>(
          formBuilderState: _formKey.currentState,
          name: fkCorrespondent,
          state: state.labels,
          label: S.of(context).documentCorrespondentPropertyLabel,
          initialValue: widget.initialFilter.correspondent,
          queryParameterIdBuilder: CorrespondentQuery.fromId,
          queryParameterNotAssignedBuilder: CorrespondentQuery.notAssigned,
          prefixIcon: const Icon(Icons.person_outline),
        );
      },
    );
  }

  Widget _buildStoragePathFormField() {
    return BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>(
      builder: (context, state) {
        return LabelFormField<StoragePath, StoragePathQuery>(
          formBuilderState: _formKey.currentState,
          name: fkStoragePath,
          state: state.labels,
          label: S.of(context).documentStoragePathPropertyLabel,
          initialValue: widget.initialFilter.storagePath,
          queryParameterIdBuilder: StoragePathQuery.fromId,
          queryParameterNotAssignedBuilder: StoragePathQuery.notAssigned,
          prefixIcon: const Icon(Icons.folder_outlined),
        );
      },
    );
  }

  Widget _buildQueryFormField() {
    final queryType =
        _formKey.currentState?.getRawValue(QueryTypeFormField.fkQueryType) ??
            QueryType.titleAndContent;
    late String label;
    switch (queryType) {
      case QueryType.title:
        label = S.of(context).documentsFilterPageQueryOptionsTitleLabel;
        break;
      case QueryType.titleAndContent:
        label =
            S.of(context).documentsFilterPageQueryOptionsTitleAndContentLabel;
        break;
      case QueryType.extended:
        label = S.of(context).documentsFilterPageQueryOptionsExtendedLabel;
        break;
    }

    return FormBuilderTextField(
      name: fkQuery,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_outlined),
        labelText: label,
        suffixIcon: QueryTypeFormField(
          initialValue: widget.initialFilter.queryType,
          afterSelected: (queryType) => setState(() {}),
        ),
      ),
      initialValue: widget.initialFilter.queryText,
    ).padded();
  }

  Widget _buildDateRangePickerHelper(String formFieldKey) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastSevenDaysLabel,
            ),
            onPressed: () {
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateUtils.addDaysToDate(DateTime.now(), -7),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastMonthLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -1);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(firstDayOfLastMonth.year,
                      firstDayOfLastMonth.month, now.day),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastThreeMonthsLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -3);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastYearLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -12);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedDateRangePickerFormField() {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            widget.initialFilter.createdDateAfter,
            widget.initialFilter.createdDateBefore,
          ),
          // Workaround for theme data not being correctly passed to daterangepicker, see
          // https://github.com/flutter/flutter/issues/87580
          pickerBuilder: (context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                    iconTheme:
                        IconThemeData(color: Theme.of(context).primaryColor),
                  ),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    onPrimary: Theme.of(context).primaryColor,
                    primary: Theme.of(context).colorScheme.primary,
                  ),
            ),
            child: child!,
          ),
          format: DateFormat.yMMMd(Localizations.localeOf(context).toString()),
          fieldStartLabelText:
              S.of(context).documentsFilterPageDateRangeFieldStartLabel,
          fieldEndLabelText:
              S.of(context).documentsFilterPageDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkCreatedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentCreatedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () =>
                  _formKey.currentState?.fields[fkCreatedAt]?.didChange(null),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        _buildDateRangePickerHelper(fkCreatedAt),
      ],
    );
  }

  Widget _buildAddedDateRangePickerFormField() {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            widget.initialFilter.addedDateAfter,
            widget.initialFilter.addedDateBefore,
          ),
          // Workaround for theme data not being correctly passed to daterangepicker, see
          // https://github.com/flutter/flutter/issues/87580
          pickerBuilder: (context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                    iconTheme:
                        IconThemeData(color: Theme.of(context).primaryColor),
                  ),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    onPrimary: Theme.of(context).primaryColor,
                    primary: Theme.of(context).colorScheme.primary,
                  ),
            ),
            child: child!,
          ),
          format: DateFormat.yMMMd(Localizations.localeOf(context).toString()),
          fieldStartLabelText:
              S.of(context).documentsFilterPageDateRangeFieldStartLabel,
          fieldEndLabelText:
              S.of(context).documentsFilterPageDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkAddedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentAddedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () =>
                  _formKey.currentState?.fields[fkAddedAt]?.didChange(null),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        _buildDateRangePickerHelper(fkAddedAt),
      ],
    );
  }

  Widget _buildDragLine() {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
    );
  }

  void _onApplyFilter() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final v = _formKey.currentState!.value;
      final docCubit = BlocProvider.of<DocumentsCubit>(context);
      DocumentFilter newFilter = docCubit.state.filter.copyWith(
        createdDateBefore: (v[fkCreatedAt] as DateTimeRange?)?.end,
        createdDateAfter: (v[fkCreatedAt] as DateTimeRange?)?.start,
        correspondent: v[fkCorrespondent] as CorrespondentQuery?,
        documentType: v[fkDocumentType] as DocumentTypeQuery?,
        storagePath: v[fkStoragePath] as StoragePathQuery?,
        tags: v[DocumentModel.tagsKey] as TagsQuery?,
        page: 1,
        queryText: v[fkQuery] as String?,
        addedDateBefore: (v[fkAddedAt] as DateTimeRange?)?.end,
        addedDateAfter: (v[fkAddedAt] as DateTimeRange?)?.start,
        queryType: v[QueryTypeFormField.fkQueryType] as QueryType,
      );
      try {
        await BlocProvider.of<DocumentsCubit>(context)
            .updateFilter(filter: newFilter);
        BlocProvider.of<SavedViewCubit>(context).resetSelection();
        FocusScope.of(context).unfocus();
        widget.panelController.close();
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _patchFromFilter(DocumentFilter f) {
    _formKey.currentState?.patchValue({
      fkCorrespondent: f.correspondent,
      fkDocumentType: f.documentType,
      fkQuery: f.queryText,
      fkStoragePath: f.storagePath,
      DocumentModel.tagsKey: f.tags,
      DocumentModel.titleKey: f.queryText,
      QueryTypeFormField.fkQueryType: f.queryType,
      fkCreatedAt: _dateTimeRangeOfNullable(
        f.createdDateAfter,
        f.createdDateBefore,
      ),
      fkAddedAt: _dateTimeRangeOfNullable(
        f.addedDateAfter,
        f.addedDateBefore,
      ),
    });
  }
}
