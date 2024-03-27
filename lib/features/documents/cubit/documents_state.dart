part of 'documents_cubit.dart';

class DocumentsState extends DocumentPagingState {
  final List<DocumentModel> selection;
  final List<int>? allDocumentIds;
  final ViewType viewType;

  const DocumentsState({
    this.selection = const [],
    this.viewType = ViewType.list,
    this.allDocumentIds,
    super.value = const [],
    super.filter = const DocumentFilter(),
    super.hasLoaded = false,
    super.isLoading = false,
  });

  List<int> get selectedIds => selection.map((e) => e.id).toList();

  DocumentsState copyWith({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<DocumentModel>? selection,
    ViewType? viewType,
    List<int>? allDocumentIds,
  }) {
    return DocumentsState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      selection: selection ?? this.selection,
      viewType: viewType ?? this.viewType,
      allDocumentIds: allDocumentIds ?? this.allDocumentIds,
    );
  }

  @override
  List<Object?> get props => [
        selection,
        viewType,
        allDocumentIds,
        super.filter,
        super.hasLoaded,
        super.isLoading,
        super.value,
      ];

  @override
  DocumentsState copyWithPaged({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
  }) {
    return copyWith(
      filter: filter,
      hasLoaded: hasLoaded,
      isLoading: isLoading,
      value: value,
    );
  }
}
