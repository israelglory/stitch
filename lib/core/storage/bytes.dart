import 'package:intl/intl.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// [bytes] for people: "0 KB", "820 KB", "45 MB", "1.2 GB". Decimal units,
/// as phones show storage.
String formatBytes(AppLocalizations l10n, int bytes) {
  const kb = 1000;
  const mb = kb * 1000;
  const gb = mb * 1000;
  final number = NumberFormat('0.#', l10n.localeName);
  if (bytes >= gb) {
    final value = bytes / gb;
    return l10n.sizeGigabytes(
      value >= 10 ? number.format(value.round()) : number.format(value),
    );
  }
  if (bytes >= mb) {
    return l10n.sizeMegabytes(number.format((bytes / mb).round()));
  }
  return l10n.sizeKilobytes(number.format((bytes / kb).ceil()));
}
