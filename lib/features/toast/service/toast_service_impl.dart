import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/toast/service/toast_service.dart';

class ToastServiceImpl implements ToastService {
  final ScaffoldMessengerState _messenger;

  ToastServiceImpl(this._messenger);

  @override
  void error(String message) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void info(String message) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void success(String message) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void warn(String message) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
