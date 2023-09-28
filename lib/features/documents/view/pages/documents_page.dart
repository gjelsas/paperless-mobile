import 'package:collection/collection.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/adaptive_documents_view.dart';
import 'package:paperless_mobile/features/documents/view/widgets/documents_empty_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/saved_views/saved_view_changed_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/saved_views/saved_views_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_panel.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/confirm_delete_saved_view_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/document_selection_sliver_app_bar.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/view_type_selection_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/sort_documents_button.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routes/typed/branches/documents_route.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DocumentFilterIntent {
  final DocumentFilter? filter;
  final bool shouldReset;

  DocumentFilterIntent({
    this.filter,
    this.shouldReset = false,
  });
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();

  final SliverOverlapAbsorberHandle savedViewsHandle =
      SliverOverlapAbsorberHandle();

  final _nestedScrollViewKey = GlobalKey<NestedScrollViewState>();

  final _savedViewsExpansionController = ExpansionTileController();
  bool _showExtendedFab = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nestedScrollViewKey.currentState!.innerController
          .addListener(_scrollExtentChangedListener);
    });
  }

  Future<void> _reloadData() async {
    try {
      await Future.wait([
        context.read<DocumentsCubit>().reload(),
        context.read<SavedViewCubit>().reload(),
        context.read<LabelCubit>().reload(),
      ]);
    } catch (error, stackTrace) {
      showGenericError(context, error, stackTrace);
    }
  }

  void _scrollExtentChangedListener() {
    const threshold = 400;
    final offset =
        _nestedScrollViewKey.currentState!.innerController.position.pixels;
    if (offset < threshold && _showExtendedFab == false) {
      setState(() {
        _showExtendedFab = true;
      });
    } else if (offset >= threshold && _showExtendedFab == true) {
      setState(() {
        _showExtendedFab = false;
      });
    }
  }

  @override
  void dispose() {
    _nestedScrollViewKey.currentState?.innerController
        .removeListener(_scrollExtentChangedListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskStatusCubit, TaskStatusState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (context, state) {
        showSnackBar(
          context,
          S.of(context)!.newDocumentAvailable,
          action: SnackBarActionConfig(
            label: S.of(context)!.reload,
            onPressed: () {
              context.read<TaskStatusCubit>().acknowledgeCurrentTask();
              context.read<DocumentsCubit>().reload();
            },
          ),
          duration: const Duration(seconds: 10),
        );
      },
      child: BlocConsumer<ConnectivityCubit, ConnectivityState>(
        listenWhen: (previous, current) =>
            previous != ConnectivityState.connected &&
            current == ConnectivityState.connected,
        listener: (context, state) {
          _reloadData();
        },
        builder: (context, connectivityState) {
          return SafeArea(
            top: true,
            child: Scaffold(
              drawer: const AppDrawer(),
              floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
                builder: (context, state) {
                  final show = state.selection.isEmpty;
                  final canReset = state.filter.appliedFiltersCount > 0;
                  if (show) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DeferredPointerHandler(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              FloatingActionButton.extended(
                                extendedPadding: _showExtendedFab
                                    ? null
                                    : const EdgeInsets.symmetric(
                                        horizontal: 16),
                                heroTag: "fab_documents_page_filter",
                                label: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(
                                        sizeFactor: animation,
                                        axis: Axis.horizontal,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _showExtendedFab
                                      ? Row(
                                          children: [
                                            const Icon(
                                              Icons.filter_alt_outlined,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              S.of(context)!.filterDocuments,
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.filter_alt_outlined),
                                ),
                                onPressed: _openDocumentFilter,
                              ),
                              if (canReset)
                                Positioned(
                                  top: -20,
                                  right: -8,
                                  child: DeferPointer(
                                    paintOnTop: true,
                                    child: Material(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          _onResetFilter();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (_showExtendedFab)
                                              Text(
                                                "Reset (${state.filter.appliedFiltersCount})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onError,
                                                    ),
                                              ).padded()
                                            else
                                              Icon(
                                                Icons.replay,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onError,
                                              ).padded(4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              resizeToAvoidBottomInset: true,
              body: WillPopScope(
                onWillPop: () async {
                  if (context
                      .read<DocumentsCubit>()
                      .state
                      .selection
                      .isNotEmpty) {
                    context.read<DocumentsCubit>().resetSelection();
                    return false;
                  }
                  return true;
                },
                child: NestedScrollView(
                  key: _nestedScrollViewKey,
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverOverlapAbsorber(
                      handle: searchBarHandle,
                      sliver: BlocBuilder<DocumentsCubit, DocumentsState>(
                        builder: (context, state) {
                          if (state.selection.isEmpty) {
                            return SliverSearchBar(
                              floating: true,
                              titleText: S.of(context)!.documents,
                            );
                          } else {
                            return DocumentSelectionSliverAppBar(
                              state: state,
                            );
                          }
                        },
                      ),
                    ),
                    SliverOverlapAbsorber(
                      handle: savedViewsHandle,
                      sliver: SliverPinnedHeader(
                        child: Material(
                          child: _buildViewActions(),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                  body: _buildDocumentsTab(
                    connectivityState,
                    context,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentsTab(
    ConnectivityState connectivityState,
    BuildContext context,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Listen for scroll notifications to load new data.
        // Scroll controller does not work here due to nestedscrollview limitations.
        final offset = notification.metrics.pixels;
        if (offset > 128 && _savedViewsExpansionController.isExpanded) {
          _savedViewsExpansionController.collapse();
        }

        final max = notification.metrics.maxScrollExtent;
        final currentState = context.read<DocumentsCubit>().state;
        if (max == 0 ||
            currentState.isLoading ||
            currentState.isLastPageLoaded) {
          return false;
        }

        if (offset >= max * 0.7) {
          context
              .read<DocumentsCubit>()
              .loadMore()
              .onError<PaperlessApiException>(
                (error, stackTrace) => showErrorMessage(
                  context,
                  error,
                  stackTrace,
                ),
              );
          return true;
        }
        return false;
      },
      child: RefreshIndicator(
        edgeOffset: kTextTabBarHeight + 2,
        onRefresh: _reloadData,
        notificationPredicate: (_) => connectivityState.isConnected,
        child: CustomScrollView(
          key: const PageStorageKey<String>("documents"),
          slivers: <Widget>[
            SliverOverlapInjector(handle: searchBarHandle),
            SliverOverlapInjector(handle: savedViewsHandle),
            SliverToBoxAdapter(
              child: BlocBuilder<DocumentsCubit, DocumentsState>(
                buildWhen: (previous, current) =>
                    previous.filter != current.filter,
                builder: (context, state) {
                  final currentUser = context.watch<LocalUserAccount>();
                  if (!currentUser.paperlessUser.canViewSavedViews) {
                    return const SizedBox.shrink();
                  }
                  return SavedViewsWidget(
                    controller: _savedViewsExpansionController,
                    onViewSelected: (view) {
                      final cubit = context.read<DocumentsCubit>();
                      if (state.filter.selectedView == view.id) {
                        _onResetFilter();
                      } else {
                        cubit.updateFilter(
                          filter: view.toDocumentFilter(),
                        );
                      }
                    },
                    onUpdateView: (view) async {
                      await context.read<SavedViewCubit>().update(view);
                      showSnackBar(
                          context, S.of(context)!.savedViewSuccessfullyUpdated);
                    },
                    onDeleteView: (view) async {
                      HapticFeedback.mediumImpact();
                      final shouldRemove = await showDialog(
                        context: context,
                        builder: (context) =>
                            ConfirmDeleteSavedViewDialog(view: view),
                      );
                      if (shouldRemove) {
                        final documentsCubit = context.read<DocumentsCubit>();
                        context.read<SavedViewCubit>().remove(view);
                        if (documentsCubit.state.filter.selectedView ==
                            view.id) {
                          documentsCubit.resetFilter();
                        }
                      }
                    },
                    filter: state.filter,
                  );
                },
              ),
            ),
            BlocBuilder<DocumentsCubit, DocumentsState>(
              builder: (context, state) {
                if (state.hasLoaded && state.documents.isEmpty) {
                  return SliverToBoxAdapter(
                    child: DocumentsEmptyState(
                      state: state,
                      onReset: _onResetFilter,
                    ),
                  );
                }
                final allowToggleFilter = state.selection.isEmpty;
                return SliverAdaptiveDocumentsView(
                  viewType: state.viewType,
                  onTap: (document) {
                    DocumentDetailsRoute($extra: document).push(context);
                  },
                  onSelected:
                      context.read<DocumentsCubit>().toggleDocumentSelection,
                  hasInternetConnection: connectivityState.isConnected,
                  onTagSelected: allowToggleFilter ? _addTagToFilter : null,
                  onCorrespondentSelected:
                      allowToggleFilter ? _addCorrespondentToFilter : null,
                  onDocumentTypeSelected:
                      allowToggleFilter ? _addDocumentTypeToFilter : null,
                  onStoragePathSelected:
                      allowToggleFilter ? _addStoragePathToFilter : null,
                  documents: state.documents,
                  hasLoaded: state.hasLoaded,
                  isLabelClickable: true,
                  isLoading: state.isLoading,
                  selectedDocumentIds: state.selectedIds,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewActions() {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(4),
          color: Theme.of(context).colorScheme.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SortDocumentsButton(
                enabled: state.selection.isEmpty,
              ),
              ViewTypeSelectionWidget(
                viewType: state.viewType,
                onChanged: context.read<DocumentsCubit>().setViewType,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDocumentFilter() async {
    final draggableSheetController = DraggableScrollableController();
    final filterIntent = await showModalBottomSheet<DocumentFilterIntent>(
      useSafeArea: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentsCubit>(),
        child: DraggableScrollableSheet(
          controller: draggableSheetController,
          expand: false,
          snap: true,
          snapSizes: const [0.9, 1],
          initialChildSize: .9,
          maxChildSize: 1,
          builder: (context, controller) =>
              BlocBuilder<DocumentsCubit, DocumentsState>(
            builder: (context, state) {
              return DocumentFilterPanel(
                initialFilter: context.read<DocumentsCubit>().state.filter,
                scrollController: controller,
                draggableSheetController: draggableSheetController,
                correspondents: state.correspondents,
                documentTypes: state.documentTypes,
                storagePaths: state.storagePaths,
                tags: state.tags,
              );
            },
          ),
        ),
      ),
    );
    if (filterIntent != null) {
      try {
        if (filterIntent.shouldReset) {
          await _onResetFilter();
        } else {
          await context
              .read<DocumentsCubit>()
              .updateFilter(filter: filterIntent.filter!);
        }
      } on PaperlessApiException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _addTagToFilter(int tagId) {
    final cubit = context.read<DocumentsCubit>();
    try {
      cubit.state.filter.tags.maybeMap(
        ids: (state) {
          if (state.include.contains(tagId)) {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                tags: state.copyWith(
                  include: state.include
                      .whereNot((element) => element == tagId)
                      .toList(),
                ),
              ),
            );
          } else if (state.exclude.contains(tagId)) {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                tags: state.copyWith(
                  exclude: state.exclude
                      .whereNot((element) => element == tagId)
                      .toList(),
                ),
              ),
            );
          } else {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                tags: state.copyWith(include: [...state.include, tagId]),
              ),
            );
          }
        },
        orElse: () {
          cubit.updateCurrentFilter(
            (filter) => filter.copyWith(tags: TagsQuery.ids(include: [tagId])),
          );
        },
      );
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addCorrespondentToFilter(int? correspondentId) {
    if (correspondentId == null) return;
    final cubit = context.read<DocumentsCubit>();

    try {
      cubit.state.filter.correspondent.maybeWhen(
        fromId: (id) {
          if (id == correspondentId) {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                  correspondent: const IdQueryParameter.unset()),
            );
          } else {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                  correspondent: IdQueryParameter.fromId(correspondentId)),
            );
          }
        },
        orElse: () {
          cubit.updateCurrentFilter(
            (filter) => filter.copyWith(
                correspondent: IdQueryParameter.fromId(correspondentId)),
          );
        },
      );
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addDocumentTypeToFilter(int? documentTypeId) {
    if (documentTypeId == null) return;
    final cubit = context.read<DocumentsCubit>();

    try {
      cubit.state.filter.documentType.maybeWhen(
        fromId: (id) {
          if (id == documentTypeId) {
            cubit.updateCurrentFilter(
              (filter) =>
                  filter.copyWith(documentType: const IdQueryParameter.unset()),
            );
          } else {
            cubit.updateCurrentFilter(
              (filter) => filter.copyWith(
                  documentType: IdQueryParameter.fromId(documentTypeId)),
            );
          }
        },
        orElse: () {
          cubit.updateCurrentFilter(
            (filter) => filter.copyWith(
                documentType: IdQueryParameter.fromId(documentTypeId)),
          );
        },
      );
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _addStoragePathToFilter(int? pathId) {
    if (pathId == null) return;
    final cubit = context.read<DocumentsCubit>();

    try {
      cubit.state.filter.storagePath.maybeWhen(
        fromId: (id) {
          if (id == pathId) {
            cubit.updateCurrentFilter(
              (filter) =>
                  filter.copyWith(storagePath: const IdQueryParameter.unset()),
            );
          } else {
            cubit.updateCurrentFilter(
              (filter) =>
                  filter.copyWith(storagePath: IdQueryParameter.fromId(pathId)),
            );
          }
        },
        orElse: () {
          cubit.updateCurrentFilter(
            (filter) =>
                filter.copyWith(storagePath: IdQueryParameter.fromId(pathId)),
          );
        },
      );
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  ///
  /// Resets the current filter and scrolls all the way to the top of the view.
  /// If a saved view is currently selected and the filter has changed,
  /// the user will be shown a dialog informing them about the changes.
  /// The user can then decide whether to abort the reset or to continue and discard the changes.
  Future<void> _onResetFilter() async {
    final cubit = context.read<DocumentsCubit>();
    final savedViewCubit = context.read<SavedViewCubit>();

    void toTop() async {
      await _nestedScrollViewKey.currentState?.outerController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final activeView = savedViewCubit.state.mapOrNull(
      loaded: (state) {
        if (cubit.state.filter.selectedView != null) {
          return state.savedViews[cubit.state.filter.selectedView!];
        }
        return null;
      },
    );
    final viewHasChanged = activeView != null &&
        activeView.toDocumentFilter() != cubit.state.filter;
    if (viewHasChanged) {
      final discardChanges = await showDialog<bool>(
            context: context,
            builder: (context) => const SavedViewChangedDialog(),
          ) ??
          false;
      if (discardChanges) {
        cubit.resetFilter();
        toTop();
      }
    } else {
      cubit.resetFilter();
      toTop();
    }
  }
}
