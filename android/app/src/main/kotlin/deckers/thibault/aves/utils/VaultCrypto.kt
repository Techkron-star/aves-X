package deckers.thibault.aves.utils

import android.content.Context
import android.util.Log
import com.google.crypto.tink.KeyTemplates
import com.google.crypto.tink.StreamingAead
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import com.google.crypto.tink.streamingaead.StreamingAeadConfig
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest

// "Bat-curity": encryption at rest of vault files.
// Files keep their name and modification date, and start with a magic header when encrypted.
// The key is wrapped by an Android Keystore key (it never leaves the secure hardware unwrapped).
// Each operation writes a temporary file, verifies it, and only then atomically replaces the original.
class VaultCrypto(private val context: Context) {
    private val streamingAead: StreamingAead by lazy {
        StreamingAeadConfig.register()
        AndroidKeysetManager.Builder()
            .withSharedPref(context, KEYSET_NAME, KEYSET_PREFS)
            .withKeyTemplate(KeyTemplates.get("AES256_GCM_HKDF_4KB"))
            .withMasterKeyUri(MASTER_KEY_URI)
            .build()
            .keysetHandle
            .getPrimitive(StreamingAead::class.java)
    }

    data class Report(val done: Int, val skipped: Int, val failed: Int)

    // encrypts (or decrypts) all the files directly inside the directory
    fun processDirectory(dir: File, encrypt: Boolean): Report {
        var done = 0
        var skipped = 0
        var failed = 0
        val files = dir.listFiles() ?: return Report(0, 0, 0)
        for (file in files) {
            if (file.name.endsWith(TEMP_SUFFIX)) {
                // leftover of an interrupted operation: the original file is still untouched
                file.delete()
                continue
            }
            if (!file.isFile) continue
            try {
                val isEncrypted = isEncrypted(file)
                if (isEncrypted == encrypt) {
                    skipped++
                } else if (if (encrypt) encryptFile(file) else decryptFile(file)) {
                    done++
                } else {
                    failed++
                }
            } catch (e: Exception) {
                Log.w(LOG_TAG, "failed to process file=${file.path} encrypt=$encrypt", e)
                File(file.path + TEMP_SUFFIX).delete()
                failed++
            }
        }
        return Report(done, skipped, failed)
    }

    private fun isEncrypted(file: File): Boolean {
        if (file.length() < MAGIC.size) return false
        FileInputStream(file).use { input ->
            val header = ByteArray(MAGIC.size)
            return input.read(header) == MAGIC.size && header.contentEquals(MAGIC)
        }
    }

    private fun encryptFile(file: File): Boolean {
        val temp = File(file.path + TEMP_SUFFIX)
        temp.delete()
        val modified = file.lastModified()

        val originalDigest = MessageDigest.getInstance(DIGEST)
        FileInputStream(file).use { input ->
            FileOutputStream(temp).use { output ->
                output.write(MAGIC)
                streamingAead.newEncryptingStream(output, ASSOCIATED_DATA).use { encrypting ->
                    copyDigesting(input, encrypting, originalDigest)
                }
            }
        }

        // verify that the encrypted copy decrypts to the exact same content
        val verifyDigest = MessageDigest.getInstance(DIGEST)
        decryptingStream(temp).use { decrypting -> copyDigesting(decrypting, null, verifyDigest) }
        if (!originalDigest.digest().contentEquals(verifyDigest.digest())) {
            temp.delete()
            return false
        }

        return replace(temp, file, modified)
    }

    private fun decryptFile(file: File): Boolean {
        val temp = File(file.path + TEMP_SUFFIX)
        temp.delete()
        val modified = file.lastModified()

        decryptingStream(file).use { decrypting ->
            FileOutputStream(temp).use { output ->
                copyDigesting(decrypting, output, null)
                output.fd.sync()
            }
        }
        return replace(temp, file, modified)
    }

    private fun decryptingStream(file: File): java.io.InputStream {
        val input = FileInputStream(file)
        val skipped = input.skip(MAGIC.size.toLong())
        if (skipped != MAGIC.size.toLong()) {
            input.close()
            throw IllegalStateException("truncated file")
        }
        return streamingAead.newDecryptingStream(input, ASSOCIATED_DATA)
    }

    private fun replace(temp: File, target: File, modified: Long): Boolean {
        // atomic when on the same file system, which is the case in the same directory
        if (!temp.renameTo(target)) {
            temp.delete()
            return false
        }
        target.setLastModified(modified)
        return true
    }

    private fun copyDigesting(input: java.io.InputStream, output: java.io.OutputStream?, digest: MessageDigest?) {
        val buffer = ByteArray(BUFFER_SIZE)
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            digest?.update(buffer, 0, count)
            output?.write(buffer, 0, count)
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<VaultCrypto>()

        private const val KEYSET_NAME = "avesx_vault_keyset"
        private const val KEYSET_PREFS = "avesx_vault_keyset_prefs"
        private const val MASTER_KEY_URI = "android-keystore://avesx_vault_master_key"
        private const val TEMP_SUFFIX = ".avxtmp"
        private const val DIGEST = "SHA-256"
        private const val BUFFER_SIZE = 64 * 1024
        private val ASSOCIATED_DATA = ByteArray(0)
        private val MAGIC = byteArrayOf(0x41, 0x56, 0x58, 0x45, 0x4E, 0x43, 0x31, 0x00) // "AVXENC1\0"
    }
}
