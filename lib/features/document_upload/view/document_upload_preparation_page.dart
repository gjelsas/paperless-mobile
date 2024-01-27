import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/core/widgets/future_or_builder.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/multi_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/new/single_label_selection_form_builder_field.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/sharing/view/widgets/file_thumbnail.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';

class DocumentUploadResult {
  final bool success;
  final String? taskId;

  DocumentUploadResult(this.success, this.taskId);
}

class DocumentUploadPreparationPage extends StatefulWidget {
  final FutureOr<Uint8List> fileBytes;
  final String? title;
  final String? filename;
  final String? fileExtension;

  const DocumentUploadPreparationPage({
    super.key,
    required this.fileBytes,
    this.title,
    this.filename,
    this.fileExtension,
  });

  @override
  State<DocumentUploadPreparationPage> createState() =>
      _DocumentUploadPreparationPageState();
}

class _DocumentUploadPreparationPageState
    extends State<DocumentUploadPreparationPage> {
  static const fkFileName = "filename";
  static final fileNameDateFormat = DateFormat("yyyy_MM_ddTHH_mm_ss");

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  Map<String, String> _errors = {};
  late bool _syncTitleAndFilename;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncTitleAndFilename = widget.filename == null && widget.title == null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          resizeToAvoidBottomInset: true,
          floatingActionButton: Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom == 0,
            child: FloatingActionButton.extended(
              heroTag: "fab_document_upload",
              onPressed: state.uploadProgress == null ? _onSubmit : null,
              label: state.uploadProgress == null
                  ? Text(S.of(context)!.upload)
                  : Text("Uploading..."), //TODO: INTL
              icon: state.uploadProgress == null
                  ? const Icon(Icons.upload)
                  : SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: state.uploadProgress,
                      )).padded(4),
            ),
          ),
          body: FormBuilder(
            key: _formKey,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    leading: const BackButton(),
                    pinned: true,
                    expandedHeight: 150,
                    flexibleSpace: FlexibleSpaceBar(
                      background: FutureOrBuilder<Uint8List>(
                        future: widget.fileBytes,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return FileThumbnail(
                            bytes: snapshot.data!,
                            fit: BoxFit.fitWidth,
                            width: MediaQuery.sizeOf(context).width,
                          );
                        },
                      ),
                      title: Text(S.of(context)!.prepareDocument),
                      collapseMode: CollapseMode.pin,
                    ),
                  ),
                ),
              ],
              body: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Builder(
                  builder: (context) {
                    return CustomScrollView(
                      slivers: [
                        SliverOverlapInjector(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                        ),
                        SliverList.list(
                          children: [
                            // Title
                            FormBuilderTextField(
                              autovalidateMode: AutovalidateMode.always,
                              name: DocumentModel.titleKey,
                              initialValue: widget.title ??
                                  "scan_${fileNameDateFormat.format(_now)}",
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return S.of(context)!.thisFieldIsRequired;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: S.of(context)!.title,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _formKey.currentState
                                        ?.fields[DocumentModel.titleKey]
                                        ?.didChange("");
                                    if (_syncTitleAndFilename) {
                                      _formKey.currentState?.fields[fkFileName]
                                          ?.didChange("");
                                    }
                                  },
                                ),
                                errorText: _errors[DocumentModel.titleKey],
                              ),
                              onChanged: (value) {
                                final String transformedValue =
                                    _formatFilename(value ?? '');
                                if (_syncTitleAndFilename) {
                                  _formKey.currentState?.fields[fkFileName]
                                      ?.didChange(transformedValue);
                                }
                              },
                            ),
                            // Filename
                            FormBuilderTextField(
                              autovalidateMode: AutovalidateMode.always,
                              readOnly: _syncTitleAndFilename,
                              enabled: !_syncTitleAndFilename,
                              name: fkFileName,
                              decoration: InputDecoration(
                                labelText: S.of(context)!.fileName,
                                suffixText: widget.fileExtension,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _formKey
                                      .currentState?.fields[fkFileName]
                                      ?.didChange(''),
                                ),
                              ),
                              initialValue: widget.filename ??
                                  "scan_${fileNameDateFormat.format(_now)}",
                            ),
                            // Synchronize title and filename
                            SwitchListTile(
                              value: _syncTitleAndFilename,
                              onChanged: (value) {
                                setState(
                                  () => _syncTitleAndFilename = value,
                                );
                                if (_syncTitleAndFilename) {
                                  final String transformedValue =
                                      _formatFilename(_formKey
                                          .currentState
                                          ?.fields[DocumentModel.titleKey]
                                          ?.value as String);
                                  if (_syncTitleAndFilename) {
                                    _formKey.currentState?.fields[fkFileName]
                                        ?.didChange(transformedValue);
                                  }
                                }
                              },
                              title: Text(
                                S.of(context)!.synchronizeTitleAndFilename,
                              ),
                            ),
                            // Created at
                            FormBuilderLocalizedDatePicker(
                              name: DocumentModel.createdKey,
                              firstDate: DateTime(1970, 1, 1),
                              lastDate: DateTime(2100, 1, 1),
                              locale: Localizations.localeOf(context),
                              labelText: S.of(context)!.createdAt + " *",
                              allowUnset: true,
                            ),
                            // Correspondent
                            if (context
                                .watch<LocalUserAccount>()
                                .paperlessUser
                                .canViewCorrespondents)
                              SingleLabelSelectionFormBuilderField<
                                  Correspondent>(
                                name: DocumentModel.correspondentKey,
                                searchHintText: S.of(context)!.startTyping,
                                emptySearchMessage:
                                    S.of(context)!.noMatchesFound,
                                emptyOptionsMessage:
                                    S.of(context)!.noCorrespondentsSetUp,
                                labelText: S.of(context)!.correspondent,
                                enabled: true,
                                prefixIcon: const Icon(Icons.person_outlined),
                                onAddLabel: (context, searchText) {
                                  return CreateLabelRoute(
                                    LabelType.correspondent,
                                    name: searchText,
                                  ).push<int>(context);
                                },
                                optionsSelector: (repository) =>
                                    repository.correspondents,
                                addNewLabelText:
                                    S.of(context)!.addNewCorrespondent,
                              ),

                            // Document type
                            if (context
                                .watch<LocalUserAccount>()
                                .paperlessUser
                                .canViewDocumentTypes)
                              SingleLabelSelectionFormBuilderField<
                                  DocumentType>(
                                name: DocumentModel.documentTypeKey,
                                searchHintText: S.of(context)!.startTyping,
                                emptySearchMessage:
                                    S.of(context)!.noMatchesFound,
                                emptyOptionsMessage:
                                    S.of(context)!.noDocumentTypesSetUp,
                                labelText: S.of(context)!.documentType,
                                enabled: true,
                                prefixIcon:
                                    const Icon(Icons.description_outlined),
                                onAddLabel: (context, searchText) {
                                  return CreateLabelRoute(
                                    LabelType.documentType,
                                    name: searchText,
                                  ).push<int>(context);
                                },
                                optionsSelector: (repository) =>
                                    repository.documentTypes,
                                addNewLabelText:
                                    S.of(context)!.addNewDocumentType,
                              ),
                            if (context
                                .watch<LocalUserAccount>()
                                .paperlessUser
                                .canViewTags)
                              MultiLabelSelectionFormBuilderField<Tag>(
                                name: DocumentModel.tagsKey,
                                searchHintText: S.of(context)!.startTyping,
                                emptySearchMessage:
                                    S.of(context)!.noMatchesFound,
                                emptyOptionsMessage: S.of(context)!.noTagsSetUp,
                                labelText: S.of(context)!.tags,
                                enabled: true,
                                prefixIcon: Icon(Icons.label_outline),
                                onAddLabel: (context, searchText) {
                                  return CreateLabelRoute(
                                    LabelType.tag,
                                    name: searchText,
                                  ).push<int>(context);
                                },
                                optionsSelector: (repository) =>
                                    repository.tags,
                                addNewLabelText: S.of(context)!.addNewTag,
                              ),
                            Text(
                              "* ${S.of(context)!.uploadInferValuesHint}",
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.justify,
                            ).padded(),
                            const SizedBox(height: 300),
                          ].padded(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final cubit = context.read<DocumentUploadCubit>();
      try {
        final formValues = _formKey.currentState!.value;

        final title = formValues[DocumentModel.titleKey] as String;
        final correspondentId =
            formValues[DocumentModel.correspondentKey] as int?;
        final documentTypeId =
            formValues[DocumentModel.documentTypeKey] as int?;
        final storagePathId = formValues[DocumentModel.storagePathKey] as int?;
        final tagIds = formValues[DocumentModel.tagsKey] as Iterable<int>?;
        final created = formValues[DocumentModel.createdKey] as FormDateTime?;
        final asn = formValues[DocumentModel.asnKey] as int?;

        final taskId = await cubit.upload(
          await widget.fileBytes,
          filename: _padWithExtension(
            _formKey.currentState?.value[fkFileName],
            widget.fileExtension,
          ),
          userId: Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
              .getValue()!
              .loggedInUserId!,
          title: title,
          documentType: documentTypeId,
          correspondent: correspondentId,
          tags: tagIds?.toList() ?? [],
          createdAt: created?.toDateTime(),
          asn: asn,
        );
        showSnackBar(
          context,
          S.of(context)!.documentSuccessfullyUploadedProcessing,
        );
        context.pop(DocumentUploadResult(true, taskId));
      } on PaperlessFormValidationException catch (exception) {
        setState(() => _errors = exception.validationMessages);
      } catch (error, stackTrace) {
        logger.fe(
          "An unknown error occurred during document upload.",
          className: runtimeType.toString(),
          methodName: "_onSubmit",
          error: error,
          stackTrace: stackTrace,
        );
        showErrorMessage(
          context,
          const PaperlessApiException.unknown(),
          stackTrace,
        );
      }
    }
  }

  String _padWithExtension(String source, [String? extension]) {
    final ext = extension ?? '.pdf';
    return source.endsWith(ext) ? source : '$source$ext';
  }

  String _formatFilename(String source) {
    return source.replaceAll(RegExp(r"[\W_]"), "_").toLowerCase();
  }

  // Future<Color> _computeAverageColor() async {
  //   final bitmap = img.decodeImage(await widget.fileBytes);
  //   if (bitmap == null) {
  //     return Colors.black;
  //   }
  //   int redBucket = 0;
  //   int greenBucket = 0;
  //   int blueBucket = 0;
  //   int pixelCount = 0;

  //   for (int y = 0; y < bitmap.height; y++) {
  //     for (int x = 0; x < bitmap.width; x++) {
  //       final c = bitmap.getPixel(x, y);

  //       pixelCount++;
  //       redBucket += c.r.toInt();
  //       greenBucket += c.g.toInt();
  //       blueBucket += c.b.toInt();
  //     }
  //   }

  //   return Color.fromRGBO(
  //     redBucket ~/ pixelCount,
  //     greenBucket ~/ pixelCount,
  //     blueBucket ~/ pixelCount,
  //     1,
  //   );
  // }
}
