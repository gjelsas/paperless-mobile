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

  const BaseState.loaded(T data)
      : this(status: LoadingStatus.loaded, data: data);

  const BaseState.loading() : this(status: LoadingStatus.loading);

  BaseState<T> withError(Object error) => copyWith(
        error: error,
        status: LoadingStatus.error,
      );

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
