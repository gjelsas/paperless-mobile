import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/base_state.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/bloc/transient_error.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

part 'document_details_cubit.freezed.dart';
part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final int id;
  final PaperlessDocumentsApi _api;
  final LabelRepository _labelRepository;
  final LocalNotificationService _notificationService;

  DocumentDetailsCubit(
    this._api,
    this._notificationService,
    this._labelRepository, {
    required this.id,
  }) : super(const DocumentDetailsState());

  Future<void> initialize() async {
    logger.fd(
      "Loading data for document $id...",
      className: runtimeType.toString(),
      methodName: "initialize",
    );
    emit(const DocumentDetailsState(status: LoadingStatus.loading));
    try {
      final (document, metaData, nextAsn, fieldSuggestions) =
          await Future.wait([
        _api.find(id),
        _api.getMetaData(id),
        _api.findNextAsn(),
        _api.findSuggestions(id),
      ]).then(
        (value) => (
          value[0] as DocumentModel,
          value[1] as DocumentMetaData,
          value[2] as int,
          value[3] as FieldSuggestions,
        ),
      );
      logger.fd(
        "Data successfully loaded for document $id.",
        className: runtimeType.toString(),
        methodName: "initialize",
      );
      emit(DocumentDetailsState.loaded(
        DocumentDetailsData(
          document: document,
          metaData: metaData,
          nextAsn: nextAsn,
          fieldSuggestions: fieldSuggestions,
        ),
      ));
    } on PaperlessApiException catch (error, stackTrace) {
      logger.fe(
        "Could not load data for document $id.",
        className: runtimeType.toString(),
        methodName: 'initialize',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.withError(error));
    }
  }

  Future<void> delete(DocumentModel document) async {
    logger.fd(
      "Deleting document ${document.id}...",
      className: runtimeType.toString(),
      methodName: "delete",
    );
    try {
      await _api.delete(document);
      logger.fd(
        "Document ${document.id} successfully deleted.",
        className: runtimeType.toString(),
        methodName: "delete",
      );
    } on PaperlessApiException catch (error, stackTrace) {
      logger.fe(
        "Could not delete document ${document.id}.",
        className: runtimeType.toString(),
        methodName: "delete",
        error: error,
        stackTrace: stackTrace,
      );
      addError(
        TransientPaperlessApiError(
          code: error.code,
          details: error.details,
        ),
      );
    }
  }

  Future<void> deleteNote(NoteModel note) async {
    assert(state.status == LoadingStatus.loaded,
        "Document data has to be loaded before calling this method.");
    assert(note.id != null, "Note id cannot be null.");
    try {
      logger.fd(
        "Deleting note ${note.id}...",
        className: runtimeType.toString(),
        methodName: "deleteNote",
      );
      final updatedDocument = await _api.deleteNote(
        state.data!.document,
        note.id!,
      );
      logger.fd(
        "Note ${note.id} successfully deleted.",
        className: runtimeType.toString(),
        methodName: "deleteNote",
      );
      emit(state.copyWith(
          data: state.data!.copyWith(
        document: updatedDocument,
      )));
    } on PaperlessApiException catch (error, stackTrace) {
      logger.fe(
        "An error occurred while deleting note ${note.id}.",
        className: runtimeType.toString(),
        methodName: "deleteNote",
        error: error,
        stackTrace: stackTrace,
      );
      addError(
        TransientPaperlessApiError(
          code: error.code,
          details: error.details,
        ),
      );
    }
  }

  Future<ResultType> openDocumentInSystemViewer() async {
    if (state.status != LoadingStatus.loaded) {
      throw Exception(
        "Document cannot be opened in system viewer "
        "if document information has not yet been loaded.",
      );
    }
    final cacheDir = FileService.instance.temporaryDirectory;
    final filePath = state.data!.metaData.mediaFilename.replaceAll("/", " ");

    final fileName = "${p.basenameWithoutExtension(filePath)}.pdf";
    final file = File("${cacheDir.path}/$fileName");

    if (!file.existsSync()) {
      file.createSync();
      logger.ft(
        "No local copy found, downloading document pdf for ${state.data!.document.id}...",
        className: runtimeType.toString(),
        methodName: "openDocumentInSystemViewer",
      );
      await _api.downloadToFile(
        state.data!.document.id,
        file.path,
      );
      logger.ft(
        "Pdf successfully downloaded for document ${state.data!.document.id}...",
        className: runtimeType.toString(),
        methodName: "openDocumentInSystemViewer",
      );
    }
    return OpenFilex.open(
      file.path,
      type: "application/pdf",
    ).then((value) => value.type);
  }

  Future<void> downloadDocument({
    bool downloadOriginal = false,
    required String locale,
    required String userId,
  }) async {
    if (state.status != LoadingStatus.loaded) {
      return;
    }
    String targetPath = _buildDownloadFilePath(
      state.data!.metaData,
      downloadOriginal,
      FileService.instance.downloadsDirectory,
    );

    if (!await File(targetPath).exists()) {
      await File(targetPath).create();
    } else {
      await _notificationService.notifyDocumentDownload(
        document: state.data!.document,
        filename: p.basename(targetPath),
        filePath: targetPath,
        finished: true,
        locale: locale,
        userId: userId,
      );
    }

    // await _notificationService.notifyFileDownload(
    //   document: state.document,
    //   filename: p.basename(targetPath),
    //   filePath: targetPath,
    //   finished: false,
    //   locale: locale,
    //   userId: userId,
    // );
    logger.fd(
      "Downloading file of document ${state.data!.document.id}...",
      className: runtimeType.toString(),
      methodName: "downloadDocument",
    );
    await _api.downloadToFile(
      state.data!.document.id,
      targetPath,
      original: downloadOriginal,
      onProgressChanged: (progress) {
        _notificationService.notifyDocumentDownload(
          document: state.data!.document,
          filename: p.basename(targetPath),
          filePath: targetPath,
          finished: true,
          locale: locale,
          userId: userId,
          progress: progress,
        );
      },
    );
    logger.fi(
      "Document successfully downloaded to $targetPath.",
      className: runtimeType.toString(),
      methodName: "downloadDocument",
    );
    await _notificationService.notifyDocumentDownload(
      document: state.data!.document,
      filename: p.basename(targetPath),
      filePath: targetPath,
      finished: true,
      locale: locale,
      userId: userId,
    );
  }

  Future<void> shareDocument({bool shareOriginal = false}) async {
    if (state.status != LoadingStatus.loaded) {
      return;
    }
    String filePath = _buildDownloadFilePath(
      state.data!.metaData,
      shareOriginal,
      FileService.instance.temporaryDirectory,
    );
    await _api.downloadToFile(
      state.data!.document.id,
      filePath,
      original: shareOriginal,
    );
    Share.shareXFiles(
      [
        XFile(
          filePath,
          name: state.data!.document.originalFileName,
          mimeType: "application/pdf",
          lastModified: state.data!.document.modified,
        ),
      ],
      subject: state.data!.document.title,
    );
  }

  Future<void> printDocument() async {
    if (state.status != LoadingStatus.loaded) {
      return;
    }
    final filePath = _buildDownloadFilePath(
      state.data!.metaData,
      false,
      FileService.instance.temporaryDirectory,
    );
    await _api.downloadToFile(
      state.data!.document.id,
      filePath,
      original: false,
    );
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception("An error occurred while downloading the document.");
    }
    Printing.layoutPdf(
      name: state.data!.document.title,
      onLayout: (format) => file.readAsBytesSync(),
    );
  }

  String _buildDownloadFilePath(
    DocumentMetaData meta,
    bool original,
    Directory dir,
  ) {
    final normalizedPath = meta.mediaFilename.replaceAll("/", " ");
    final extension = original ? p.extension(normalizedPath) : '.pdf';
    return "${dir.path}/${p.basenameWithoutExtension(normalizedPath)}$extension";
  }

  Future<void> addNote(String text) async {
    assert(state.status == LoadingStatus.loaded);
    try {
      final updatedDocument = await _api.addNote(
        document: state.data!.document,
        text: text,
      );
      emit(state.copyWith(
          data: state.data!.copyWith(
        document: updatedDocument,
      )));
    } on PaperlessApiException catch (err) {
      addError(TransientPaperlessApiError(code: err.code));
    }
  }

  Future<int> nextAsn() {
    return _api.findNextAsn();
  }

  Future<void> updateDocument(DocumentModel document) async {
    logger.fd(
      "Updating document ${document.id}...",
      className: runtimeType.toString(),
      methodName: "updateDocument",
    );
    try {
      final updatedDocument = await _api.update(document);
      final (metadata, nextAsn, suggestions) = await Future.wait([
        _api.getMetaData(id),
        _api.findNextAsn(),
        _api.findSuggestions(id),
        _labelRepository.reload(),
      ]).then((value) => (
            value[0] as DocumentMetaData,
            value[1] as int,
            value[2] as FieldSuggestions,
          ));
      emit(state.copyWith(
        data: DocumentDetailsData(
          document: updatedDocument,
          metaData: metadata,
          nextAsn: nextAsn,
          fieldSuggestions: suggestions,
        ),
      ));
    } on PaperlessApiException catch (error, stackTrace) {
      addError(
          TransientPaperlessApiError(code: error.code, details: error.details));
      logger.fe(
        "An error occurred while updating document ${document.id}.",
        className: runtimeType.toString(),
        methodName: "updateDocument",
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      addError(error);
      logger.fe(
        "An unexpected error occurred while updating document ${document.id}.",
        className: runtimeType.toString(),
        methodName: "updateDocument",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
