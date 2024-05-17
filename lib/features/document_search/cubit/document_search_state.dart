part of 'document_search_cubit.dart';

enum SearchView {
  suggestions,
  results;
}

@JsonSerializable(ignoreUnannotated: true)
class DocumentSearchState extends DocumentPagingState {
  final List<String> searchHistory;
  final SearchView view;
  final List<String> suggestions;
  @JsonKey()
  final ViewType viewType;

  const DocumentSearchState({
    this.view = SearchView.suggestions,
    this.searchHistory = const [],
    this.suggestions = const [],
    this.viewType = ViewType.detailed,
    super.filter = const DocumentFilter(),
    super.value,
    super.status = PagedLoadingStatus.initial,
    super.all = const [],
  });

  @override
  List<Object?> get props => [
        ...super.props,
        searchHistory,
        suggestions,
        view,
        viewType,
      ];

  @override
  DocumentSearchState copyWithPaged({
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    PagedLoadingStatus? status,
    List<int>? all,
  }) {
    return copyWith(
      filter: filter,
      value: value,
      status: status,
      all: all,
    );
  }

  DocumentSearchState copyWith({
    List<String>? searchHistory,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<String>? suggestions,
    SearchView? view,
    ViewType? viewType,
    PagedLoadingStatus? status,
    List<int>? all,
  }) {
    return DocumentSearchState(
      value: value ?? this.value,
      filter: filter ?? this.filter,
      status: status ?? this.status,
      searchHistory: searchHistory ?? this.searchHistory,
      view: view ?? this.view,
      suggestions: suggestions ?? this.suggestions,
      viewType: viewType ?? this.viewType,
      all: all ?? this.all,
    );
  }

  factory DocumentSearchState.fromJson(Map<String, dynamic> json) =>
      _$DocumentSearchStateFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentSearchStateToJson(this);
}

// sealed class DocumentSearchState1 {}

// class DocumentSearchStateInitial {}

// class SuggestionsLoadingState extends DocumentSearchState1 {
//   final List<String> history;

//   SuggestionsLoadingState({required this.history});
// }

// class SuggestionsLoadedState extends DocumentSearchState1 {
//   final List<String> history;
//   final List<String> suggestions;

//   SuggestionsLoadedState({
//     required this.history,
//     required this.suggestions,
//   });
// }

// class SuggestionsErrorState extends DocumentSearchState1 {}

// class ResultsLoadingState extends DocumentSearchState1 {}

// class ResultsLoadedState extends DocumentSearchState1 {}

// class ResultsErrorState extends DocumentSearchState1 {}
