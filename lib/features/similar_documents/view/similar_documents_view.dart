import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/translation/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_loading_status.dart';
import 'package:paperless_mobile/features/paged_document_view/view/document_paging_view_mixin.dart';
import 'package:paperless_mobile/features/similar_documents/cubit/similar_documents_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';

class SimilarDocumentsView extends StatefulWidget {
  const SimilarDocumentsView({super.key});

  @override
  State<SimilarDocumentsView> createState() => _SimilarDocumentsViewState();
}

class _SimilarDocumentsViewState extends State<SimilarDocumentsView>
    with DocumentPagingViewMixin<SimilarDocumentsView, SimilarDocumentsCubit> {
  @override
  void initState() {
    super.initState();
    try {
      context.read<SimilarDocumentsCubit>().initialize();
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          !previous.isConnected && current.isConnected,
      listener: (context, state) =>
          context.read<SimilarDocumentsCubit>().initialize(),
      builder: (context, connectivity) {
        return BlocBuilder<SimilarDocumentsCubit, SimilarDocumentsState>(
          builder: (context, state) {
            if (!connectivity.isConnected &&
                state.status != PagedLoadingStatus.loaded) {
              return const SliverToBoxAdapter(
                child: OfflineWidget(),
              );
            }
            if (state.error != null) {
              return Center(
                child: Text(
                  translateError(context, state.error!),
                  textAlign: TextAlign.center,
                ),
              ).padded();
            }
            if (state.status == PagedLoadingStatus.loaded &&
                !(state.status == PagedLoadingStatus.loading ||
                    state.status == PagedLoadingStatus.loadingMore) &&
                state.documents.isEmpty) {
              return Center(
                child: Text(S.of(context)!.noItemsFound),
              );
            }
            return DefaultAdaptiveDocumentsView(
              documents: state.documents,
              hasInternetConnection: connectivity.isConnected,
              isLabelClickable: false,
              isLoading: state.status == PagedLoadingStatus.loading,
              hasLoaded: state.status == PagedLoadingStatus.loaded,
              enableHeroAnimation: false,
              onTap: (document) {
                DocumentDetailsRoute(
                  title: document.title,
                  id: document.id,
                  thumbnailUrl: document.buildThumbnailUrl(context),
                  isLabelClickable: false,
                ).push(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  ScrollController get pagingScrollController => ScrollController();
}
