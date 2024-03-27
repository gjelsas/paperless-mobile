import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';
import 'package:paperless_api/src/models/models.dart';
import 'package:paperless_api/src/modules/labels_api/paperless_labels_api.dart';
import 'package:paperless_api/src/request_utils.dart';

class PaperlessLabelApiImpl implements PaperlessLabelsApi {
  final Dio _client;

  PaperlessLabelApiImpl(this._client);
  @override
  Future<T> create<T extends Label>(T label) async {
    assert(label.id == null);
    final errorCode = switch (label) {
      Correspondent() => ErrorCode.correspondentCreateFailed,
      DocumentType() => ErrorCode.documentTypeCreateFailed,
      StoragePath() => ErrorCode.storagePathCreateFailed,
      Tag() => ErrorCode.tagCreateFailed,
    };
    return performRequestGuarded(() async {
      final entity = await _client.post(
        '/api/${_endpoint<T>()}/',
        data: label.toJson(),
        options: Options(
          validateStatus: (status) => status == 201,
        ),
      );
      return _parse<T>(entity.data);
    }, errorCode);
  }

  @override
  Future<T> update<T extends Label>(T label) async {
    assert(label.id != null);
    final errorCode = switch (label) {
      Correspondent() => ErrorCode.correspondentUpdateFailed,
      DocumentType() => ErrorCode.documentTypeUpdateFailed,
      StoragePath() => ErrorCode.storagePathUpdateFailed,
      Tag() => ErrorCode.tagUpdateFailed,
    };
    return performRequestGuarded(() async {
      final entity = await _client.put(
        '/api/${_endpoint<T>()}/${label.id!}/',
        data: label.toJson(),
        options: Options(
          validateStatus: (status) => status == 200,
        ),
      );
      return _parse<T>(entity.data);
    }, errorCode);
  }

  @override
  Future<int> delete<T extends Label>(T label) {
    assert(label.id != null);
    final errorCode = switch (label) {
      Correspondent() => ErrorCode.correspondentDeleteFailed,
      DocumentType() => ErrorCode.documentTypeDeleteFailed,
      StoragePath() => ErrorCode.storagePathDeleteFailed,
      Tag() => ErrorCode.tagDeleteFailed,
    };
    return performRequestGuarded(() async {
      await _client.delete(
        '/api/${_endpoint<T>()}/${label.id}/',
        options: Options(validateStatus: (status) => status == 204),
      );
      return label.id!;
    }, errorCode);
  }

  String _endpoint<T extends Label>() {
    return switch (T) {
      Correspondent => "correspondents",
      DocumentType => "document_types",
      StoragePath => "storage_paths",
      Tag => "tags",
      _ => throw PaperlessApiException.unknown(details: "Unknown type: $T"),
    };
  }

  T _parse<T extends Label>(Map<String, dynamic> json) {
    return switch (T) {
      Correspondent => Correspondent.fromJson(json),
      DocumentType => DocumentType.fromJson(json),
      StoragePath => StoragePath.fromJson(json),
      Tag => Tag.fromJson(json),
      _ => throw PaperlessApiException.unknown(details: "Unknown type: $T"),
    } as T;
  }

  @override
  Future<T> find<T extends Label>(int id) {
    final errorCode = switch (T) {
      Correspondent => ErrorCode.correspondentLoadFailed,
      DocumentType => ErrorCode.documentTypeLoadFailed,
      StoragePath => ErrorCode.storagePathLoadFailed,
      Tag => ErrorCode.tagLoadFailed,
      _ => throw PaperlessApiException.unknown(details: "Unknown type: $T"),
    };
    return performRequestGuarded(() async {
      final response = await _client.get(
        '/api/${_endpoint<T>()}/$id/',
        options: Options(
          validateStatus: (status) => status == 200,
        ),
      );
      return _parse<T>(response.data);
    }, errorCode);
  }

  @override
  Future<Iterable<T>> findAll<T extends Label>([Iterable<int>? ids]) {
    final errorCode = switch (T) {
      Correspondent => ErrorCode.correspondentLoadFailed,
      DocumentType => ErrorCode.documentTypeLoadFailed,
      StoragePath => ErrorCode.storagePathLoadFailed,
      Tag => ErrorCode.tagLoadFailed,
      _ => throw PaperlessApiException.unknown(details: "Unknown type: $T"),
    };
    return performRequestGuarded(() async {
      final response = await _client.get(
        '/api/${_endpoint<T>()}/?page_size=100000',
        options: Options(
          validateStatus: (status) => status == 200,
        ),
      );
      return parseCollection<T>(response, _parse<T>, ids);
    }, errorCode);
  }
}
