package deckers.thibault.aves.channel.calls

import android.app.ActivityManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import androidx.core.content.edit
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import deckers.thibault.aves.channel.calls.Coresult.Companion.safe
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class SecurityHandler(private val context: Context) : MethodCallHandler {
    private var sharedPreferences: SharedPreferences? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "writeValue" -> safe(call, result, ::writeValue)
            "readValue" -> safe(call, result, ::readValue)
            "getClockInfo" -> safe(call, result, ::getClockInfo)
            "wipeAppData" -> safe(call, result, ::wipeAppData)
            else -> result.notImplemented()
        }
    }

    private fun getStore(): SharedPreferences {
        if (sharedPreferences == null) {
            val mainKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            sharedPreferences = EncryptedSharedPreferences.create(
                context,
                FILENAME,
                mainKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        }
        return sharedPreferences!!
    }

    private fun writeValue(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        val value = call.argument<Any?>("value")
        if (key == null) {
            result.error("writeValue-args", "missing arguments", null)
            return
        }

        val preferences = getStore()
        preferences.edit {
            when (value) {
                is Boolean -> putBoolean(key, value)
                is Float -> putFloat(key, value)
                is Int -> putInt(key, value)
                is Long -> putLong(key, value)
                is String -> putString(key, value)
                null -> remove(key)
                else -> {
                    result.error("writeValue-type", "unsupported type for value=$value", null)
                    return
                }
            }
        }
        result.success(true)
    }

    private fun readValue(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        if (key == null) {
            result.error("readValue-args", "missing arguments", null)
            return
        }

        result.success(getStore().all[key])
    }

    // monotonic clock (not affected by changes of the system date and time)
    // and boot count (`-1` when unavailable), to detect reboots
    private fun getClockInfo(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val bootCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, -1)
        } else {
            -1
        }
        result.success(
            hashMapOf(
                "elapsedRealtimeMillis" to SystemClock.elapsedRealtime(),
                "bootCount" to bootCount,
            )
        )
    }

    // same effect as clearing the data of the app from the system settings:
    // removes the app files (including vaults), databases, preferences and caches,
    // and stops the app process
    private fun wipeAppData(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val success = activityManager.clearApplicationUserData()
        result.success(success)
    }

    companion object {
        const val CHANNEL = "deckers.thibault/aves/security"
        const val FILENAME = "secret_shared_prefs"
    }
}