package com.hamgab.messenger.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.hamgab.messenger.data.ChatItem
import com.hamgab.messenger.databinding.ItemChatListBinding
import com.bumptech.glide.Glide

class ChatListAdapter(
    private val items: MutableList<ChatItem>,
    private val onClick: (ChatItem) -> Unit
) : RecyclerView.Adapter<ChatListAdapter.VH>() {

    fun update(newItems: List<ChatItem>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemChatListBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = items[position]
        holder.bind(item)
    }

    override fun getItemCount() = items.size

    inner class VH(val binding: ItemChatListBinding) : RecyclerView.ViewHolder(binding.root) {
        init {
            binding.root.setOnClickListener {
                val pos = adapterPosition
                if (pos != RecyclerView.NO_POSITION) onClick(items[pos])
            }
        }

        fun bind(item: ChatItem) {
            binding.name.text = item.partnerName.ifEmpty { item.partnerId }
            binding.lastMessage.text = item.lastMessage.ifEmpty { "شروع گفتگو…" }

            val timeStr = formatTime(item.lastTimestamp)
            binding.time.text = timeStr

            if (item.partnerPhoto.isNotEmpty()) {
                Glide.with(binding.root).load(item.partnerPhoto).circleCrop().into(binding.avatar)
            }

            if (item.unreadCount > 0) {
                binding.unreadBadge.visibility = android.view.View.VISIBLE
                binding.unreadBadge.text = item.unreadCount.toString()
            } else {
                binding.unreadBadge.visibility = android.view.View.GONE
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
}
