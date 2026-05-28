# Keep generic type signatures used by Gson in flutter_local_notifications.
-keepattributes Signature

# Keep Gson and type tokens from being stripped or having signatures removed.
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }

# Keep flutter_local_notifications classes used via reflection.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
