# Keep rules for release (R8) builds.

# flutter_gemma / MediaPipe LLM (on-device inference).
# MediaPipe references compile-time-only classes (auto-value, protobuf,
# generated protos) that aren't on the runtime classpath, so R8 must be told
# not to fail on them.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

-keep class com.google.auto.value.** { *; }
-dontwarn com.google.auto.value.**

-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# LiteRT / TensorFlow Lite runtime used by flutter_gemma.
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# javax annotations referenced by the above libraries.
-dontwarn javax.annotation.**
-dontwarn javax.lang.model.**
