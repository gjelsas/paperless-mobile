import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/archive_serial_number_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tag_widget.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/multi_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/single_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';

/// Widget shown when the document information has been loaded.
class DocumentOverviewEditWidget extends StatelessWidget {
  final DocumentDetailsData data;
  final EdgeInsets itemPadding;
  final double verticalPadding;
  const DocumentOverviewEditWidget({
    super.key,
    required this.data,
    required this.itemPadding,
    required this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocalUserAccount>().paperlessUser;
    return ListView(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      children: [
        Padding(
          padding: itemPadding,
          child: FormBuilderTextField(
            initialValue: data.document.title,
            name: 'title',
            decoration: InputDecoration(
              labelText: S.of(context)!.title,
            ),
          ),
        ),
        Padding(
          padding: itemPadding,
          child: ArchiveSerialNumberFormBuilderField(
            name: 'asn',
            enabled: true,
            nextAsn: data.nextAsn,
            initialValue: data.document.archiveSerialNumber,
          ),
        ),
        Padding(
          padding: itemPadding,
          child: FormBuilderLocalizedDatePicker(
            name: "createdAt",
            initialValue: data.document.created,
            labelText: S.of(context)!.createdAt,
            firstDate: DateTime(1970, 1, 1),
            lastDate: DateTime(2100, 1, 1),
            locale: Localizations.localeOf(context),
            prefixIcon: const Icon(Icons.calendar_today),
            suggestions: data.fieldSuggestions.dates,
            showSuggestions: user.canEditDocuments,
          ),
        ),

        if (user.canViewCorrespondents)
          Padding(
            padding: itemPadding,
            child: SingleLabelSelectionFormBuilderField<Correspondent>(
              name: "correspondent",
              initialValue: data.document.correspondent,
              searchHintText: S.of(context)!.startTyping,
              emptySearchMessage: S.of(context)!.noMatchesFound,
              emptyOptionsMessage: S.of(context)!.noCorrespondentsSetUp,
              labelText: S.of(context)!.correspondent,
              enabled: true,
              prefixIcon: const Icon(Icons.person_outlined),
              onAddLabel: (context, searchText) {
                return CreateLabelRoute(
                  LabelType.correspondent,
                  name: searchText,
                ).push<int>(context);
              },
              optionsSelector: (repository) => repository.correspondents,
              addNewLabelText: S.of(context)!.addNewCorrespondent,
              suggestions: data.fieldSuggestions.correspondents,
              showSuggestions: user.canEditDocuments,
            ),
          ),

        // DocumentType form field
        if (user.canViewDocumentTypes)
          Padding(
            padding: itemPadding,
            child: SingleLabelSelectionFormBuilderField<DocumentType>(
              name: "documentType",
              initialValue: data.document.documentType,
              searchHintText: S.of(context)!.startTyping,
              emptySearchMessage: S.of(context)!.noMatchesFound,
              emptyOptionsMessage: S.of(context)!.noDocumentTypesSetUp,
              labelText: S.of(context)!.documentType,
              enabled: true,
              prefixIcon: const Icon(Icons.description_outlined),
              onAddLabel: (context, searchText) {
                return CreateLabelRoute(
                  LabelType.documentType,
                  name: searchText,
                ).push<int>(context);
              },
              optionsSelector: (repository) => repository.documentTypes,
              addNewLabelText: S.of(context)!.addNewDocumentType,
            ),
          ),

        // StoragePath form field
        if (user.canViewStoragePaths)
          Padding(
            padding: itemPadding,
            child: SingleLabelSelectionFormBuilderField<StoragePath>(
              name: "storagePath",
              initialValue: data.document.storagePath,
              searchHintText: S.of(context)!.startTyping,
              emptySearchMessage: S.of(context)!.noMatchesFound,
              emptyOptionsMessage: S.of(context)!.noStoragePathsSetUp,
              labelText: S.of(context)!.storagePath,
              enabled: true,
              prefixIcon: const Icon(Icons.folder_outlined),
              onAddLabel: (context, searchText) {
                return CreateLabelRoute(
                  LabelType.storagePath,
                  name: searchText,
                ).push<int>(context);
              },
              optionsSelector: (repository) => repository.storagePaths,
              addNewLabelText: S.of(context)!.addNewStoragePath,
            ),
          ),
        // Tag form field
        if (user.canViewTags)
          Padding(
            padding: itemPadding,
            child: MultiLabelSelectionFormBuilderField<Tag>(
              name: "tags",
              searchHintText: S.of(context)!.startTyping,
              emptySearchMessage: S.of(context)!.noMatchesFound,
              emptyOptionsMessage: S.of(context)!.noTagsSetUp,
              labelText: S.of(context)!.tags,
              enabled: true,
              prefixIcon: const Icon(Icons.label_outline),
              onAddLabel: (context, searchText) {
                return CreateLabelRoute(
                  LabelType.tag,
                  name: searchText,
                ).push<int>(context);
              },
              displayOptionBuilder: (context, label, onDelete) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    label.name,
                    style: TextStyle(color: label.textColor),
                  ),
                  onDeleted: onDelete,
                  backgroundColor: label.color,
                  deleteIcon: Icon(
                    Icons.clear,
                    color: label.textColor,
                  ),
                );
              },
              optionsSelector: (repository) => repository.tags,
              addNewLabelText: S.of(context)!.addNewTag,
            ),
          ),
      ],
    );
  }
}
