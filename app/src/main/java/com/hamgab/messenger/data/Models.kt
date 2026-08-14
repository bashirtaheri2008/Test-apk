package com.hamgab.messenger.data

import com.google.gson.annotations.SerializedName

data class User(
    val uid: String = "",
    val name: String = "",
    val bio: String = "",
    val photoURL: String = "",
    val verified: Boolean = false,
    val phone: String = ""
)

data class Message(
    val id: String = "",
    val text: String = "",
    val senderId: String = "",
    val senderName: String = "",
    val timestamp: Long = 0,
    val type: String = "text",
    val imageURL: String = ""
) : java.io.Serializable

data class ChatItem(
    val chatId: String = "",
    val partnerId: String = "",
    val partnerName: String = "",
    val partnerPhoto: String = "",
    val lastMessage: String = "",
    val lastTimestamp: Long = 0,
    val unreadCount: Int = 0
)

data class Contact(
    val uid: String = "",
    val name: String = "",
    val phone: String = "",
    val photoURL: String = ""
)

// Firestore REST API response wrappers
data class FirestoreDocument(
    val name: String = "",
    val fields: Map<String, FirestoreValue>? = null,
    @SerializedName("createTime") val createTime: String? = null,
    @SerializedName("updateTime") val updateTime: String? = null
)

data class FirestoreValue(
    val stringValue: String? = null,
    val integerValue: String? = null,
    val booleanValue: Boolean? = null,
    val timestampValue: String? = null,
    val arrayValue: FirestoreArray? = null,
    val mapValue: FirestoreMap? = null,
    val doubleValue: Double? = null
)

data class FirestoreArray(
    val values: List<FirestoreValue>? = null
)

data class FirestoreMap(
    val fields: Map<String, FirestoreValue>? = null
)

data class FirestoreListResponse(
    val documents: List<FirestoreDocument>? = null,
    @SerializedName("nextPageToken") val nextPageToken: String? = null
)
