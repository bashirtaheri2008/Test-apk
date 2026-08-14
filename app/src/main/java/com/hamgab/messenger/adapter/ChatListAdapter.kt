package com.hamgab.messenger.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.hamgab.messenger.data.ChatItem
import com.hamgab.messenger.databinding.ItemChatListBinding

class ChatListAdapter(
    private val items: MutableList<ChatItem>,
    private val onClick: (ChatItem) -> Unit
) : RecyclerView.Adapter<ChatListAdapter.VH>() {

    private var filteredItems: List<ChatItem> = items.toList()

    fun update(newItems: List<ChatItem>) {
        items.clear()
        items.addAll(newItems)
        filteredItems = items.toList()
        notifyDataSetChanged()
    }

    fun filter(query: String) {
        filteredItems = if (query.isEmpty()) {
            items.toList()
        } else {
            items.filter { it.partnerName.contains(query, ignoreCase = true) }
        }
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemChatListBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        holder.bind(filteredItems[position])
    }

    override fun getItemCount() = filteredItems.size

    inner class VH(val binding: ItemChatListBinding) : RecyclerView.ViewHolder(binding.root) {
        init {
            binding.root.setOnClickListener {
                val pos = adapterPosition
                if (pos != RecyclerView.NO_POSITION) onClick(filteredItems[pos])
            }
        }

        fun bind(item: ChatItem) {
            binding.name.text = item.partnerName.ifEmpty { item.partnerId }
            binding.lastMessage.text = item.lastMessage.ifEmpty { "شروع گفتگو…" }
            binding.time.text = formatTime(item.lastTimestamp)

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
            val now = java.util.Calendar.getInstance()
            val isToday = cal.get(java.util.Calendar.YEAR) == now.get(java.util.Calendar.YEAR) &&
                    cal.get(java.util.Calendar.DAY_OF_YEAR) == now.get(java.util.Calendar.DAY_OF_YEAR)

            val h = cal.get(java.util.Calendar.HOUR_OF_DAY)
            val m = cal.get(java.util.Calendar.MINUTE)

            return if (isToday) {
                String.format("%02d:%02d", h, m)
            } else {
                val dayDiff = now.get(java.util.Calendar.DAY_OF_YEAR) - cal.get(java.util.Calendar.DAY_OF_YEAR)
                if (dayDiff == 1) "دیروز" else String.format("%02d:%02d", h, m)
            }
        }
    }
}
