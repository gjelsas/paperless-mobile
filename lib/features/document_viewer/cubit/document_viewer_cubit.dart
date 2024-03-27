import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/base_state.dart';

part 'document_viewer_state.dart';

class DocumentViewerCubit extends Cubit<DocumentViewerState> {
  final PaperlessDocumentsApi _api;
  DocumentViewerCubit(this._api) : super(const DocumentViewerState());

  Future<void> initialize(final int documentId) async {
    try {
      emit(const DocumentViewerState.loading());
      final data = await _api.downloadDocument(documentId, original: true);
      emit(DocumentViewerState.loaded(data));
    } on PaperlessApiException catch (e) {
      emit(state.withError(e));
    }
  }
}
