import 'package:flutter/material.dart';
import '../models/rental_agreement_model.dart';
import '../services/tenancy_service.dart';

class RentTrackingScreen extends StatefulWidget {
  final int propertyId;
  final String propertyTitle;
  final double? defaultRentAmount;

  const RentTrackingScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    this.defaultRentAmount,
  });

  @override
  State<RentTrackingScreen> createState() => _RentTrackingScreenState();
}

class _RentTrackingScreenState extends State<RentTrackingScreen> {
  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  RentalAgreement? _agreement;
  List<RentalAgreement> _history = [];
  bool _isLoading = true;
  bool _isEndingTenancy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TenancyService.fetchCurrentAgreement(widget.propertyId);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _agreement = result['data'] as RentalAgreement);
    } else {
      setState(() => _error = result['error']?.toString() ?? "Could not load tenancy info.");
    }

    final historyResult = await TenancyService.fetchPropertyHistory(widget.propertyId);
    if (mounted && historyResult['success'] == true) {
      final all = historyResult['data'] as List<RentalAgreement>;
      setState(() => _history = all.where((a) => !a.isActive).toList());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Agreement start date se lekar aaj tak, har mahine ki list banata hai (latest pehle)
  List<Map<String, int>> _buildMonthList(String startDateStr) {
    DateTime start;
    try {
      start = DateTime.parse(startDateStr);
    } catch (e) {
      start = DateTime.now();
    }
    final now = DateTime.now();
    final months = <Map<String, int>>[];
    int y = start.year, m = start.month;
    while (y < now.year || (y == now.year && m <= now.month)) {
      months.add({'month': m, 'year': y});
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return months.reversed.toList();
  }

  RentPayment? _paymentFor(int month, int year) {
    final matches = _agreement!.payments.where((p) => p.month == month && p.year == year);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _openMarkPaidDialog(int month, int year) async {
    final amountController = TextEditingController(
      text: widget.defaultRentAmount != null ? widget.defaultRentAmount!.toStringAsFixed(0) : '',
    );
    final remarksController = TextEditingController();
    String paymentMode = 'cash';
    bool isSaving = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Mark Paid — ${_monthNames[month]} $year"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(dialogError!, style: const TextStyle(color: Colors.red)),
                      ),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      decoration: const InputDecoration(labelText: "Payment Mode", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'online', child: Text('Online')),
                      ],
                      onChanged: (v) => setDialogState(() => paymentMode = v ?? 'cash'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(labelText: "Remarks (optional)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text.trim());
                          if (amount == null || amount <= 0) {
                            setDialogState(() => dialogError = "Please enter a valid amount.");
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });
                          final result = await TenancyService.markPayment(
                            agreementId: _agreement!.id,
                            month: month,
                            year: year,
                            amount: amount,
                            paymentMode: paymentMode,
                            remarks: remarksController.text.trim(),
                          );
                          if (result['success'] == true) {
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            await _load();
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              dialogError = result['error']?.toString() ?? "Could not save.";
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmEndTenancy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("End Tenancy"),
        content: const Text(
          "This will end the current tenancy and make the property available (Live) again. Continue?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("End Tenancy")),
        ],
      ),
    );
    if (confirmed != true || _agreement == null) return;

    setState(() => _isEndingTenancy = true);
    final result = await TenancyService.endTenancy(_agreement!.id);
    if (!mounted) return;
    setState(() => _isEndingTenancy = false);

    if (result['success'] == true) {
      Navigator.pop(context, true); // My Properties ko batata hai refresh karne ke liye
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? "Could not end tenancy.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rent Tracking — ${widget.propertyTitle}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text("Try Again")),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    _agreement!.renterName.isNotEmpty
                                        ? _agreement!.renterName
                                        : "Renter",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (_agreement!.isPhoneVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.verified, size: 16, color: Colors.blue),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(_agreement!.renterPhone, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.logout),
                                  label: _isEndingTenancy
                                      ? const SizedBox(
                                          width: 16, height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text("End Tenancy"),
                                  onPressed: _isEndingTenancy ? null : _confirmEndTenancy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Monthly Payments",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._buildMonthList(_agreement!.startDate).map((m) {
                        final payment = _paymentFor(m['month']!, m['year']!);
                        final isPaid = payment?.status == 'paid';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text("${_monthNames[m['month']!]} ${m['year']}"),
                            subtitle: isPaid
                                ? Text(
                                    "Paid — ₹${payment!.amount.toStringAsFixed(0)} (${payment.paymentMode})"
                                    "${payment.remarks.isNotEmpty ? ' • ${payment.remarks}' : ''}",
                                  )
                                : const Text("Pending", style: TextStyle(color: Colors.orange)),
                            trailing: isPaid
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : TextButton(
                                    onPressed: () => _openMarkPaidDialog(m['month']!, m['year']!),
                                    child: const Text("Mark Paid"),
                                  ),
                          ),
                        );
                      }),
                      if (_history.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text("Past Renters",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._history.map((a) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(a.renterName.isNotEmpty ? a.renterName : a.renterPhone),
                                subtitle: Text("Started: ${a.startDate}"),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}