package com.hamgab.messenger.data

import android.content.Context
import android.content.SharedPreferences

class Prefs(context: Context) {
    private val sp: SharedPreferences = context.getSharedPreferences("hamgab", Context.MODE_PRIVATE)

    var uid: String
        get() = sp.getString("uid", "") ?: ""
        set(v) { sp.edit().putString("uid", v).apply() }

    var phone: String
        get() = sp.getString("phone", "") ?: ""
        set(v) { sp.edit().putString("phone", v).apply() }

    var name: String
        get() = sp.getString("name", "") ?: ""
        set(v) { sp.edit().putString("name", v).apply() }

    var bio: String
        get() = sp.getString("bio", "") ?: ""
        set(v) { sp.edit().putString("bio", v).apply() }

    var photoURL: String
        get() = sp.getString("photoURL", "") ?: ""
        set(v) { sp.edit().putString("photoURL", v).apply() }

    var isDarkTheme: Boolean
        get() = sp.getBoolean("dark_theme", false)
        set(v) { sp.edit().putBoolean("dark_theme", v).apply() }

    var isLoggedIn: Boolean
        get() = sp.getBoolean("logged_in", false)
        set(v) { sp.edit().putBoolean("logged_in", v).apply() }

    fun logout() {
        sp.edit().clear().apply()
    }
}
