import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_loading_status.dart';

///
/// Base state for all blocs/cubits using a paged view of documents.
/// [T] is the return type of the API call.
///
abstract class DocumentPagingState extends Equatable {
  final PagedLoadingStatus status;
  final List<PagedSearchResult<DocumentModel>> value;
  final DocumentFilter filter;
  final List<int>? all;
  const DocumentPagingState({
    this.value = const [],
    this.status = PagedLoadingStatus.initial,
    this.filter = const DocumentFilter(),
    this.all,
  });

  List<DocumentModel> get documents =>
      value.expand((element) => element.results).toList();

  int get currentPageNumber {
    assert(value.isNotEmpty);
    return value.last.pageKey;
  }

  int? get nextPageNumber {
    return isLastPageLoaded ? null : currentPageNumber + 1;
  }

  int get count {
    if (value.isEmpty) {
      return 0;
    }
    return value.first.count;
  }

  bool get isLastPageLoaded {
    if (status != PagedLoadingStatus.loaded ||
        status != PagedLoadingStatus.loadingMore) {
      return false;
    }
    if (value.isNotEmpty) {
      return value.last.next == null;
    }
    return true;
  }

  int inferPageCount({required int pageSize}) {
    if (status != PagedLoadingStatus.loaded ||
        status != PagedLoadingStatus.loadingMore) {
      return 100000;
    }
    if (value.isEmpty) {
      return 0;
    }
    return value.first.inferPageCount(pageSize: pageSize);
  }

  // Return type has to be dynamic
  dynamic copyWithPaged({
    PagedLoadingStatus status,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<int>? all,
  });

  @override
  List<Object?> get props => [
        filter,
        value,
        status,
        all,
      ];
}
