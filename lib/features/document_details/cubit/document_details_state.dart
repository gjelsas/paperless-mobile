part of 'document_details_cubit.dart';

class DocumentDetailsData {
  final DocumentModel document;
  final DocumentMetaData metaData;

  const DocumentDetailsData({
    required this.document,
    required this.metaData,
  });

  DocumentDetailsData copyWith({
    DocumentModel? document,
    DocumentMetaData? metaData,
  }) {
    return DocumentDetailsData(
      document: document ?? this.document,
      metaData: metaData ?? this.metaData,
    );
  }
}

typedef DocumentDetailsState = BaseState<DocumentDetailsData>;
