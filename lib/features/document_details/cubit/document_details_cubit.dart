import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/base_state.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/bloc/transient_error.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final int id;
  final PaperlessDocumentsApi _api;
  final LocalNotificationService _notificationService;

  DocumentDetailsCubit(
    this._api,
    this._notificationService, {
    required this.id,
  }) : super(const DocumentDetailsState());

  Future<void> initialize() async {
    debugPrint("Initialize called");
    emit(const DocumentDetailsState(status: LoadingStatus.loading));
    try {
      final (document, metaData) = await Future.wait([
        _api.find(id),
        _api.getMetaData(id),
      ]).then((value) => (
            value[0] as DocumentModel,
            value[1] as DocumentMetaData,
          ));
      // final document = await _api.find(id);
      // final metaData = await _api.getMetaData(id);
      debugPrint("Document data loaded for $id");
      emit(DocumentDetailsState(
        status: LoadingStatus.loaded,
        data: DocumentDetailsData(
          document: document,
          metaData: metaData,
        ),
      ));
    } on PaperlessApiException catch (error, stackTrace) {
      logger.fe(
        "An error occurred while loading data for document $id.",
        className: runtimeType.toString(),
        methodName: 'initialize',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const DocumentDetailsState(status: LoadingStatus.error));
      addError(
        TransientPaperlessApiError(code: error.code, details: error.details),
      );
    }
  }

  Future<void> delete(DocumentModel document) async {
    try {
      await _api.delete(document);
    } on PaperlessApiException catch (e) {
      addError(
        TransientPaperlessApiError(code: e.code, details: e.details),
      );
    }
  }

  Future<void> updateNote(NoteModel note) async {
    assert(state.status == LoadingStatus.loaded);
    final document = state.data!.document;
    final updatedNotes = document.notes.map((e) => e.id == note.id ? note : e);
    try {
      final updatedDocument = await _api.update(
        state.data!.document.copyWith(
          notes: updatedNotes,
        ),
      );
      emit(state.copyWith(
          data: state.data!.copyWith(
        document: updatedDocument,
      )));
    } on PaperlessApiException catch (e) {
      addError(
        TransientPaperlessApiError(
          code: e.code,
          details: e.details,
        ),
      );
    }
  }

  Future<void> deleteNote(NoteModel note) async {
    assert(state.status == LoadingStatus.loaded,
        "Document data has to be loaded before calling this method.");
    assert(note.id != null, "Note id cannot be null.");
    try {
      final updatedDocument = await _api.deleteNote(
        state.data!.document,
        note.id!,
      );
      emit(state.copyWith(
          data: state.data!.copyWith(
        document: updatedDocument,
      )));
    } on PaperlessApiException catch (e) {
      addError(
        TransientPaperlessApiError(
          code: e.code,
          details: e.details,
        ),
      );
    }
  }

  Future<void> assignAsn(
    DocumentModel document, {
    int? asn,
    bool autoAssign = false,
  }) async {
    try {
      DocumentModel updatedDocument;
      if (!autoAssign) {
        updatedDocument = await _api.update(
          document.copyWith(archiveSerialNumber: () => asn),
        );
      } else {
        final int autoAsn = await _api.findNextAsn();
        updatedDocument = await _api
            .update(document.copyWith(archiveSerialNumber: () => autoAsn));
      }
      emit(
        state.copyWith(
          data: state.data!.copyWith(document: document),
        ),
      );
    } on PaperlessApiException catch (e) {
      addError(
        TransientPaperlessApiError(code: e.code, details: e.details),
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
      await _api.downloadToFile(
        state.data!.document.id,
        file.path,
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
    await _notificationService.notifyDocumentDownload(
      document: state.data!.document,
      filename: p.basename(targetPath),
      filePath: targetPath,
      finished: true,
      locale: locale,
      userId: userId,
    );
    logger.fi("Document '${state.data!.document.title}' saved to $targetPath.");
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
}
