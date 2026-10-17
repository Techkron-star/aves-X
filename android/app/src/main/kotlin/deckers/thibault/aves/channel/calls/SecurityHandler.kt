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
import deckers.thibault.aves.storage.StorageUtils
import deckers.thibault.aves.utils.VaultCrypto
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.File
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class SecurityHandler(private val context: Context) : MethodCallHandler {
    private var sharedPreferences: SharedPreferences? = null
    private val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val vaultCrypto by lazy { VaultCrypto(context) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "writeValue" -> safe(call, result, ::writeValue)
            "readValue" -> safe(call, result, ::readValue)
            "getClockInfo" -> safe(call, result, ::getClockInfo)
            "wipeAppData" -> safe(call, result, ::wipeAppData)
            "cryptVault" -> ioScope.launch { safe(call, result, ::cryptVault) }
            "cryptAllVaults" -> ioScope.launch { safe(call, result, ::cryptAllVaults) }
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

    // encrypts or decrypts the files of one vault (by name)
    private fun cryptVault(call: MethodCall, result: MethodChannel.Result) {
        val vault = call.argument<String>("vault")
        val encrypt = call.argument<Boolean>("encrypt")
        if (vault == null || encrypt == null || vault.contains('/') || vault.contains("..")) {
            result.error("cryptVault-args", "missing or invalid arguments", null)
            return
        }

        val dir = File(StorageUtils.getVaultRoot(context), vault)
        result.success(synchronizedCrypt(dir, encrypt))
    }

    // encrypts or decrypts the files of every vault
    private fun cryptAllVaults(call: MethodCall, result: MethodChannel.Result) {
        val encrypt = call.argument<Boolean>("encrypt")
        if (encrypt == null) {
            result.error("cryptAllVaults-args", "missing arguments", null)
            return
        }

        var done = 0
        var skipped = 0
        var failed = 0
        File(StorageUtils.getVaultRoot(context)).listFiles()?.filter { it.isDirectory }?.forEach { dir ->
            val report = synchronizedCrypt(dir, encrypt)
            done += report["done"] ?: 0
            skipped += report["skipped"] ?: 0
            failed += report["failed"] ?: 0
        }
        result.success(hashMapOf("done" to done, "skipped" to skipped, "failed" to failed))
    }

    // one operation at a time, as they replace files
    @Synchronized
    private fun synchronizedCrypt(dir: File, encrypt: Boolean): Map<String, Int> {
        val report = vaultCrypto.processDirectory(dir, encrypt)
        return hashMapOf("done" to report.done, "skipped" to report.skipped, "failed" to report.failed)
    }

    companion object {
        const val CHANNEL = "deckers.thibault/aves/security"
        const val FILENAME = "secret_shared_prefs"
    }
}