package deckers.thibault.aves.channel.calls

import android.app.ActivityManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import androidx.core.content.edit
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import deckers.thibault.aves.channel.calls.Coresult.Companion.safe
import deckers.thibault.aves.storage.StorageUtils
import deckers.thibault.aves.utils.LogUtils
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
            "cryptSelfTest" -> ioScope.launch { safe(call, result, ::cryptSelfTest) }
            "destroyCryptoKeys" -> ioScope.launch { safe(call, result, ::destroyCryptoKeys) }
            "isRootAvailable" -> ioScope.launch { safe(call, result, ::isRootAvailable) }
            "playPcm" -> safe(call, result, ::playPcm)
            "stopPcm" -> safe(call, result, ::stopPcm)
            "rootTrim" -> ioScope.launch { safe(call, result, ::rootTrim) }
            "rootSeal" -> ioScope.launch { safe(call, result, ::rootSeal) }
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
    @Suppress("UNCHECKED_CAST")
    private fun cryptAllVaults(call: MethodCall, result: MethodChannel.Result) {
        val encrypt = call.argument<Boolean>("encrypt")
        if (encrypt == null) {
            result.error("cryptAllVaults-args", "missing arguments", null)
            return
        }

        var done = 0
        var skipped = 0
        var failed = 0
        val errors = mutableListOf<String>()
        File(StorageUtils.getVaultRoot(context)).listFiles()?.filter { it.isDirectory }?.forEach { dir ->
            val report = synchronizedCrypt(dir, encrypt)
            done += report["done"] as Int
            skipped += report["skipped"] as Int
            failed += report["failed"] as Int
            errors.addAll(report["errors"] as List<String>)
        }
        result.success(hashMapOf("done" to done, "skipped" to skipped, "failed" to failed, "errors" to errors))
    }

    // one operation at a time, as they replace files
    @Synchronized
    private fun synchronizedCrypt(dir: File, encrypt: Boolean): Map<String, Any> {
        return try {
            val report = vaultCrypto.processDirectory(dir, encrypt)
            hashMapOf("done" to report.done, "skipped" to report.skipped, "failed" to report.failed, "errors" to report.errors)
        } catch (e: Throwable) {
            // e.g. the key cannot be used: the details are reported instead of failing silently
            hashMapOf("done" to 0, "skipped" to 0, "failed" to 1, "errors" to listOf("${e.javaClass.simpleName}: ${e.message}"))
        }
    }

    // `null` when the encryption key works, the error otherwise
    private fun cryptSelfTest(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        result.success(vaultCrypto.selfTest())
    }

    private fun destroyCryptoKeys(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        result.success(vaultCrypto.destroyKeys())
    }

    // plays a short mono 16 bit PCM clip (the Fail-Safe voice), without any audio file or library.
    // A streaming track is used instead of a static one: static tracks failed to initialize on some devices,
    // and the clip can be larger than their buffer. Returns "ok" when playback started, otherwise the reason:
    // "empty", "muted" (media volume at zero: nothing would be heard), "init", "write" or "error:<details>".
    // static reference to the currently playing track, so we can stop it
    private var _currentTrack: android.media.AudioTrack? = null

    private fun playPcm(call: MethodCall, result: MethodChannel.Result) {
        val pcm = call.argument<ByteArray>("pcm")
        val rate = call.argument<Int>("rate") ?: 44100
        if (pcm == null || pcm.isEmpty()) {
            result.success("empty")
            return
        }

        val audioManager = context.getSystemService(android.content.Context.AUDIO_SERVICE) as? android.media.AudioManager
        if (audioManager != null && audioManager.getStreamVolume(android.media.AudioManager.STREAM_MUSIC) == 0) {
            result.success("muted")
            return
        }

        var track: android.media.AudioTrack? = null
        try {
            val minBuffer = android.media.AudioTrack.getMinBufferSize(
                rate,
                android.media.AudioFormat.CHANNEL_OUT_MONO,
                android.media.AudioFormat.ENCODING_PCM_16BIT
            )
            if (minBuffer <= 0) {
                Log.w(LOG_TAG, "unsupported audio format: rate=$rate minBuffer=$minBuffer")
                result.success("init")
                return
            }
            val built = android.media.AudioTrack.Builder()
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    android.media.AudioFormat.Builder()
                        .setEncoding(android.media.AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(android.media.AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(maxOf(minBuffer * 2, 16384))
                .setTransferMode(android.media.AudioTrack.MODE_STREAM)
                .build()
            track = built
            if (built.state != android.media.AudioTrack.STATE_INITIALIZED) {
                built.release()
                Log.w(LOG_TAG, "could not initialize the audio track: rate=$rate minBuffer=$minBuffer")
                result.success("init")
                return
            }
            built.setVolume(1f)
            built.play()
            _currentTrack = built
            val toPlay = built
            val durationMillis = pcm.size / 2 * 1000L / rate
            Thread {
                try {
                    android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
                    var offset = 0
                    while (offset < pcm.size) {
                        val written = toPlay.write(pcm, offset, pcm.size - offset)
                        if (written <= 0) {
                            Log.w(LOG_TAG, "audio write stopped at $offset/${pcm.size}")
                            break
                        }
                        offset += written
                    }
                    // wait for the buffered clip to be played before releasing the track
                    Thread.sleep(durationMillis + 200)
                } catch (e: Exception) {
                    Log.w(LOG_TAG, "failed to play the Fail-Safe voice", e)
                } finally {
                    try {
                        toPlay.stop()
                    } catch (_: Exception) {
                    }
                    toPlay.release()
                    _currentTrack = null
                }
            }.start()
            result.success("ok")
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to play the Fail-Safe voice", e)
            try {
                track?.release()
            } catch (_: Exception) {
            }
            result.success("error:${e.javaClass.simpleName}:${e.message}")
        }
    }

    // stops the currently playing Fail-Safe voice clip (if any)
    private fun stopPcm(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val track = _currentTrack
        if (track != null) {
            try {
                track.stop()
            } catch (_: Exception) {
            }
            try {
                track.release()
            } catch (_: Exception) {
            }
            _currentTrack = null
            result.success("ok")
        } else {
            result.success("none")
        }
    }

    // Black Hole (optional root mode): runs a command as root, with a timeout. `null` if root is not available.
    private fun runAsRoot(command: String, timeoutMillis: Long): String? {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val start = SystemClock.elapsedRealtime()
            while (process.isAlive && SystemClock.elapsedRealtime() - start < timeoutMillis) {
                Thread.sleep(50)
            }
            if (process.isAlive) {
                process.destroy()
                return null
            }
            if (process.exitValue() != 0) return null
            process.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            null
        }
    }

    private fun isRootAvailable(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        result.success(runAsRoot("id", 5000)?.contains("uid=0") == true)
    }

    // after deleting files: asks the file system to discard the freed blocks, so they are not left as is on flash storage
    private fun rootTrim(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        result.success(runAsRoot("fstrim /data", 30000) != null)
    }

    // Black Hole (optional root mode): starts a detached root process that outlives the app.
    // It waits for the app process to be gone (the system stops it when the data are cleared), then removes
    // whatever remains of the app data (and only that: the paths are those of this app), then discards the freed blocks.
    // So the destruction goes on even if the app is killed in the middle of it.
    private fun rootSeal(@Suppress("unused_parameter") call: MethodCall, result: MethodChannel.Result) {
        val packageName = context.packageName
        val dirs = listOf(context.dataDir.path, "/data/data/$packageName")
            .filter { it.endsWith("/$packageName") }
            .distinct()
        if (!Regex("[A-Za-z0-9._]+").matches(packageName) || dirs.isEmpty()) {
            result.success(false)
            return
        }
        val pid = android.os.Process.myPid()
        val removal = dirs.joinToString("; ") { "rm -rf '$it'/* '$it'/.[!.]* 2>/dev/null" }
        val script = "while kill -0 $pid 2>/dev/null; do sleep 0.2; done; $removal; fstrim /data"
        result.success(runAsRoot("nohup sh -c \"$script\" >/dev/null 2>&1 &", 5000) != null)
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<SecurityHandler>()
        const val CHANNEL = "deckers.thibault/aves/security"
        const val FILENAME = "secret_shared_prefs"
    }
}