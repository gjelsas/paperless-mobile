// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/translation/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/pop_with_unsaved_changes.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_download_button.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_meta_data_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_notes_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_overview_edit_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_permissions_widget.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_share_button.dart';
import 'package:paperless_mobile/features/document_viewer/view/document_viewer.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/similar_documents/cubit/similar_documents_cubit.dart';
import 'package:paperless_mobile/features/similar_documents/view/similar_documents_view.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';
import 'package:provider/provider.dart';

class DocumentDetailsPage extends StatefulWidget {
  final int id;
  final String? title;
  final bool isLabelClickable;
  final String? titleAndContentQueryString;
  final String? thumbnailUrl;
  final String? heroTag;

  const DocumentDetailsPage({
    super.key,
    this.isLabelClickable = true,
    this.titleAndContentQueryString,
    this.thumbnailUrl,
    required this.id,
    this.heroTag,
    this.title,
  });

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  final _contentScrollController = ScrollController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiUserSupport =
        context.watch<LocalUserAccount>().hasMultiUserSupport;
    final tabLength = 5 + (hasMultiUserSupport ? 1 : 0);
    return DefaultTabController(
      length: tabLength,
      child: Theme(
        data: Theme.of(context).copyWith(
            navigationRailTheme: const NavigationRailThemeData(
          labelType: NavigationRailLabelType.none,
        )),
        child: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: Scaffold(
            body: BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
              builder: (context, state) {
                switch (state.status) {
                  case LoadingStatus.initial || LoadingStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  case LoadingStatus.error:
                    return Center(
                      child: Column(
                        children: [
                          const Text("Data could not be loaded."),
                          ElevatedButton(
                            child: const Text("Try again"),
                            onPressed: () {
                              context.read<DocumentDetailsCubit>().initialize();
                            },
                          ),
                        ],
                      ),
                    );
                  case LoadingStatus.loaded:
                    final data = state.data!;
                    return OrientationBuilder(
                      builder: (context, orientation) => AdaptiveLayout(
                        internalAnimations: false,
                        // bodyOrientation: switch (orientation) {
                        //   Orientation.portrait => Axis.vertical,
                        //   Orientation.landscape => Axis.horizontal,
                        // },
                        topNavigation: SlotLayout(
                          config: {
                            Breakpoints.standard: SlotLayout.from(
                              key: Key("Top App Bar"),
                              builder: (context) {
                                return SizedBox(
                                  height: kToolbarHeight + kTextTabBarHeight,
                                  child: _buildAppBar(data),
                                );
                              },
                            ),
                          },
                        ),
                        body: SlotLayout(
                          config: {
                            Breakpoints.standard: SlotLayout.from(
                              key: Key("details-primary-body"),
                              builder: (context) {
                                return _buildPrimaryBody(data);
                              },
                            ),
                          },
                        ),
                        secondaryBody: SlotLayout(
                          config: {
                            Breakpoints.mediumAndUp: SlotLayout.from(
                              key: Key("details-secondary-body"),
                              builder: (context) {
                                return DocumentViewerRoute(
                                  id: data.document.id,
                                  isFullscreen: false,
                                ).build(
                                  context,
                                  GoRouterState.of(context),
                                );
                              },
                            ),
                          },
                        ),
                      ),
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryBody(
    DocumentDetailsData data,
  ) {
    return Scaffold(
      bottomNavigationBar: _buildBottomAppBar(data),
      body: PopWithUnsavedChanges(
        hasChangesPredicate: () => _hasUnsavedChanges(data.document),
        child: FormBuilder(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: _formFields(data),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(DocumentDetailsData data) {
    final hasMultiUserSupport =
        context.watch<LocalUserAccount>().hasMultiUserSupport;
    return AppBar(
      title: Text(data.document.title),
      actions: [
        IconButton(
          icon: Icon(Icons.preview_outlined),
          onPressed: () {
            DocumentViewerRoute(
              id: data.document.id,
              title: data.document.title,
              scrollDirection: Axis.horizontal,
              isFullscreen: true,
            ).push(context);
          },
        ),
        DocumentShareButton(document: data.document),
        ConnectivityAwareActionWrapper(
          disabled: !context
              .watch<LocalUserAccount>()
              .paperlessUser
              .canDeleteDocuments,
          offlineBuilder: (context, child) {
            return const IconButton(
              icon: Icon(Icons.delete),
              onPressed: null,
            );
          },
          child: IconButton(
            tooltip: S.of(context)!.deleteDocumentTooltip,
            icon: const Icon(Icons.delete),
            onPressed: () => _onDelete(data.document),
          ),
        ),
      ],
      bottom: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: S.of(context)!.overview),
          Tab(text: S.of(context)!.content),
          Tab(text: S.of(context)!.metaData),
          Tab(text: S.of(context)!.notes(0)),
          Tab(text: S.of(context)!.similarDocuments),
          if (hasMultiUserSupport) Tab(text: S.of(context)!.permissions),
        ],
      ),
    );
  }

  List<Widget> _formFields(DocumentDetailsData data) {
    return [
      DocumentOverviewEditWidget(
        data: data,
        itemPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        verticalPadding: 16,
      ),
      Scrollbar(
        controller: _contentScrollController,
        interactive: true,
        child: FormBuilderTextField(
          scrollController: _contentScrollController,
          name: "content",
          initialValue: data.document.content,
          maxLines: null,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
          ),
        ),
      ),
      DocumentMetaDataWidget(
        padding: EdgeInsets.all(16),
        document: data.document,
        metaData: data.metaData,
        itemSpacing: 16,
      ),
      DocumentNotesWidget(
        document: data.document,
      ),
      Provider(
        create: (context) => SimilarDocumentsCubit(
          context.read(),
          context.read(),
          context.read(),
          documentId: data.document.id,
        ),
        child: const SimilarDocumentsView(),
      ),
      DocumentPermissionsWidget(
        document: data.document,
      ),
    ];
  }

  Widget _buildBottomAppBar(DocumentDetailsData data) {
    final currentUser = context.watch<LocalUserAccount>();
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ConnectivityAwareActionWrapper(
            offlineBuilder: (context, child) => const DocumentDownloadButton(
              document: null,
              enabled: false,
            ),
            child: DocumentDownloadButton(
              document: data.document,
            ),
          ),
          ConnectivityAwareActionWrapper(
            offlineBuilder: (context, child) => const IconButton(
              icon: Icon(Icons.open_in_new),
              onPressed: null,
            ),
            child: IconButton(
              tooltip: S.of(context)!.openInSystemViewer,
              icon: const Icon(Icons.open_in_new),
              onPressed: _onOpenFileInSystemViewer,
            ).paddedOnly(right: 4.0),
          ),
          IconButton(
            tooltip: S.of(context)!.print,
            onPressed: () =>
                context.read<DocumentDetailsCubit>().printDocument(),
            icon: const Icon(Icons.print),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _hasUnsavedChanges(data.document)
                ? () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      setState(() => _isSaving = true);
                      try {
                        final updatedDocument =
                            _mergeFormIntoDocument(data.document);
                        FocusScope.of(context).unfocus();
                        await context
                            .read<DocumentDetailsCubit>()
                            .updateDocument(updatedDocument);
                        showSnackBar(context,
                            S.of(context)!.documentSuccessfullyUpdated);
                      } finally {
                        setState(() => _isSaving = false);
                      }
                    }
                  }
                : null,
            label: Text(S.of(context)!.save),
            icon: const Icon(Icons.save).loading(
              loading: _isSaving,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  DocumentModel _mergeFormIntoDocument(DocumentModel document) {
    final form = _formKey.currentState!;
    final title = form.getRawValue('title') as String?;
    final asn = form.getRawValue('asn') as int?;
    final createdAt = form.getRawValue('createdAt') as FormDateTime?;
    final correspondent = form.getRawValue('correspondent') as int?;
    final documentType = form.getRawValue('documentType') as int?;
    final storagePath = form.getRawValue('storagePath') as int?;
    final tags = form.getRawValue('tags') as Iterable<int>?;
    final content = form.getRawValue('content') as String?;
    return document.copyWith(
      title: title,
      archiveSerialNumber: () => asn,
      created: createdAt?.toDateTime(),
      correspondent: () => correspondent,
      documentType: () => documentType,
      storagePath: () => storagePath,
      tags: tags,
      content: content,
    );
  }

  bool _hasUnsavedChanges(DocumentModel? initialDocument) {
    final currentState = _formKey.currentState;
    if (currentState == null) return false;
    if (initialDocument == null) return false;
    final formDocument = _mergeFormIntoDocument(initialDocument);
    return initialDocument != formDocument;
  }

  void _onOpenFileInSystemViewer() async {
    final status =
        await context.read<DocumentDetailsCubit>().openDocumentInSystemViewer();
    if (status == ResultType.done) return;
    if (status == ResultType.noAppToOpen) {
      showGenericError(context, S.of(context)!.noAppToDisplayPDFFilesFound);
    }
    if (status == ResultType.fileNotFound) {
      showGenericError(context, translateError(context, ErrorCode.unknown));
    }
    if (status == ResultType.permissionDenied) {
      showGenericError(
          context, S.of(context)!.couldNotOpenFilePermissionDenied);
    }
  }

  void _onDelete(DocumentModel document) async {
    final delete = await showDialog(
          context: context,
          builder: (context) =>
              DeleteDocumentConfirmationDialog(document: document),
        ) ??
        false;
    if (delete) {
      try {
        await context.read<DocumentDetailsCubit>().delete(document);
        // showSnackBar(context, S.of(context)!.documentSuccessfullyDeleted);
      } on PaperlessApiException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } finally {
        do {
          context.pop();
        } while (context.canPop());
      }
    }
  }
}
