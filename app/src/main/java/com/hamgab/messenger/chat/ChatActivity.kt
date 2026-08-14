package com.hamgab.messenger.chat

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bumptech.glide.Glide
import com.hamgab.messenger.data.FirestoreApi
import com.hamgab.messenger.data.Message
import com.hamgab.messenger.data.Prefs
import com.hamgab.messenger.adapter.MessageAdapter
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
    private var pollRunning = true

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (pollRunning) {
                loadMessages()
                handler.postDelayed(this, 3000)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChatBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        partnerId = intent.getStringExtra("partnerId") ?: ""
        partnerName = intent.getStringExtra("partnerName") ?: ""
        partnerPhoto = intent.getStringExtra("partnerPhoto") ?: ""

        if (partnerId.isEmpty()) {
            finish()
            return
        }

        // Setup header
        binding.partnerName.text = partnerName
        if (partnerPhoto.isNotEmpty()) {
            Glide.with(this).load(partnerPhoto).circleCrop().into(binding.partnerAvatar)
        }

        binding.backBtn.setOnClickListener { finish() }

        // Setup messages list
        adapter = MessageAdapter(prefs.uid)
        binding.messagesList.layoutManager = LinearLayoutManager(this).apply {
            stackFromEnd = true
        }
        binding.messagesList.adapter = adapter

        // Send button
        binding.sendBtn.setOnClickListener {
            val text = binding.messageInput.text.toString().trim()
            if (text.isNotEmpty()) {
                sendMessage(text)
                binding.messageInput.text?.clear()
            }
        }

        loadMessages()
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

    private fun sendMessage(text: String) {
        lifecycleScope.launch {
            api.ensureChatExists(prefs.uid, partnerId, partnerName, prefs.name)
            val success = api.sendMessage(prefs.uid, partnerId, text, prefs.name)
            if (success) {
                val msg = Message(
                    senderId = prefs.uid,
                    senderName = prefs.name,
                    text = text,
                    timestamp = System.currentTimeMillis()
                )
                adapter.addMessage(msg)
                binding.messagesList.scrollToPosition(adapter.itemCount - 1)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        pollRunning = true
        handler.postDelayed(pollRunnable, 3000)
    }

    override fun onPause() {
        super.onPause()
        pollRunning = false
        handler.removeCallbacks(pollRunnable)
    }

    override fun onDestroy() {
        super.onDestroy()
        pollRunning = false
        handler.removeCallbacks(pollRunnable)
    }
}
