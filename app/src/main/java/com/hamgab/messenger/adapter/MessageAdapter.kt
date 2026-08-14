package com.hamgab.messenger.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.hamgab.messenger.data.Message
import com.hamgab.messenger.databinding.ItemMessageReceivedBinding
import com.hamgab.messenger.databinding.ItemMessageSentBinding

class MessageAdapter(
    private val myUid: String
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val TYPE_SENT = 1
        private const val TYPE_RECEIVED = 2
    }

    private val items = mutableListOf<Message>()

    fun update(messages: List<Message>) {
        items.clear()
        items.addAll(messages.sortedBy { it.timestamp })
        notifyDataSetChanged()
    }

    fun addMessage(msg: Message) {
        items.add(msg)
        notifyItemInserted(items.size - 1)
    }

    override fun getItemViewType(position: Int): Int {
        return if (items[position].senderId == myUid) TYPE_SENT else TYPE_RECEIVED
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            TYPE_SENT -> {
                val binding = ItemMessageSentBinding.inflate(LayoutInflater.from(parent.context), parent, false)
                SentVH(binding)
            }
            else -> {
                val binding = ItemMessageReceivedBinding.inflate(LayoutInflater.from(parent.context), parent, false)
                ReceivedVH(binding)
            }
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val msg = items[position]
        when (holder) {
            is SentVH -> holder.bind(msg)
            is ReceivedVH -> holder.bind(msg)
        }
    }

    override fun getItemCount() = items.size

    inner class SentVH(val binding: ItemMessageSentBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(msg: Message) {
            binding.messageText.text = msg.text
            binding.messageTime.text = formatTime(msg.timestamp)
            // Status: show double check for "read" (simplified: always show double check)
            binding.statusIcon.setImageResource(R.drawable.ic_check_double)
        }
    }

    inner class ReceivedVH(val binding: ItemMessageReceivedBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(msg: Message) {
            binding.messageText.text = msg.text
            binding.messageTime.text = formatTime(msg.timestamp)
        }
    }

    private fun formatTime(ts: Long): String {
        if (ts == 0L) return ""
        val cal = java.util.Calendar.getInstance()
        cal.timeInMillis = ts
        val h = cal.get(java.util.Calendar.HOUR_OF_DAY)
        val m = cal.get(java.util.Calendar.MINUTE)
        return String.format("%02d:%02d", h, m)
    }
}
