# Media3 stores types that only exist on newer Android versions in fields
# (android.media.metrics.LogSessionId, API 31) and only touches them behind
# version checks. R8's class merging turned such fields into Object and
# added a check-cast back to the real type on an unguarded path, which
# loads the class and crashed caption generation on Android 11
# ("NoClassDefFoundError: android/media/metrics/LogSessionId"). Keeping the
# fields' declared types stops that rewrite; the classes are still shrunk
# and renamed.
-keepclassmembers,allowobfuscation class androidx.media3.** {
    <fields>;
}
