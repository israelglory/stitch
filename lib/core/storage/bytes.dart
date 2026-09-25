/// [bytes] for people: "0 KB", "820 KB", "45 MB", "1.2 GB". Decimal units,
/// as phones show storage.
String formatBytes(int bytes) {
  const kb = 1000;
  const mb = kb * 1000;
  const gb = mb * 1000;
  if (bytes >= gb) {
    final value = bytes / gb;
    return '${value >= 10 ? value.round() : value.toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) return '${(bytes / mb).round()} MB';
  return '${(bytes / kb).ceil()} KB';
}
