import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/constants.dart';
import 'package:paperless_api/src/request_utils.dart';

class PaperlessDocumentsApiImpl implements PaperlessDocumentsApi {
  final Dio client;

  PaperlessDocumentsApiImpl(this.client);

  @override
  Future<String?> create(
    Uint8List documentBytes, {
    required String filename,
    required String title,
    String contentType = 'application/octet-stream',
    DateTime? createdAt,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    int? asn,
    void Function(double progress)? onProgressChanged,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'document',
        MultipartFile.fromBytes(documentBytes, filename: filename),
      ),
    );
    formData.fields.add(MapEntry('title', title));

    if (createdAt != null) {
      formData.fields.add(
        MapEntry('created', apiDateFormat.format(createdAt)),
      );
    }
    if (correspondent != null) {
      formData.fields.add(MapEntry('correspondent', jsonEncode(correspondent)));
    }
    if (documentType != null) {
      formData.fields.add(MapEntry('document_type', jsonEncode(documentType)));
    }
    if (asn != null) {
      formData.fields.add(MapEntry('archive_serial_number', jsonEncode(asn)));
    }
    for (final tag in tags) {
      formData.fields.add(MapEntry('tags', tag.toString()));
    }
    return performRequestGuarded(() async {
      final response = await client.post(
        '/api/documents/post_document/',
        data: formData,
        onSendProgress: (count, total) {
          onProgressChanged?.call(count.toDouble() / total.toDouble());
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      if (response.data != "OK") {
        return response.data as String;
      } else {
        return null;
      }
    }, ErrorCode.documentUploadFailed);
  }

  @override
  Future<DocumentModel> update(DocumentModel doc) async {
    return performRequestGuarded(() async {
      final response = await client.put(
        "/api/documents/${doc.id}/",
        data: doc.toJson(),
        options: Options(validateStatus: (status) => status == 200),
      );
      return DocumentModel.fromJson(response.data);
    }, ErrorCode.documentUpdateFailed);
  }

  @override
  Future<PagedSearchResult<DocumentModel>> findAll(
    DocumentFilter filter,
  ) async {
    final filterParams = filter.toQueryParameters()
      ..addAll({'truncate_content': "true"});
    return performRequestGuarded(
      () async {
        final response = await client.get(
          "/api/documents/",
          queryParameters: filterParams,
          options: Options(validateStatus: (status) => status == 200),
        );
        return compute(
          PagedSearchResult.fromJsonSingleParam,
          PagedSearchResultJsonSerializer<DocumentModel>(
            response.data,
            DocumentModelJsonConverter(),
          ),
        );
      },
      ErrorCode.documentLoadFailed,
    );
  }

  @override
  Future<int> delete(DocumentModel doc) async {
    return performRequestGuarded(() async {
      await client.delete(
        "/api/documents/${doc.id}/",
        options: Options(validateStatus: (status) => status == 204),
      );
      return Future.value(doc.id);
    }, ErrorCode.documentDeleteFailed);
  }

  @override
  String getThumbnailUrl(int documentId) {
    return "/api/documents/$documentId/thumb/";
  }

  String getPreviewUrl(int documentId) {
    return "/api/documents/$documentId/preview/";
  }

  @override
  Future<Uint8List> getPreview(int documentId) async {
    return performRequestGuarded(() async {
      final response = await client.get(
        getPreviewUrl(documentId),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status == 200,
        ),
      );
      return response.data;
    }, ErrorCode.documentPreviewFailed);
  }

  @override
  Future<int> findNextAsn() async {
    return performRequestGuarded(() async {
      final result = await client.get(
        "/api/documents/next_asn/",
        options: Options(headers: {
          HttpHeaders.acceptHeader: "application/json",
        }),
      );
      return result.data as int;
    }, ErrorCode.documentAsnQueryFailed);
  }

  @override
  Future<Iterable<int>> bulkAction(BulkAction action) async {
    return performRequestGuarded(() async {
      await client.post(
        "/api/documents/bulk_edit/",
        data: action.toJson(),
        options: Options(validateStatus: (status) => status == 200),
      );
      return action.documentIds;
    }, ErrorCode.documentBulkActionFailed);
  }

  @override
  Future<Uint8List> downloadDocument(
    int id, {
    bool original = false,
  }) async {
    return performRequestGuarded(() async {
      final response = await client.get(
        "/api/documents/$id/download/",
        queryParameters: {'original': original},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    }, ErrorCode.downloadFailed);
  }

  @override
  Future<void> downloadToFile(
    int id,
    String localFilePath, {
    bool original = false,
    void Function(double)? onProgressChanged,
  }) async {
    return performRequestGuarded(() async {
      final response = await client.download(
        "/api/documents/$id/download/",
        localFilePath,
        onReceiveProgress: (count, total) =>
            onProgressChanged?.call(count / total),
        queryParameters: {'original': original},
      );
      return response.data;
    }, ErrorCode.downloadFailed);
  }

  @override
  Future<DocumentMetaData> getMetaData(int id) async {
    debugPrint("Fetching data for /api/documents/$id/metadata/...");

    return performRequestGuarded(
      () async {
        final response = await client.get("/api/documents/$id/metadata/");
        return DocumentMetaData.fromJson(response.data);
      },
      ErrorCode.documnetMetaDataLoadFailed,
    );
  }

  @override
  Future<List<String>> autocomplete(String query, [int limit = 10]) async {
    return performRequestGuarded(() async {
      final response = await client.get(
        '/api/search/autocomplete/',
        queryParameters: {
          'term': query,
          'limit': limit,
        },
        options: Options(validateStatus: (status) => status == 200),
      );
      return (response.data as List).cast<String>();
    }, ErrorCode.autocompleteQueryError);
  }

  @override
  Future<FieldSuggestions> findSuggestions(int documentId) async {
    return performRequestGuarded(() async {
      final response = await client.get(
        "/api/documents/$documentId/suggestions/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return FieldSuggestions.fromJson(response.data).forDocumentId(documentId);
    }, ErrorCode.suggestionsQueryError);
  }

  @override
  Future<DocumentModel> find(int id) async {
    return performRequestGuarded(() async {
      final response = await client.get("/api/documents/$id/");
      debugPrint("Fetched data for /api/documents/$id/.");
      return DocumentModel.fromJson(response.data);
    }, ErrorCode.documentLoadFailed);
  }

  @override
  Future<DocumentModel> deleteNote(DocumentModel document, int noteId) async {
    return performRequestGuarded(() async {
      final response = await client
          .delete("/api/documents/${document.id}/notes/?id=$noteId");
      final notes =
          (response.data as List).map((e) => NoteModel.fromJson(e)).toList();

      return document.copyWith(notes: notes);
    }, ErrorCode.deleteNoteFailed);
  }

  @override
  Future<DocumentModel> addNote({
    required DocumentModel document,
    required String text,
  }) async {
    return performRequestGuarded(() async {
      final response = await client.post(
        "/api/documents/${document.id}/notes/",
        options: Options(validateStatus: (status) => status == 200),
        data: {'note': text},
      );

      final notes =
          (response.data as List).map((e) => NoteModel.fromJson(e)).toList();

      return document.copyWith(notes: notes);
    }, ErrorCode.addNoteFailed);
  }
}
