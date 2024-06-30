part of 'linked_documents_cubit.dart';

@JsonSerializable(ignoreUnannotated: true)
class LinkedDocumentsState extends DocumentPagingState {
  @JsonKey()
  final ViewType viewType;

  const LinkedDocumentsState({
    this.viewType = ViewType.list,
    super.filter = const DocumentFilter(),
    super.value,
    super.status,
    super.all,
  });

  LinkedDocumentsState copyWith({
    DocumentFilter? filter,
    PagedLoadingStatus? status,
    List<int>? all,
    List<PagedSearchResult<DocumentModel>>? value,
    ViewType? viewType,
  }) {
    return LinkedDocumentsState(
      filter: filter ?? this.filter,
      value: value ?? this.value,
      viewType: viewType ?? this.viewType,
      all: all ?? this.all,
      status: status ?? this.status,
    );
  }

  @override
  LinkedDocumentsState copyWithPaged({
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<int>? all,
  }) {
    return copyWith(
      value: value,
      filter: filter,
      all: all,
      status: status,
    );
  }

  @override
  List<Object?> get props => [
        viewType,
        ...super.props,
      ];

  factory LinkedDocumentsState.fromJson(Map<String, dynamic> json) =>
      _$LinkedDocumentsStateFromJson(json);

  Map<String, dynamic> toJson() => _$LinkedDocumentsStateToJson(this);
}
