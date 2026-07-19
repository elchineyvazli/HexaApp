import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.timestamp,
    this.text,
    this.stickerPath,
  });

  final String id;
  final String senderId;
  final String? text;
  final String? stickerPath;
  final DateTime timestamp;
}

class StickerItem {
  const StickerItem({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    required this.glowColor,
  });

  final String id;
  final String name;
  final String price;
  final String emoji;

  /// Mevcut satın alma modelini bozmamak için korunur.
  final Color glowColor;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.chatId, super.key});

  final String chatId;

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _messageFocusNode = FocusNode();

  final List<StickerItem> _storeStickers = const <StickerItem>[
    StickerItem(
      id: 'st_neon_crystal',
      name: 'Kristal',
      price: '4.99 \$',
      emoji: '💎',
      glowColor: HexaColors.purple,
    ),
    StickerItem(
      id: 'st_cyber_crown',
      name: 'Taç',
      price: '11.99 \$',
      emoji: '👑',
      glowColor: HexaColors.cyan,
    ),
    StickerItem(
      id: 'st_plasma_heart',
      name: 'Plazma Kalp',
      price: '29.99 \$',
      emoji: '❤️‍🔥',
      glowColor: HexaColors.purpleSoft,
    ),
  ];

  final List<MessageModel> _messages = <MessageModel>[
    MessageModel(
      id: 'm1',
      senderId: 'other',
      text:
          'Selam! Videomu beğenmene sevindim. Hexa fütürizmi hakkında ne düşünüyorsun?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    MessageModel(
      id: 'm2',
      senderId: 'me',
      text: 'Harika bir akış hızı var, mimariyi çok beğendim! ⚡',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        MessageModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: 'me',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  void _purchaseAndSendSticker(StickerItem sticker) {
    setState(() {
      _messages.add(
        MessageModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: 'me',
          stickerPath: sticker.emoji,
          timestamp: DateTime.now(),
        ),
      );
    });

    Navigator.of(context).pop();
  }

  void _showStickerStore() {
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: HexaColors.scrim,
      elevation: 0,
      builder: (sheetContext) {
        return _StickerStoreSheet(
          stickers: _storeStickers,
          onStickerPressed: _purchaseAndSendSticker,
          onClose: () {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HexaTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HexaColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: HexaColors.backgroundDark,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _ChatHeader(
                  chatId: widget.chatId,
                  onBackPressed: () {
                    context.pop();
                  },
                ),
                const _ChatDivider(),
                Expanded(child: _MessageList(messages: _messages)),
                _MessageComposer(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  onOpenStickers: _showStickerStore,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.chatId, required this.onBackPressed});

  final String chatId;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final normalizedChatId = chatId.trim().isEmpty
        ? 'hexa_user'
        : chatId.trim();

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Geri',
              onPressed: onBackPressed,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.90),
                minimumSize: const Size(42, 42),
                maximumSize: const Size(42, 42),
              ),
              icon: Icon(Icons.arrow_back_rounded, size: 22),
            ),
            const SizedBox(width: 5),
            _ChatAvatar(name: normalizedChatId),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    normalizedChatId.startsWith('@')
                        ? normalizedChatId
                        : '@$normalizedChatId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Özel mesaj',
                    style: TextStyle(
                      color: Color(0x66FFFFFF),
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.03,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cleanName = name.replaceFirst('@', '').trim();

    final letter = cleanName.isEmpty
        ? 'H'
        : cleanName.substring(0, 1).toUpperCase();

    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: HexaGradients.signal,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: HexaColors.backgroundDark,
          shape: BoxShape.circle,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: HexaColors.surfaceMutedDark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: HexaColors.purpleSoft,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatDivider extends StatelessWidget {
  const _ChatDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0x12FFFFFF));
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<MessageModel> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyConversation();
    }

    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];

        return _MessageItem(message: message);
      },
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.senderId == 'me';

    final sticker = message.stickerPath?.trim() ?? '';

    if (sticker.isNotEmpty) {
      return _StickerMessage(
        emoji: sticker,
        isMine: isMine,
        timestamp: message.timestamp,
      );
    }

    final text = message.text?.trim() ?? '';

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
          bottom: 8,
        ),
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 8),
        decoration: BoxDecoration(
          color: isMine ? HexaColors.purple : HexaColors.surfaceMutedDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 6),
            bottomRight: Radius.circular(isMine ? 6 : 20),
          ),
          border: isMine
              ? null
              : Border.all(color: Colors.white.withOpacity(0.055)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontSize: 14.5,
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.13,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(isMine ? 0.58 : 0.38),
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerMessage extends StatelessWidget {
  const _StickerMessage({
    required this.emoji,
    required this.isMine,
    required this.timestamp,
  });

  final String emoji;
  final bool isMine;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMine ? 54 : 0,
          right: isMine ? 0 : 54,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HexaColors.surfaceDark,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 45, height: 1),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatMessageTime(timestamp),
                style: const TextStyle(
                  color: Color(0x52FFFFFF),
                  fontSize: 9.5,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white.withOpacity(0.24),
              size: 31,
            ),
            const SizedBox(height: 14),
            const Text(
              'Henüz mesaj yok',
              style: TextStyle(
                color: Color(0xBFFFFFFF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sohbeti başlatmak için bir mesaj gönder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.onOpenStickers,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final VoidCallback onOpenStickers;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0F),
        border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final canSend = value.text.trim().isNotEmpty;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _ComposerIconButton(
                  tooltip: 'Sticker gönder',
                  icon: Icons.add_reaction_outlined,
                  onPressed: onOpenStickers,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 46,
                      maxHeight: 118,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: HexaColors.surfaceDark,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      cursorColor: HexaColors.purple,
                      cursorWidth: 1.6,
                      onSubmitted: (_) {
                        if (canSend) {
                          onSend();
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.10,
                      ),
                      decoration: const InputDecoration(
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Mesaj yaz...',
                        hintStyle: TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(enabled: canSend, onPressed: onSend),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.055),
          foregroundColor: Colors.white.withOpacity(0.68),
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Mesajı gönder',
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? HexaColors.purple
              : Colors.white.withOpacity(0.055),
          foregroundColor: enabled
              ? Colors.white
              : Colors.white.withOpacity(0.28),
          disabledBackgroundColor: Colors.white.withOpacity(0.055),
          disabledForegroundColor: Colors.white.withOpacity(0.28),
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
        ),
        icon: Icon(Icons.arrow_upward_rounded, size: 21),
      ),
    );
  }
}

