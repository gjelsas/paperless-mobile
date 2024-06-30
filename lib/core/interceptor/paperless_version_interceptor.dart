import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';

class PaperlessVersionHeaderInterceptor extends Interceptor {
  final Box<LocalUserAccount> _userAccountBox;
  final Box<GlobalSettings> _globalSettingsBox;
  const PaperlessVersionHeaderInterceptor(
      this._userAccountBox, this._globalSettingsBox);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;
    final version = _userAccountBox
        .get(_globalSettingsBox.getValue()?.loggedInUserId)
        ?.apiVersion;
    if (version == null) {
      return handler.next(options);
    }

    if (headers.containsKey(HttpHeaders.acceptHeader)) {
      headers[HttpHeaders.acceptHeader] += ';application/json;version=$version';
    } else {
      headers[HttpHeaders.acceptHeader] = 'application/json;version=$version';
    }
    return handler.next(options);
  }
}
