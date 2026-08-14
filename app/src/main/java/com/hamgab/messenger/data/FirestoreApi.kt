package com.hamgab.messenger.data

import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class FirestoreApi {

    companion object {
        private const val PROJECT_ID = "web-rasa"
        private const val BASE = "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

        // IMGBB key from original app
        const val IMGBB_KEY = "8efbeb33b4488d0dc418b081df38d21b"

        private val client: OkHttpClient = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

        private val gson = Gson()
        private val JSON = "application/json".toMediaType()

        private fun esc(value: String): String {
            val sb = StringBuilder()
            for (c in value) {
                when (c) {
                    '\\', '"', '/', '\n', '\r', '\t' -> {
                        sb.append('\\')
                        when (c) { '\\' -> sb.append('\\'); '"' -> sb.append('"'); '/' -> sb.append('/'); '\n' -> sb.append('n'); '\r' -> sb.append('r'); '\t' -> sb.append('t'); else -> sb.append(c) }
                    }
                    else -> {
                        if (c.code < 0x20 || c.code > 0x10FFFF) sb.append("\\u${"%04x".format(c.code)}")
                        else sb.append(c)
                    }
                }
            }
            return sb.toString()
        }

        // Convert a Kotlin map to Firestore REST fields JSON
        private fun toFields(data: Map<String, Any?>): String {
            val sb = StringBuilder("{")
            var first = true
            for ((key, value) in data) {
                if (!first) sb.append(",")
                first = false
                sb.append("\"").append(key).append("\":")
                when (value) {
                    is String -> sb.append("{\"stringValue\":\"").append(esc(value)).append("\"}")
                    is Int -> sb.append("{\"integerValue\":\"").append(value).append("\"}")
                    is Long -> sb.append("{\"integerValue\":\"").append(value).append("\"}")
                    is Boolean -> sb.append("{\"booleanValue\":").append(value).append("}")
                    null -> sb.append("{\"nullValue\":null}")
                    else -> sb.append("{\"stringValue\":\"").append(esc(value.toString())).append("\"}")
                }
            }
            sb.append("}")
            return sb.toString()
        }

        private fun getString(field: FirestoreValue?): String = field?.stringValue ?: ""

        private fun getLong(field: FirestoreValue?): Long = field?.integerValue?.toLongOrNull() ?: 0L

        private fun getBool(field: FirestoreValue?): Boolean = field?.booleanValue ?: false

        fun docToUser(doc: FirestoreDocument): User {
            val f = doc.fields
            return User(
                uid = doc.name.substringAfterLast("/"),
                name = getString(f?.get("name")),
                bio = getString(f?.get("bio")),
                photoURL = getString(f?.get("photoURL")),
                verified = getBool(f?.get("verified")),
                phone = getString(f?.get("phone"))
            )
        }

        fun docToMessage(doc: FirestoreDocument): Message {
            val f = doc.fields
            return Message(
                id = doc.name.substringAfterLast("/"),
                text = getString(f?.get("text")),
                senderId = getString(f?.get("senderId")),
                senderName = getString(f?.get("senderName")),
                timestamp = getLong(f?.get("timestamp")),
                type = getString(f?.get("type")).ifEmpty { "text" },
                imageURL = getString(f?.get("imageURL"))
            )
        }

        private fun chatId(a: String, b: String): String {
            return if (a < b) "${a}_$b" else "${b}_$a"
        }
    }

    suspend fun getUser(uid: String): User? = withContext(Dispatchers.IO) {
        try {
            val req = Request.Builder().url("$BASE/users/$uid").get().build()
            val res = client.newCall(req).execute()
            if (!res.isSuccessful) return@withContext null
            val doc = gson.fromJson(res.body?.string(), FirestoreDocument::class.java)
            docToUser(doc)
        } catch (e: Exception) { null }
    }

    suspend fun createOrUpdateUser(uid: String, phone: String, name: String, bio: String, photoURL: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val data = mapOf(
                "phone" to phone,
                "name" to name,
                "bio" to bio,
                "photoURL" to photoURL,
                "verified" to false
            )
            val body = "{\"fields\":${toFields(data)}}".toRequestBody(JSON)
            val req = Request.Builder()
                .url("$BASE/users/$uid?updateMask.fieldPaths=phone&updateMask.fieldPaths=name&updateMask.fieldPaths=bio&updateMask.fieldPaths=photoURL&updateMask.fieldPaths=verified")
                .patch(body)
                .build()
            val res = client.newCall(req).execute()
            res.isSuccessful
        } catch (e: Exception) { false }
    }

    suspend fun getChatMessages(uid: String, partnerId: String): List<Message> = withContext(Dispatchers.IO) {
        try {
            val cid = chatId(uid, partnerId)
            val req = Request.Builder()
                .url("$BASE/chats/$cid/messages?orderBy=timestamp&pageSize=100")
                .get()
                .build()
            val res = client.newCall(req).execute()
            if (!res.isSuccessful) return@withContext emptyList()
            val list = gson.fromJson(res.body?.string(), FirestoreListResponse::class.java)
            list?.documents?.map { docToMessage(it) } ?: emptyList()
        } catch (e: Exception) { emptyList() }
    }

    suspend fun sendMessage(uid: String, partnerId: String, text: String, senderName: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val cid = chatId(uid, partnerId)
            val ts = System.currentTimeMillis()
            val data = mapOf(
                "text" to text,
                "senderId" to uid,
                "senderName" to senderName,
                "timestamp" to ts,
                "type" to "text"
            )
            val body = "{\"fields\":${toFields(data)}}".toRequestBody(JSON)
            val req = Request.Builder()
                .url("$BASE/chats/$cid/messages")
                .post(body)
                .build()
            val res = client.newCall(req).execute()
            res.isSuccessful
        } catch (e: Exception) { false }
    }

    suspend fun getUserChats(uid: String): List<ChatItem> = withContext(Dispatchers.IO) {
        try {
            // Query chats where members array contains uid
            // Firestore REST structuredQuery
            val queryBody = """
                {"structuredQuery":{"from":[{"collectionId":"chats"}],"where":{"fieldFilter":{"field":{"fieldPath":"members"},"filter":{"arrayFilter":{"operator":"ARRAY_CONTAINS","value":{"stringValue":"$uid"}}}}},"orderBy":[{"field":{"fieldPath":"lastTimestamp"},"direction":"DESCENDING"}]}}
            """.trimIndent()

            val req = Request.Builder()
                .url("$BASE:runQuery")
                .post(queryBody.toRequestBody(JSON))
                .build()
            val res = client.newCall(req).execute()
            if (!res.isSuccessful) return@withContext emptyList()
            val responseText = res.body?.string() ?: return@withContext emptyList()

            // Parse response — array of documents
            val docs = gson.fromJson(responseText, Array<FirestoreDocument>::class.java)
            docs?.mapNotNull { doc ->
                val f = doc.fields ?: return@mapNotNull null
                val chatDocId = doc.name.substringAfterLast("/")
                // Extract the partner ID from members array
                val membersArr = f["members"]?.arrayValue?.values?.map { it.stringValue ?: "" } ?: emptyList()
                val partnerId = membersArr.firstOrNull { it != uid } ?: ""
                if (partnerId.isEmpty()) return@mapNotNull null

                val partner = getUser(partnerId)
                ChatItem(
                    chatId = chatDocId,
                    partnerId = partnerId,
                    partnerName = partner?.name ?: partnerId,
                    partnerPhoto = partner?.photoURL ?: "",
                    lastMessage = getString(f["lastMessage"]),
                    lastTimestamp = getLong(f["lastTimestamp"]),
                    unreadCount = getLong(f["unreadCount"]).toInt()
                )
            } ?: emptyList()
        } catch (e: Exception) { emptyList() }
    }

    suspend fun ensureChatExists(uid: String, partnerId: String, partnerName: String, myName: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val cid = chatId(uid, partnerId)
            // Check if chat document exists
            val checkReq = Request.Builder().url("$BASE/chats/$cid").get().build()
            val checkRes = client.newCall(checkReq).execute()
            if (checkRes.isSuccessful) return@withContext true // already exists

            // Create chat doc
            val data = mapOf(
                "members" to uid, // will be overwritten below
                "lastMessage" to "",
                "lastTimestamp" to System.currentTimeMillis(),
                "createdAt" to System.currentTimeMillis()
            )
            // We need array for members — build manually
            val body = """
                {"fields":{
                    "members":{"arrayValue":{"values":[{"stringValue":"$uid"},{"stringValue":"$partnerId"}]}},
                    "lastMessage":{"stringValue":""},
                    "lastTimestamp":{"integerValue":"${System.currentTimeMillis()}"},
                    "createdAt":{"integerValue":"${System.currentTimeMillis()}"}
                }}
            """.trimIndent().toRequestBody(JSON)

            val req = Request.Builder().url("$BASE/chats/$cid").patch(body).build()
            val res = client.newCall(req).execute()
            res.isSuccessful
        } catch (e: Exception) { false }
    }

    suspend fun addContactByPhone(myUid: String, phone: String): User? = withContext(Dispatchers.IO) {
        try {
            val uid = phone.replace(Regex("[^0-9]"), "")
            // Check if this user exists
            val user = getUser(uid)
            if (user != null && user.uid.isNotEmpty()) {
                return@withContext user
            }
            // Create a placeholder user
            createOrUpdateUser(uid, phone, "", "", "")
            getUser(uid)
        } catch (e: Exception) { null }
    }

    suspend fun updateUserProfile(uid: String, name: String, bio: String, photoURL: String): Boolean = withContext(Dispatchers.IO) {
        createOrUpdateUser(uid, "", name, bio, photoURL)
    }
}
