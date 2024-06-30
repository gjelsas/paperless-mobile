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
    super.all,
    super.status,
  });

  List<int> get selectedIds => selection.map((e) => e.id).toList();

  DocumentsState copyWith({
    PagedLoadingStatus? status,
    List<int>? all,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<DocumentModel>? selection,
    ViewType? viewType,
    List<int>? allDocumentIds,
  }) {
    return DocumentsState(
      value: value ?? this.value,
      filter: filter ?? this.filter,
      selection: selection ?? this.selection,
      viewType: viewType ?? this.viewType,
      allDocumentIds: allDocumentIds ?? this.allDocumentIds,
      status: status ?? this.status,
      all: all ?? this.all,
    );
  }

  @override
  List<Object?> get props => [
        selection,
        viewType,
        allDocumentIds,
        ...super.props,
      ];

  @override
  DocumentsState copyWithPaged({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<int>? all,
  }) {
    return copyWith(
      filter: filter,
      value: value,
      all: all,
      status: status,
    );
  }
}
