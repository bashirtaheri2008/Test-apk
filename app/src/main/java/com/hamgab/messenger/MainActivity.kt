package com.hamgab.messenger

import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.hamgab.messenger.adapter.ChatListAdapter
import com.hamgab.messenger.auth.AuthActivity
import com.hamgab.messenger.chat.ChatActivity
import com.hamgab.messenger.data.FirestoreApi
import com.hamgab.messenger.data.Prefs
import com.hamgab.messenger.databinding.ActivityMainBinding
import com.hamgab.messenger.databinding.DialogAddContactBinding
import com.hamgab.messenger.profile.ProfileActivity
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var prefs: Prefs
    private val api = FirestoreApi()
    private lateinit var adapter: ChatListAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        // Guard — must be logged in
        if (!prefs.isLoggedIn) {
            startActivity(Intent(this, AuthActivity::class.java))
            finish()
            return
        }

        setSupportActionBar(binding.toolbar)

        adapter = ChatListAdapter(mutableListOf()) { chatItem ->
            val intent = Intent(this, ChatActivity::class.java)
            intent.putExtra("partnerId", chatItem.partnerId)
            intent.putExtra("partnerName", chatItem.partnerName)
            intent.putExtra("partnerPhoto", chatItem.partnerPhoto)
            startActivity(intent)
        }

        binding.chatList.layoutManager = LinearLayoutManager(this)
        binding.chatList.adapter = adapter

        binding.swipeRefresh.setOnRefreshListener { loadChats() }

        binding.fabNewChat.setOnClickListener { showAddContactDialog() }

        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_profile -> {
                    startActivity(Intent(this, ProfileActivity::class.java))
                    true
                }
                R.id.action_about -> {
                    showAboutDialog()
                    true
                }
                R.id.action_logout -> {
                    prefs.logout()
                    startActivity(Intent(this, AuthActivity::class.java))
                    finish()
                    true
                }
                else -> false
            }
        }

        loadChats()
    }

    private fun loadChats() {
        binding.swipeRefresh.isRefreshing = true
        lifecycleScope.launch {
            val chats = api.getUserChats(prefs.uid)
            binding.swipeRefresh.isRefreshing = false

            if (chats.isEmpty()) {
                binding.emptyState.visibility = View.VISIBLE
                binding.chatList.visibility = View.GONE
            } else {
                binding.emptyState.visibility = View.GONE
                binding.chatList.visibility = View.VISIBLE
                adapter.update(chats)
            }
        }
    }

    private fun showAddContactDialog() {
        val dialogBinding = DialogAddContactBinding.inflate(LayoutInflater.from(this))
        val dialog = AlertDialog.Builder(this)
            .setView(dialogBinding.root)
            .create()

        dialogBinding.addBtn.setOnClickListener {
            val phone = dialogBinding.contactPhone.text.toString().trim()
            if (!phone.matches(Regex("\\+93\\d{9}")) && !phone.matches(Regex("93\\d{9}")) && !phone.matches(Regex("\\d{9}"))) {
                Toast.makeText(this, "شماره نامعتبر است. مثال: +93745872028", Toast.LENGTH_LONG).show()
                return@setOnClickListener
            }

            val normalizedPhone = if (phone.startsWith("+")) phone else "+93$phone"
            lifecycleScope.launch {
                val user = api.addContactByPhone(prefs.uid, normalizedPhone)
                if (user != null) {
                    api.ensureChatExists(prefs.uid, user.uid, user.name.ifEmpty { normalizedPhone }, prefs.name)
                    dialog.dismiss()
                    Toast.makeText(this@MainActivity, "مخاطب اضافه شد", Toast.LENGTH_SHORT).show()
                    loadChats()
                    // Open chat
                    val intent = Intent(this@MainActivity, ChatActivity::class.java)
                    intent.putExtra("partnerId", user.uid)
                    intent.putExtra("partnerName", user.name.ifEmpty { normalizedPhone })
                    intent.putExtra("partnerPhoto", user.photoURL)
                    startActivity(intent)
                } else {
                    Toast.makeText(this@MainActivity, "خطا در افزودن مخاطب", Toast.LENGTH_SHORT).show()
                }
            }
        }

        dialog.show()
    }

    private fun showAboutDialog() {
        AlertDialog.Builder(this)
            .setTitle("درباره هم‌گب")
            .setMessage("پیام‌رسان هم‌گب\nنسخه 2.0\nارتباط امن، سریع و هوشمند")
            .setPositiveButton("باشه", null)
            .show()
    }

    override fun onResume() {
        super.onResume()
        loadChats()
    }
}