class _StickerStoreSheet extends StatelessWidget {
  const _StickerStoreSheet({
    required this.stickers,
    required this.onStickerPressed,
    required this.onClose,
  });

  final List<StickerItem> stickers;
  final ValueChanged<StickerItem> onStickerPressed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final sheetHeight = (screenHeight * 0.46).clamp(350.0, 480.0).toDouble();

    return SizedBox(
      height: sheetHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HexaColors.surfaceOverlayDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 9),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 10, 13),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Stickerlar',
                              style: TextStyle(
                                color: Color(0xF2FFFFFF),
                                fontSize: 18,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.32,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Sohbete özel içerikler',
                              style: TextStyle(
                                color: Color(0x66FFFFFF),
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: onClose,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.60),
                          backgroundColor: Colors.white.withOpacity(0.055),
                        ),
                        icon: Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x12FFFFFF),
                ),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 17, 16, 22),
                    itemCount: stickers.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 10);
                    },
                    itemBuilder: (context, index) {
                      final item = stickers[index];

                      return _StickerStoreCard(
                        item: item,
                        onPressed: () {
                          onStickerPressed(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerStoreCard extends StatelessWidget {
  const _StickerStoreCard({required this.item, required this.onPressed});

  final StickerItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.name}, ${item.price}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 126,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HexaColors.surfaceDark,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.glowColor.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 36, height: 1),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.08,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.price,
                  style: TextStyle(
                    color: item.glowColor.withOpacity(0.88),
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMessageTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
