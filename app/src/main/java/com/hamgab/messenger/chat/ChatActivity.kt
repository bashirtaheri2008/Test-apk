package com.hamgab.messenger.chat

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bumptech.glide.Glide
import com.hamgab.messenger.R
import com.hamgab.messenger.adapter.MessageAdapter
import com.hamgab.messenger.data.FirestoreApi
import com.hamgab.messenger.data.Prefs
import com.hamgab.messenger.databinding.ActivityChatBinding
import kotlinx.coroutines.launch

class ChatActivity : AppCompatActivity() {

    private lateinit var binding: ActivityChatBinding
    private lateinit var prefs: Prefs
    private val api = FirestoreApi()
    private lateinit var adapter: MessageAdapter
    private var partnerId = ""
    private var partnerName = ""
    private var partnerPhoto = ""
    private val handler = Handler(Looper.getMainLooper())
    private var pollRunnable: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChatBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        partnerId = intent.getStringExtra("partnerId") ?: ""
        partnerName = intent.getStringExtra("partnerName") ?: "نامشخص"
        partnerPhoto = intent.getStringExtra("partnerPhoto") ?: ""

        // Setup toolbar
        binding.chatName.text = partnerName
        binding.chatStatus.text = "آخرین بازدید اخیراً"
        if (partnerPhoto.isNotEmpty()) {
            Glide.with(this).load(partnerPhoto).circleCrop().into(binding.chatAvatar)
        }

        binding.toolbar.setNavigationOnClickListener { finish() }

        // Setup messages list
        adapter = MessageAdapter(prefs.uid)
        binding.messagesList.layoutManager = LinearLayoutManager(this).apply {
            stackFromEnd = true
        }
        binding.messagesList.adapter = adapter

        // Message input watcher
        binding.messageInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                val hasText = !s.isNullOrBlank()
                binding.btnSend.visibility = if (hasText) View.VISIBLE else View.GONE
                binding.btnMic.visibility = if (hasText) View.GONE else View.VISIBLE
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        // Send button
        binding.btnSend.setOnClickListener {
            val text = binding.messageInput.text.toString().trim()
            if (text.isNotEmpty()) {
                sendMessage(text)
                binding.messageInput.text.clear()
            }
        }

        // Mic button (placeholder)
        binding.btnMic.setOnClickListener {
            Toast.makeText(this, "ضبط صوت به‌زودی!", Toast.LENGTH_SHORT).show()
        }

        // Attach button
        binding.btnAttach.setOnClickListener {
            Toast.makeText(this, "ارسال فایل به‌زودی!", Toast.LENGTH_SHORT).show()
        }

        // Call button
        binding.btnCall.setOnClickListener {
            Toast.makeText(this, "تماس صوتی به‌زودی!", Toast.LENGTH_SHORT).show()
        }

        loadMessages()
        startPolling()
    }

    private fun sendMessage(text: String) {
        lifecycleScope.launch {
            val success = api.sendMessage(prefs.uid, partnerId, text, prefs.name)
            if (success) {
                loadMessages()
            } else {
                Toast.makeText(this@ChatActivity, "خطا در ارسال پیام", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun loadMessages() {
        lifecycleScope.launch {
            val messages = api.getChatMessages(prefs.uid, partnerId)
            if (messages.isNotEmpty()) {
                adapter.update(messages)
                binding.messagesList.scrollToPosition(adapter.itemCount - 1)
            }
        }
    }

    private fun startPolling() {
        pollRunnable = object : Runnable {
            override fun run() {
                loadMessages()
                handler.postDelayed(this, 5000)
            }
        }
        handler.postDelayed(pollRunnable!!, 5000)
    }

    override fun onDestroy() {
        super.onDestroy()
        pollRunnable?.let { handler.removeCallbacks(it) }
    }
}
