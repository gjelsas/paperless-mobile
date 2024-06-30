part of 'inbox_cubit.dart';

@JsonSerializable(ignoreUnannotated: true)
class InboxState extends DocumentPagingState {
  final Iterable<int> inboxTags;

  final int itemsInInboxCount;

  @JsonKey()
  final bool isHintAcknowledged;

  const InboxState({
    super.value = const [],
    super.filter = const DocumentFilter(),
    this.inboxTags = const [],
    this.isHintAcknowledged = false,
    this.itemsInInboxCount = 0,
    super.all = const [],
    super.status = PagedLoadingStatus.initial,
  });

  @override
  List<Object?> get props => [
        value,
        filter,
        inboxTags,
        documents,
        isHintAcknowledged,
        itemsInInboxCount,
        ...super.props,
      ];

  InboxState copyWith({
    PagedLoadingStatus? status,
    Iterable<int>? inboxTags,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    bool? isHintAcknowledged,
    Map<int, FieldSuggestions>? suggestions,
    int? itemsInInboxCount,
    List<int>? all,
  }) {
    return InboxState(
      status: status ?? this.status,
      value: value ?? super.value,
      inboxTags: inboxTags ?? this.inboxTags,
      isHintAcknowledged: isHintAcknowledged ?? this.isHintAcknowledged,
      filter: filter ?? super.filter,
      itemsInInboxCount: itemsInInboxCount ?? this.itemsInInboxCount,
      all: all ?? this.all,
    );
  }

  factory InboxState.fromJson(Map<String, dynamic> json) =>
      _$InboxStateFromJson(json);

  Map<String, dynamic> toJson() => _$InboxStateToJson(this);

  @override
  InboxState copyWithPaged({
    List<int>? all,
    PagedLoadingStatus? status,
    List<PagedSearchResult<DocumentModel>>? value,
    // Filter does not change when inbox is open, therefore this is never really used.
    DocumentFilter? filter,
  }) {
    return copyWith(
      all: all,
      status: status,
      value: value,
      filter: filter,
    );
  }
}
