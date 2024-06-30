part of 'similar_documents_cubit.dart';

class SimilarDocumentsState extends DocumentPagingState {
  final ErrorCode? error;
  const SimilarDocumentsState({
    required super.filter,
    super.value,
    this.error,
    super.status,
    super.all,
  });

  @override
  List<Object?> get props => [
        filter,
        value,
        error,
        ...super.props,
      ];

  @override
  SimilarDocumentsState copyWithPaged({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<int>? all,
  }) {
    return copyWith(
      value: value,
      filter: filter,
      status: status,
      all: all,
    );
  }

  SimilarDocumentsState copyWith({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    ErrorCode? error,
    List<int>? all,
  }) {
    return SimilarDocumentsState(
      status: status ?? this.status,
      all: all ?? this.all,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}
