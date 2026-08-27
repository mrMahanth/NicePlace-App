import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'inquiry_detail_screen.dart';

class InquiriesListScreen extends StatefulWidget {
  const InquiriesListScreen({super.key});

  @override
  State<InquiriesListScreen> createState() => _InquiriesListScreenState();
}

class _InquiriesListScreenState extends State<InquiriesListScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<Inquiry> inquiries = [];

  @override
  void initState() {
    super.initState();
    loadInquiries();
  }

  Future<void> loadInquiries() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await InquiryService.fetchInquiries();

    if (result['success']) {
      setState(() {
        inquiries = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Inquiries load nahi ho payi. Dobara try karo.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inquiries')),
      body: RefreshIndicator(
        onRefresh: loadInquiries,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (inquiries.isEmpty) {
      return ListView(
        // ListView taaki pull-to-refresh empty state par bhi kaam kare
        children: const [
          SizedBox(height: 100),
          Center(child: Text('Abhi tak koi inquiry nahi hai.')),
        ],
      );
    }

    return ListView.separated(
      itemCount: inquiries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        final lastMessage = inquiry.messages.isNotEmpty
            ? inquiry.messages.last.message
            : inquiry.initialMessage;

        return ListTile(
          title: Text(inquiry.propertyTitle),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Chip(
            label: Text(inquiry.status),
            backgroundColor: _statusColor(inquiry.status),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InquiryDetailScreen(inquiryId: inquiry.id),
              ),
            );
            // Wapas aane par list refresh kar do (naya message ho sakta hai)
            loadInquiries();
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange.shade100;
      case 'responded':
        return Colors.green.shade100;
      case 'closed':
        return Colors.grey.shade300;
      default:
        return Colors.blue.shade50;
    }
  }
}