import 'package:equatable/equatable.dart';

class PaperlessApiException with EquatableMixin implements Exception {
  final ErrorCode code;
  final String? details;
  final Object? error;
  final StackTrace? stackTrace;
  final int? httpStatusCode;

  const PaperlessApiException(
    this.code, {
    this.details,
    this.stackTrace,
    this.error,
    this.httpStatusCode,
  });

  const PaperlessApiException.unknown({
    String? details,
    StackTrace? stackTrace,
    int? httpStatusCode,
    Object? error,
  }) : this(
          ErrorCode.unknown,
          details: details,
          stackTrace: stackTrace,
          error: error,
          httpStatusCode: httpStatusCode,
        );

  @override
  List<Object?> get props => [code, details, error, stackTrace, httpStatusCode];

  @override
  String toString() {
    if (details?.isNotEmpty ?? false) {
      return details!;
    } else if (error != null) {
      return error!.toString();
    }
    return super.toString();
  }
}

enum ErrorCode {
  unknown,
  authenticationFailed,
  notAuthenticated,
  documentUploadFailed,
  documentUpdateFailed,
  documentLoadFailed,
  documentDeleteFailed,
  documentBulkActionFailed,
  documentPreviewFailed,
  documentAsnQueryFailed,
  tagCreateFailed,
  tagLoadFailed,
  documentTypeCreateFailed,
  documentTypeLoadFailed,
  correspondentCreateFailed,
  correspondentLoadFailed,
  scanRemoveFailed,
  invalidClientCertificateConfiguration,
  biometricsNotSupported,
  biometricAuthenticationFailed,
  deviceOffline,
  serverUnreachable,
  similarQueryError,
  suggestionsQueryError,
  autocompleteQueryError,
  storagePathLoadFailed,
  storagePathCreateFailed,
  loadSavedViewsError,
  createSavedViewError,
  deleteSavedViewError,
  requestTimedOut,
  unsupportedFileFormat,
  missingClientCertificate,
  acknowledgeTasksError,
  correspondentDeleteFailed,
  documentTypeDeleteFailed,
  tagDeleteFailed,
  correspondentUpdateFailed,
  documentTypeUpdateFailed,
  tagUpdateFailed,
  storagePathDeleteFailed,
  storagePathUpdateFailed,
  serverInformationLoadFailed,
  serverStatisticsLoadFailed,
  uiSettingsLoadFailed,
  loadTasksError,
  userNotFound,
  userAlreadyExists,
  updateSavedViewError,
  customFieldCreateFailed,
  customFieldLoadFailed,
  customFieldDeleteFailed,
  deleteNoteFailed,
  addNoteFailed,
  downloadFailed,
  documnetMetaDataLoadFailed;
}
