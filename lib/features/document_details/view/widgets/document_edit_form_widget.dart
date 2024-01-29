import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/multi_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/single_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';

class DocumentEditFormWidget extends StatefulWidget {
  final DocumentModel document;
  final String titleKey;
  final String correspondentKey;
  final String tagsKey;
  final String createdKey;
  final String documentTypeKey;
  final String storagePathKey;

  const DocumentEditFormWidget({
    super.key,
    required this.document,
    required this.titleKey,
    required this.correspondentKey,
    required this.tagsKey,
    required this.createdKey,
    required this.documentTypeKey,
    required this.storagePathKey,
  });

  @override
  State<DocumentEditFormWidget> createState() => _DocumentEditFormWidgetState();
}

class _DocumentEditFormWidgetState extends State<DocumentEditFormWidget> {
  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        _buildTitleFormField(context),
        _buildCreatedFormField(context),
        _buildCorrespondentFormField(context),
        _buildDocumentTypeFormField(context),
        _buildStoragePathFormField(context),
        _buildTagsFormField(context)
      ],
    );
  }

  Widget _buildTagsFormField(BuildContext context) {
    return MultiLabelSelectionFormBuilderField<Tag>(
      name: widget.tagsKey,
      initialValue: widget.document.tags,
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
      optionsSelector: (repository) => repository.tags,
      addNewLabelText: S.of(context)!.addNewTag,
    );
  }

  Widget _buildStoragePathFormField(BuildContext context) {
    return SingleLabelSelectionFormBuilderField<StoragePath>(
      name: widget.storagePathKey,
      initialValue: widget.document.storagePath,
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
    );
  }

  Widget _buildDocumentTypeFormField(BuildContext context) {
    return SingleLabelSelectionFormBuilderField<DocumentType>(
      name: widget.documentTypeKey,
      initialValue: widget.document.documentType,
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
    );
  }

  Widget _buildCorrespondentFormField(BuildContext context) {
    return SingleLabelSelectionFormBuilderField<Correspondent>(
      name: widget.correspondentKey,
      initialValue: widget.document.correspondent,
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
    );
  }

  Widget _buildCreatedFormField(BuildContext context) {
    return FormBuilderLocalizedDatePicker(
      name: widget.createdKey,
      initialValue: widget.document.created,
      labelText: S.of(context)!.createdAt,
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(2100, 1, 1),
      locale: Localizations.localeOf(context),
      prefixIcon: const Icon(Icons.calendar_today),
    );
  }

  Widget _buildTitleFormField(BuildContext context) {
    return FormBuilderField<String>(
      name: widget.titleKey,
      initialValue: widget.document.title,
      builder: (field) {
        return TextFormField(
          initialValue: field.value,
          onChanged: (value) {
            field.didChange(value);
          },
          decoration: InputDecoration(
            label: Text(S.of(context)!.title),
            suffixIcon: field.value?.isNotEmpty ?? false
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      field.didChange(null);
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
