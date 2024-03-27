import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';
import 'package:paperless_api/src/models/paperless_api_exception.dart';

Future<T?> getSingleResult<T>(
  String url,
  T Function(Map<String, dynamic>) fromJson,
  ErrorCode errorCode, {
  required Dio client,
  int minRequiredApiVersion = 1,
}) async {
  return performRequestGuarded(() async {
    final response = await client.get(
      url,
      options: Options(
        headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
        validateStatus: (status) => status == 200,
      ),
    );
    return compute(
      fromJson,
      response.data as Map<String, dynamic>,
    );
  }, errorCode);
}

Future<Iterable<T>> parseCollection<T extends Label>(
  Response<dynamic> response,
  T Function(Map<String, dynamic>) fromJson,
  Iterable<int>? ids,
) async {
  final Map<String, dynamic> body = response.data;
  if (body['count'] == 0) {
    return <T>[];
  } else {
    var results = (body['results'] as List).cast<Map<String, dynamic>>();
    if (ids != null) {
      results =
          results.where((element) => ids.contains(element['id'])).toList();
    }
    return results.map((e) => fromJson(e));
    // return compute(
    //   _collectionFromJson,
    //   _CollectionFromJsonSerializationParams(
    //     fromJson,
    //     results,
    //   ),
    // );
  }
}

Future<List<T>> getCollection<T>(
  String url,
  T Function(Map<String, dynamic>) fromJson,
  ErrorCode errorCode, {
  required Dio client,
  int minRequiredApiVersion = 1,
}) async {
  return performRequestGuarded(() async {
    final response = await client.get(
      url,
      options: Options(
        headers: {'accept': 'application/json; version=$minRequiredApiVersion'},
        validateStatus: (status) => status == 200,
      ),
    );
    final Map<String, dynamic> body = response.data;
    if (body['count'] == 0) {
      return <T>[];
    } else {
      return compute(
        _collectionFromJson,
        _CollectionFromJsonSerializationParams(
          fromJson,
          (body['results'] as List).cast<Map<String, dynamic>>(),
        ),
      );
    }
  }, errorCode);
}

List<T> _collectionFromJson<T>(
  _CollectionFromJsonSerializationParams<T> params,
) {
  return params.list.map<T>((result) => params.fromJson(result)).toList();
}

class _CollectionFromJsonSerializationParams<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final List<Map<String, dynamic>> list;

  _CollectionFromJsonSerializationParams(this.fromJson, this.list);
}

int getExtendedVersionNumber(String version) {
  List versionCells = version.split('.');
  versionCells = versionCells.map((i) => int.parse(i)).toList();
  return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
}

int? tryParseNullable(String? source, {int? radix}) {
  if (source == null) return null;
  return int.tryParse(source, radix: radix);
}

/// Ensures only [PaperlessApiException]s are thrown from all requests.
Future<T> performRequestGuarded<T>(
  Future<T> Function() callback,
  ErrorCode errorCode,
) {
  try {
    return callback();
  } on DioException catch (exception, stackTrace) {
    throw exception.unravel(
      orElse: PaperlessApiException(
        errorCode,
        error: exception,
        details: exception.message,
        stackTrace: stackTrace,
      ),
    );
  } catch (error, stackTrace) {
    throw PaperlessApiException.unknown(
      error: error,
      stackTrace: stackTrace,
    );
  }
}
