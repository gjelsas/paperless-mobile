import 'dart:math';

String formatMaxCount(int? count, [int maxCount = 99]) {
  if ((count ?? 0) > maxCount) {
    return "$maxCount+";
  }
  return (count ?? 0).toString();
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
}
