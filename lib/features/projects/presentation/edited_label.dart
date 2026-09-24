import 'package:intl/intl.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// "Edited 5 minutes ago", "Edited yesterday", "Edited Sep 3", relative to
/// [now].
String editedLabel(
  AppLocalizations l10n,
  DateTime edited,
  DateTime now, {
  String? locale,
}) {
  final local = edited.toLocal();
  final today = now.toLocal();
  final age = today.difference(local);
  if (age.inMinutes < 1) return l10n.editedJustNow;
  if (age.inHours < 1) return l10n.editedMinutesAgo(age.inMinutes);
  final startOfToday = DateTime(today.year, today.month, today.day);
  if (!local.isBefore(startOfToday)) return l10n.editedHoursAgo(age.inHours);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
  if (!local.isBefore(startOfYesterday)) return l10n.editedYesterday;
  final format = local.year == today.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return l10n.editedOn(format.format(local));
}
