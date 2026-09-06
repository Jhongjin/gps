package app.gyeote.gyeote

import android.content.Context
import android.location.LocationManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.KeyStore
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object GyeoteLocationUploadQueue {
    private const val QUEUE_FILE = "gyeote_location_upload_queue.json"
    private const val MAX_QUEUE_ITEMS = 120
    private const val KEY_ALIAS = "gyeote_location_upload_queue"
    private const val ENCRYPTION_VERSION = 1
    private const val INITIAL_BACKOFF_MS = 15_000L
    private const val MAX_BACKOFF_MS = 5 * 60 * 1000L
    private const val AUTH_BACKOFF_MS = 10 * 60 * 1000L

    @Volatile
    private var isFlushing = false

    @Volatile
    private var nextAttemptAtMs = 0L

    @Volatile
    private var failureStreak = 0

    @Volatile
    private var lastFailureCode: String? = null

    @Synchronized
    fun enqueue(context: Context, payload: Map<String, Any?>) {
        val config = GyeoteLocationState.uploadConfig ?: return
        if (!hasRequiredConfig(config)) return

        val queue = readQueue(context)
        queue.put(JSONObject(payload))
        val trimmed = trimQueue(queue)
        writeQueue(context, trimmed)
    }

    @Synchronized
    fun queueSize(context: Context): Int {
        return readQueue(context).length()
    }

    @Synchronized
    fun resetBackoff() {
        failureStreak = 0
        nextAttemptAtMs = 0L
        lastFailureCode = null
    }

    fun flushAsync(context: Context, locationManager: LocationManager, force: Boolean = false) {
        val appContext = context.applicationContext
        val now = System.currentTimeMillis()
        val retryAt = nextAttemptAtMs

        if (!force && retryAt > now) {
            GyeoteLocationPayloads.emitStatus(
                appContext,
                locationManager,
                "upload_retry_wait",
                retryDetails(appContext, retryAt - now),
            )
            return
        }

        synchronized(this) {
            if (isFlushing) {
                GyeoteLocationPayloads.emitStatus(
                    appContext,
                    locationManager,
                    "upload_already_running",
                    mapOf("pendingCount" to safeQueueLength(appContext)),
                )
                return
            }
            isFlushing = true
        }

        Thread {
            try {
                flush(appContext, locationManager)
            } finally {
                synchronized(this@GyeoteLocationUploadQueue) {
                    isFlushing = false
                }
            }
        }.start()
    }

    @Synchronized
    private fun flush(context: Context, locationManager: LocationManager) {
        val config = GyeoteLocationState.uploadConfig
        if (!hasRequiredConfig(config)) {
            GyeoteLocationPayloads.emitStatus(
                context,
                locationManager,
                "upload_not_configured",
                mapOf("pendingCount" to safeQueueLength(context)),
            )
            return
        }

        val queue = readQueue(context)
        if (queue.length() == 0) {
            resetBackoff()
            GyeoteLocationPayloads.emitStatus(
                context,
                locationManager,
                "upload_queue_empty",
                mapOf("pendingCount" to 0),
            )
            return
        }

        val remaining = JSONArray()
        var uploadedCount = 0
        var firstFailure: UploadFailure? = null

        for (index in 0 until queue.length()) {
            val payload = queue.optJSONObject(index) ?: continue

            try {
                uploadPayload(config!!, payload)
                uploadedCount += 1
            } catch (error: IOException) {
                firstFailure = UploadFailure(
                    code = "upload_network_failed",
                    message = "Network upload failed.",
                )
                remaining.put(payload)
                appendQueueTail(queue, remaining, index + 1)
                break
            } catch (error: UploadHttpException) {
                firstFailure = failureFromHttp(error)
                remaining.put(payload)
                appendQueueTail(queue, remaining, index + 1)
                break
            } catch (error: Exception) {
                firstFailure = UploadFailure(
                    code = "upload_failed",
                    message = error.message ?: "Location upload failed.",
                )
                remaining.put(payload)
                appendQueueTail(queue, remaining, index + 1)
                break
            }
        }

        writeQueue(context, remaining)

        val failure = firstFailure
        if (failure == null) {
            resetBackoff()
            GyeoteLocationPayloads.emitStatus(
                context,
                locationManager,
                "upload_flushed",
                mapOf(
                    "uploadedCount" to uploadedCount,
                    "pendingCount" to 0,
                ),
            )
            return
        }

        val retryInMs = registerFailure(failure)
        val details = mapOf(
            "uploadedCount" to uploadedCount,
            "pendingCount" to remaining.length(),
            "retryInSeconds" to millisToSeconds(retryInMs),
            "httpStatus" to failure.httpStatus,
        )

        if (failure.authRelated) {
            GyeoteLocationPayloads.emitError(
                context,
                locationManager,
                "upload_auth_failed",
                "위치 업로드 인증이 만료됐어요. 앱을 열어 다시 연결해 주세요.",
                details,
            )
        } else {
            GyeoteLocationPayloads.emitStatus(
                context,
                locationManager,
                "upload_retry_scheduled",
                details + ("failureCode" to failure.code),
            )
        }
    }

    private fun uploadPayload(config: Map<String, Any?>, payload: JSONObject) {
        val latestRow = rowFromPayload(config, payload, includeHistoryFields = false)
        val historyRow = rowFromPayload(config, payload, includeHistoryFields = true)

        postgrestRequest(
            config = config,
            path = "/rest/v1/latest_locations?on_conflict=profile_id",
            body = latestRow.toString(),
            prefer = "resolution=merge-duplicates,return=minimal",
        )
        postgrestRequest(
            config = config,
            path = "/rest/v1/location_history?on_conflict=profile_id,idempotency_key",
            body = JSONArray().put(historyRow).toString(),
            prefer = "resolution=ignore-duplicates,return=minimal",
        )
    }

    private fun rowFromPayload(config: Map<String, Any?>, payload: JSONObject, includeHistoryFields: Boolean): JSONObject {
        val sharedCoordinate = payload.optJSONObject("sharedCoordinate")
        val sharingPrecision = sharingPrecision()
        val hideSharedCoordinate = sharingPrecision == "hidden"
        val row = JSONObject()

        row.put("profile_id", config["profileId"])
        row.put("device_id", config["deviceId"])
        row.put("source", payload.optString("source", "unknown"))
        // 원시 좌표는 올리지 않는다. 페이로드에는 남아 있지만 그건 기기 안에서
        // 민감 장소를 판정하는 용도이고, 서버에는 가려진 좌표만 간다.
        row.putNullable("shared_lat", if (hideSharedCoordinate) null else sharedCoordinate?.optDoubleOrNull("latitude"))
        row.putNullable("shared_lng", if (hideSharedCoordinate) null else sharedCoordinate?.optDoubleOrNull("longitude"))
        row.putNullable("accuracy_m", payload.optDoubleOrNull("accuracyM"))
        row.put("sharing_precision", sharingPrecision)
        row.put("recorded_at", payload.optString("recordedAt", isoDate(System.currentTimeMillis())))

        if (!includeHistoryFields) {
            row.put("updated_at", isoDate(System.currentTimeMillis()))
            row.putNullable("speed_mps", payload.optDoubleOrNull("speedMps"))
            row.putNullable("heading_deg", payload.optDoubleOrNull("headingDeg"))
            row.putNullable("battery_percent", payload.optIntOrNull("batteryPercent"))
        } else {
            row.put("idempotency_key", idempotencyKey(config, payload))
            val companionSessionId = GyeoteLocationState.activeSession?.get("companionSessionId") as? String
            row.putNullable("companion_session_id", companionSessionId)
        }

        return row
    }

    private fun postgrestRequest(config: Map<String, Any?>, path: String, body: String, prefer: String) {
        val supabaseUrl = "${config["supabaseUrl"]}".trimEnd('/')
        val publishableKey = "${config["publishableKey"]}"
        val accessToken = "${config["accessToken"]}"
        val connection = URL("$supabaseUrl$path").openConnection() as HttpURLConnection

        try {
            connection.requestMethod = "POST"
            connection.connectTimeout = 10_000
            connection.readTimeout = 15_000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("apikey", publishableKey)
            connection.setRequestProperty("Authorization", "Bearer $accessToken")
            connection.setRequestProperty("Prefer", prefer)

            connection.outputStream.use { output ->
                output.write(body.toByteArray(Charsets.UTF_8))
            }

            val status = connection.responseCode
            if (status !in 200..299) {
                throw UploadHttpException(status, readErrorBody(connection))
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun readQueue(context: Context): JSONArray {
        val file = queueFile(context)
        if (!file.exists()) {
            return JSONArray()
        }

        val raw = file.readText()
        return runCatching {
            val trimmed = raw.trim()
            if (trimmed.startsWith("[")) {
                JSONArray(trimmed)
            } else {
                JSONArray(decryptQueuePayload(JSONObject(trimmed)))
            }
        }.getOrDefault(JSONArray())
    }

    private fun writeQueue(context: Context, queue: JSONArray) {
        queueFile(context).writeText(encryptQueuePayload(queue.toString()))
    }

    private fun queueFile(context: Context): File {
        return File(context.filesDir, QUEUE_FILE)
    }

    private fun trimQueue(queue: JSONArray): JSONArray {
        if (queue.length() <= MAX_QUEUE_ITEMS) {
            return queue
        }

        val trimmed = JSONArray()
        for (index in queue.length() - MAX_QUEUE_ITEMS until queue.length()) {
            trimmed.put(queue.get(index))
        }
        return trimmed
    }

    private fun appendQueueTail(source: JSONArray, target: JSONArray, startIndex: Int) {
        for (index in startIndex until source.length()) {
            target.put(source.get(index))
        }
    }

    private fun hasRequiredConfig(config: Map<String, Any?>?): Boolean {
        if (config == null) return false
        return listOf("supabaseUrl", "publishableKey", "accessToken", "profileId", "deviceId").all {
            !config[it]?.toString().isNullOrBlank()
        }
    }

    private fun sharingPrecision(): String {
        return when (GyeoteLocationState.sharingPolicy["mode"] as? String ?: "balanced") {
            "sosOnly" -> "sos_only"
            else -> GyeoteLocationState.sharingPolicy["mode"] as? String ?: "balanced"
        }
    }

    private fun idempotencyKey(config: Map<String, Any?>, payload: JSONObject): String {
        val existing = payload.optString("idempotencyKey", "")
        if (existing.startsWith("${config["deviceId"]}-")) {
            return existing
        }

        val sequence = payload.optLong("sequence", 0L)
        val recordedAt = payload.optString("recordedAt", isoDate(System.currentTimeMillis()))
        return "${config["deviceId"]}-$sequence-$recordedAt"
    }

    private fun failureFromHttp(error: UploadHttpException): UploadFailure {
        val authRelated = error.statusCode == 401 || error.statusCode == 403
        val code = if (authRelated) "upload_auth_failed" else "upload_http_${error.statusCode}"
        return UploadFailure(
            code = code,
            message = error.responseBody.ifBlank { "Supabase upload failed with HTTP ${error.statusCode}." },
            authRelated = authRelated,
            httpStatus = error.statusCode,
        )
    }

    private fun registerFailure(failure: UploadFailure): Long {
        failureStreak = (failureStreak + 1).coerceAtMost(6)
        lastFailureCode = failure.code
        val multiplier = 1L shl (failureStreak - 1).coerceAtMost(5)
        val retryInMs = if (failure.authRelated) {
            AUTH_BACKOFF_MS
        } else {
            (INITIAL_BACKOFF_MS * multiplier).coerceAtMost(MAX_BACKOFF_MS)
        }
        nextAttemptAtMs = System.currentTimeMillis() + retryInMs
        return retryInMs
    }

    private fun retryDetails(context: Context, remainingMs: Long): Map<String, Any?> {
        val details = mutableMapOf<String, Any?>(
            "pendingCount" to safeQueueLength(context),
            "retryInSeconds" to millisToSeconds(remainingMs),
        )
        lastFailureCode?.let { details["failureCode"] = it }
        return details
    }

    private fun safeQueueLength(context: Context): Int {
        return runCatching { readQueue(context).length() }.getOrDefault(0)
    }

    private fun millisToSeconds(value: Long): Long {
        return ((value.coerceAtLeast(0L) + 999L) / 1000L).coerceAtLeast(1L)
    }

    private fun readErrorBody(connection: HttpURLConnection): String {
        val stream = connection.errorStream ?: runCatching { connection.inputStream }.getOrNull()
        return stream
            ?.bufferedReader(Charsets.UTF_8)
            ?.use { reader -> reader.readText().take(240) }
            .orEmpty()
    }

    private fun isoDate(timeMs: Long): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(Date(timeMs))
    }

    private fun encryptQueuePayload(plainText: String): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return plainText
        }

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey())
        val ciphertext = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        return JSONObject()
            .put("version", ENCRYPTION_VERSION)
            .put("algorithm", "AES/GCM/NoPadding")
            .put("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .put("ciphertext", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
            .toString()
    }

    private fun decryptQueuePayload(envelope: JSONObject): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return "[]"
        }

        val iv = Base64.decode(envelope.getString("iv"), Base64.NO_WRAP)
        val ciphertext = Base64.decode(envelope.getString("ciphertext"), Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateSecretKey(), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
    }

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        if (existing != null) {
            return existing.secretKey
        }

        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)
            .build()

        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private fun JSONObject.putNullable(key: String, value: Any?) {
        put(key, value ?: JSONObject.NULL)
    }

    private fun JSONObject.optDoubleOrNull(key: String): Double? {
        val value = if (has(key) && !isNull(key)) opt(key) else null
        val doubleValue = when (value) {
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        }
        return doubleValue?.takeIf { it.isFinite() }
    }

    private fun JSONObject.optIntOrNull(key: String): Int? {
        val value = if (has(key) && !isNull(key)) opt(key) else null
        return when (value) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
    }

    private data class UploadFailure(
        val code: String,
        val message: String,
        val authRelated: Boolean = false,
        val httpStatus: Int? = null,
    )

    private class UploadHttpException(
        val statusCode: Int,
        val responseBody: String,
    ) : Exception("Supabase upload failed with HTTP $statusCode")
}
