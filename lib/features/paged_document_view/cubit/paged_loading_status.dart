enum PagedLoadingStatus {
  initial,

  /// Data is loaded for the first time
  loading,

  /// Data has been loaded
  loaded,

  /// New data is currently being loaded, but some data already exists.
  loadingMore,
  error;
}
