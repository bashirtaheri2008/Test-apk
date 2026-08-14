import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onStar;
  final VoidCallback? onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onLongPress,
    this.onForward,
    this.onDelete,
    this.onStar,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isDeleted) {
      return _buildDeletedBubble(theme, isDark);
    }

    final bubbleColor = isMe
      ? (isDark ? const Color(0xFF005c4b) : const Color(0xFFd9fdd3))
      : (isDark ? const Color(0xFF202c33) : Colors.white);
    final textColor = isDark ? const Color(0xFFe9edef) : const Color(0xFF111b21);
    final timeColor = isDark ? const Color(0xFF8696a0) : const Color(0xFF667781);

    return Padding(
      padding: EdgeInsets.only(left: isMe ? 60 : 4, right: isMe ? 4 : 60, top: 2, bottom: 2),
      child: Align(
        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.forwardedFrom.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shortcut, size: 14, color: timeColor),
                        const SizedBox(width: 4),
                        Text('فوروارد شده از ${message.forwardedFrom}', style: TextStyle(fontSize: 12, color: timeColor, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                if (message.replyToText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Alignment(isMe ? -1 : 1, 0).toString() == '0'
                        ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 3))
                        : Border(right: BorderSide(color: theme.colorScheme.primary, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.replyToName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 2),
                        Text(message.replyToText, style: TextStyle(fontSize: 13, color: timeColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                if (message.type == MessageType.image && message.mediaURL.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(message.mediaURL, width: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 200, height: 150, color: Colors.grey.shade300, child: const Icon(Icons.broken_image))),
                  ),
                if (message.type == MessageType.audio)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.play_arrow, color: textColor, size: 28),
                    const SizedBox(width: 4),
                    Container(width: 120, height: 3, decoration: BoxDecoration(color: timeColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(formatDuration(message.mediaDuration), style: TextStyle(fontSize: 12, color: timeColor)),
                  ]),
                if (message.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(message.text, style: TextStyle(fontSize: 15, color: textColor, height: 1.4)),
                  ),
                if (message.mediaCaption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(message.mediaCaption, style: TextStyle(fontSize: 14, color: textColor)),
                  ),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (message.isStarred)
                    const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, size: 13, color: Color(0xFFFFC107))),
                  Text(formatTime(message.timestamp), style: TextStyle(fontSize: 11, color: timeColor)),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(message.status == MessageStatus.read ? Icons.done_all
                      : message.status == MessageStatus.delivered ? Icons.done_all : Icons.check,
                      size: 14, color: message.status == MessageStatus.read ? const Color(0xFF53bdeb) : timeColor),
                  ],
                ]),
                if (message.reaction != MessageReaction.none)
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: timeColor.withOpacity(0.3))),
                      child: Text(getReactionEmoji(message.reaction), style: const TextStyle(fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedBubble(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(left: isMe ? 60 : 4, right: isMe ? 4 : 60, top: 2, bottom: 2),
      child: Align(
        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202c33) : const Color(0xFFf0f0f0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.block, size: 14, color: isDark ? const Color(0xFF8696a0) : Colors.grey),
            const SizedBox(width: 4),
            Text('این پیام حذف شد', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: isDark ? const Color(0xFF8696a0) : Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
