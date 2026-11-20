import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/api_service.dart';
import '../utils/auto_refresh.dart';

class InquiryDetailScreen extends StatefulWidget {
  final int inquiryId;

  const InquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  bool isLoading = true;
  bool isSending = false;
  String errorMessage = '';
  Inquiry? inquiry;
  int? currentUserId;

  final TextEditingController messageController = TextEditingController();

  late final AutoRefresher _auto;

  @override
  void initState() {
    super.initState();
    _auto = AutoRefresher(onRefresh: _silentLoad, seconds: 5);
    loadDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auto.start(context);
  }

  @override
  void dispose() {
    _auto.dispose();
    messageController.dispose();
    super.dispose();
  }

  // Chat refresh: messageController ko haath nahi lagate, isliye typed text safe rehta hai
  Future<void> _silentLoad() async {
    currentUserId ??= await ApiService.getCurrentUserId();
    final result = await InquiryService.fetchInquiryDetail(widget.inquiryId);
    if (!mounted) return;
    if (result['success']) {
      setState(() {
        inquiry = result['data'];
        errorMessage = '';
        isLoading = false;
      });
    }
  }

  Future<void> loadDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    currentUserId = await ApiService.getCurrentUserId();
    // NOTE: currentUserId nikalne ka tarika tumhare api_service ke hisaab se
    // adjust karna pad sakta hai - agla step isko sahi karega
    final result = await InquiryService.fetchInquiryDetail(widget.inquiryId);

    if (result['success']) {
      setState(() {
        inquiry = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Detail load nahi ho payi. Dobara try karo.';
        isLoading = false;
      });
    }
  }

  Future<void> handleSend() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    final result = await InquiryService.sendMessage(
      inquiryId: widget.inquiryId,
      message: text,
    );

    setState(() => isSending = false);

    if (result['success']) {
      messageController.clear();
      _silentLoad(); // spinner ke bina naya message dikhao
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message bhejne mein error. Login check karo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inquiry?.propertyTitle ?? 'Inquiry'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    _buildInputBox(),
                  ],
                ),
    );
  }

  Widget _buildMessageList() {
    final inq = inquiry!;

    // initial_message ko bhi ek "message" ki tarah upar dikhayenge,
    // fir uske baad saari ChatMessage replies
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildBubble(
          text: inq.initialMessage,
          senderName: inq.buyerName,
          isMe: inq.buyer == currentUserId,
        ),
        const SizedBox(height: 8),
        ...inq.messages.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildBubble(
                text: m.message,
                senderName: m.senderName,
                isMe: m.sender == currentUserId,
              ),
            )),
      ],
    );
  }

  Widget _buildBubble({
    required String text,
    required String senderName,
    required bool isMe,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Reply likho...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          isSending
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: handleSend,
                ),
        ],
      ),
    );
  }
}