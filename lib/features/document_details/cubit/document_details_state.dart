part of 'document_details_cubit.dart';

@freezed
class DocumentDetailsData with _$DocumentDetailsData {
  const factory DocumentDetailsData({
    required DocumentModel document,
    required DocumentMetaData metaData,
    required FieldSuggestions fieldSuggestions,
    required int nextAsn,
  }) = _DocumentDetailsData;
}

typedef DocumentDetailsState = BaseState<DocumentDetailsData>;
