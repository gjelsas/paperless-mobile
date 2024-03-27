part of 'saved_view_details_cubit.dart';

class SavedViewDetailsState extends DocumentPagingState {
  final ViewType viewType;

  const SavedViewDetailsState({
    super.status,
    this.viewType = ViewType.list,
    super.filter = const DocumentFilter(),
    super.value,
    super.all,
  });

  @override
  List<Object?> get props => [
        viewType,
        ...super.props,
      ];

  @override
  SavedViewDetailsState copyWithPaged({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<int>? all,
  }) {
    return copyWith(
      status: status,
      value: value,
      filter: filter,
    );
  }

  SavedViewDetailsState copyWith({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    ViewType? viewType,
    Map<int, Correspondent>? correspondents,
    Map<int, DocumentType>? documentTypes,
    Map<int, Tag>? tags,
    Map<int, StoragePath>? storagePaths,
    List<int>? all,
  }) {
    return SavedViewDetailsState(
      status: status ?? this.status,
      all: all ?? this.all,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      viewType: viewType ?? this.viewType,
    );
  }
}
