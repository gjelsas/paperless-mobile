import 'package:paperless_mobile/core/bloc/loading_status.dart';

class BaseState<T> {
  final Object? error;
  final T? data;
  final LoadingStatus status;

  const BaseState({
    this.error,
    this.data,
    this.status = LoadingStatus.initial,
  });

  BaseState<T> copyWith({
    Object? error,
    T? data,
    LoadingStatus? status,
  }) {
    return BaseState(
      error: error ?? this.error,
      data: data ?? this.data,
      status: status ?? this.status,
    );
  }
}
