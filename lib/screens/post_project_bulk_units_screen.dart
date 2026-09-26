import 'package:flutter/material.dart';
import '../models/unit_draft_model.dart';
import '../models/attribute_definition_model.dart';
import '../services/project_service.dart';
import '../services/property_service.dart';
import '../services/property_type_service.dart';
import 'post_project_unit_edit_screen.dart';
import 'post_project_media_screen.dart';

class PostProjectBulkUnitsScreen extends StatefulWidget {
  final int projectId;

  const PostProjectBulkUnitsScreen({super.key, required this.projectId});

  @override
  State<PostProjectBulkUnitsScreen> createState() => _PostProjectBulkUnitsScreenState();
}

class _PostProjectBulkUnitsScreenState extends State<PostProjectBulkUnitsScreen> {
  // ---------- Project info (listing type, starting price, property type) ----------
  bool _isLoadingProjectInfo = true;
  String? _projectInfoError;
  int? _propertyTypeId;
  String _projectListingType = 'rent';
  double? _startingPrice;
  Map<int, String> _commonAttributeValues = {};

  // ---------- Existing units ----------
  bool _isLoadingUnits = true;
  String? _unitsError;
  List<Map<String, dynamic>> _existingUnits = [];

  // ---------- Attributes (lazy - sirf jab Add/Edit/Duplicate ho tab load hote hain) ----------
  List<AttributeDefinitionModel>? _attributeDefinitions; // null = abhi tak load nahi hue
  bool _isLoadingAttributes = false;

  final List<UnitDraft> _draftUnits = [];

  bool _isChangingListingType = false;

  // ---------- Batch creation ----------
  bool _isCreatingUnits = false;
  String? _creationProgressText;

  @override
  void initState() {
    super.initState();
    _loadProjectInfo();
    _loadUnits();
  }

  Future<void> _loadProjectInfo() async {
    setState(() {
      _isLoadingProjectInfo = true;
      _projectInfoError = null;
    });
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      _propertyTypeId = project['property_type_pk'];
      _projectListingType = project['listing_type'] ?? 'rent';
      _startingPrice = _parseFlexibleDouble(project['starting_price']);

      final projectAttrValues = project['attribute_values'] as List<dynamic>? ?? [];
      final Map<int, String> commonValues = {};
      for (final av in projectAttrValues) {
        final value = av['value'];
        if (value != null && value.toString().isNotEmpty) {
          commonValues[av['attribute_definition']] = value.toString();
        }
      }

      setState(() {
        _commonAttributeValues = commonValues;
        _isLoadingProjectInfo = false;
      });
    } catch (e) {
      setState(() {
        _projectInfoError = "Could not load project info.";
        _isLoadingProjectInfo = false;
      });
    }
  }

  // DRF DecimalField ko JSON mein String bhejta hai (e.g. "1000.00"), number nahi -
  // ye helper dono format (String ya number) ko safely double mein badal deta hai.
  double? _parseFlexibleDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoadingUnits = true;
      _unitsError = null;
    });
    try {
      final units = await PropertyService.fetchUnitsForProject(widget.projectId);
      setState(() {
        _existingUnits = units;
        _isLoadingUnits = false;
      });
    } catch (e) {
      setState(() {
        _unitsError = "Could not load units.";
        _isLoadingUnits = false;
      });
    }
  }

  // Attributes sirf pehli baar Add/Edit/Duplicate pe load hote hain, phir cache ho jaate hain
  Future<List<AttributeDefinitionModel>?> _ensureAttributesLoaded() async {
    if (_attributeDefinitions != null) return _attributeDefinitions;
    if (_propertyTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project info not loaded yet. Please wait or retry above.")),
      );
      return null;
    }

    setState(() => _isLoadingAttributes = true);
    try {
      final allAttrs = await PropertyTypeService.fetchAttributeDefinitions(_propertyTypeId!);
      final filtered = allAttrs.where((a) {
        final applicable = a.applicableTo == 'all' || a.applicableTo == _projectListingType;
        return applicable && a.attributeType != 'file';
      }).toList();
      setState(() {
        _attributeDefinitions = filtered;
        _isLoadingAttributes = false;
      });
      return filtered;
    } catch (e) {
      setState(() => _isLoadingAttributes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not load amenities. Please try again.")),
        );
      }
      return null;
    }
  }

  List<int> get _checkboxAttributeIds =>
      (_attributeDefinitions ?? []).where((a) => a.attributeType == 'checkbox').map((a) => a.id).toList();

  Future<void> _showChangeListingTypeDialog() async {
    if (_draftUnits.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Change Listing Type"),
          content: const Text(
            "Changing the listing type will clear the new units listed below (not yet created). Continue?",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Continue")),
          ],
        ),
      );
      if (proceed != true) return;
    }

    String newListingType = _projectListingType;
    final priceController = TextEditingController(text: _startingPrice?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Project Listing Type"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: newListingType,
                    decoration: const InputDecoration(labelText: "Listing Type", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'rent', child: Text('Rent')),
                      DropdownMenuItem(value: 'sale', child: Text('Sale')),
                    ],
                    onChanged: (v) => setDialogState(() => newListingType = v ?? 'rent'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: newListingType == 'rent' ? "Starting Rent From" : "Starting Price From",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
                ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Save")),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    setState(() => _isChangingListingType = true);

    final result = await ProjectService.updateListingTypeAndPrice(
      projectId: widget.projectId,
      listingType: newListingType,
      startingPrice: double.tryParse(priceController.text.trim()),
      startingPriceUnit: newListingType == 'sale' ? 'per_sqft' : 'per_month',
    );

    setState(() => _isChangingListingType = false);

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        _draftUnits.clear();
        _attributeDefinitions = null; // listing type badla, attributes ka applicable-filter dobara chahiye
      });
      await _loadProjectInfo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update listing type. Please try again.")),
      );
    }
  }

  Future<void> _addNewUnit() async {
    final attrs = await _ensureAttributesLoaded();
    if (attrs == null || !mounted) return;

    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: UnitDraft(listingType: _projectListingType),
          attributeDefinitions: attrs,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits.add(result));
  }

  Future<void> _editDraftUnit(int index) async {
    final attrs = await _ensureAttributesLoaded();
    if (attrs == null || !mounted) return;

    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: _draftUnits[index],
          attributeDefinitions: attrs,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits[index] = result);
  }

  Future<void> _duplicateDraftUnit(int index) async {
    final attrs = await _ensureAttributesLoaded();
    if (attrs == null || !mounted) return;

    final duplicated = _draftUnits[index].duplicate();
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: duplicated,
          attributeDefinitions: attrs,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits.add(result));
  }

  void _deleteDraftUnit(int index) {
    setState(() => _draftUnits.removeAt(index));
  }

  Future<void> _duplicateExistingUnit(Map<String, dynamic> unit) async {
    final attrs = await _ensureAttributesLoaded();
    if (attrs == null || !mounted) return;

    final draft = UnitDraft.fromExistingUnitJson(unit, _checkboxAttributeIds);
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: draft,
          attributeDefinitions: attrs,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits.add(result));
  }

  Future<void> _deleteExistingUnit(Map<String, dynamic> unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Unit"),
        content: Text("Delete \"${unit['title']}\"? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await PropertyService.deleteProperty(unit['id']);
    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _existingUnits.removeWhere((u) => u['id'] == unit['id']));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete unit. Please try again.")),
      );
    }
  }

  // ---------- NAYA: Batch-wise creation (5-5 units) ----------
  Future<void> _createAllUnits() async {
    if (_draftUnits.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Add at least one unit first.")));
      return;
    }

    const batchSize = 5;
    setState(() {
      _isCreatingUnits = true;
      _creationProgressText = null;
    });

    final totalBatches = (_draftUnits.length / batchSize).ceil();
    int createdCount = 0;
    int batchNumber = 0;

    while (_draftUnits.isNotEmpty) {
      batchNumber++;
      final batch = _draftUnits.take(batchSize).toList();

      setState(() => _creationProgressText = "Creating batch $batchNumber of $totalBatches...");

      final unitsJson = batch.map((d) => d.toApiJson()).toList();
      final result = await ProjectService.bulkCreateUnits(projectId: widget.projectId, units: unitsJson);

      if (result["success"] == true) {
        setState(() {
          // Sirf successfully-created batch hi list se hataate hain
          _draftUnits.removeRange(0, batch.length);
        });
        createdCount += batch.length;
      } else {
        setState(() {
          _isCreatingUnits = false;
          _creationProgressText = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Batch $batchNumber failed: ${result["error"]}. "
              "$createdCount unit(s) were created before this. Remaining units are still in the list below — you can try again.",
            ),
          ),
        );
        await _loadUnits();
        return;
      }
    }

    setState(() {
      _isCreatingUnits = false;
      _creationProgressText = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$createdCount unit(s) created successfully.")),
    );
    await _loadUnits();
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectMediaScreen(projectId: widget.projectId),
      ),
    );
  }

  Widget _existingUnitCard(Map<String, dynamic> unit) {
    return Card(
      child: ListTile(
        title: Text(unit['title'] ?? ''),
        subtitle: Text(
          "Status: ${unit['status']}  •  ${unit['listing_type'] == 'rent' ? '₹${unit['rent_amount'] ?? unit['price']}' : '₹${unit['total_price'] ?? unit['price']}'}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: "Duplicate",
              onPressed: () => _duplicateExistingUnit(unit),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: "Delete",
              onPressed: () => _deleteExistingUnit(unit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftUnitCard(int index) {
    final draft = _draftUnits[index];
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        title: Text(draft.unitNumber.isEmpty ? "(Unnamed unit)" : "Unit ${draft.unitNumber}"),
        subtitle: Text("${draft.priceSummary()}  •  ${draft.status}  •  not yet created"),
        onTap: () => _editDraftUnit(index),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: "Duplicate",
              onPressed: () => _duplicateDraftUnit(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: "Delete",
              onPressed: () => _deleteDraftUnit(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectInfoHeader() {
    if (_isLoadingProjectInfo) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text("Loading project info..."),
          ],
        ),
      );
    }
    if (_projectInfoError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(child: Text(_projectInfoError!, style: const TextStyle(color: Colors.red))),
            TextButton(onPressed: _loadProjectInfo, child: const Text("Retry")),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Project Listing Type: ${_projectListingType == 'rent' ? 'Rent' : 'Sale'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _isChangingListingType
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: _showChangeListingTypeDialog, child: const Text("Change")),
        ],
      ),
    );
  }

  Widget _unitsSection() {
    if (_isLoadingUnits) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_unitsError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(child: Text(_unitsError!, style: const TextStyle(color: Colors.red))),
            TextButton(onPressed: _loadUnits, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_existingUnits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Existing Units", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._existingUnits.map(_existingUnitCard),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bulk Units")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _projectInfoHeader(),
          const SizedBox(height: 16),

          _unitsSection(),

          const Text("New Units", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            "Add units below, then tap \"Create All Units\" to save them all at once.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          if (_draftUnits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("No new units added yet.", style: TextStyle(color: Colors.black54)),
            )
          else
            for (int i = 0; i < _draftUnits.length; i++) _draftUnitCard(i),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isLoadingAttributes ? null : _addNewUnit,
            icon: _isLoadingAttributes
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
            label: Text(_isLoadingAttributes ? "Loading..." : "Add Unit"),
          ),

          const SizedBox(height: 16),
          if (_creationProgressText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_creationProgressText!, style: const TextStyle(color: Colors.black54)),
            ),
          ElevatedButton(
            onPressed: _isCreatingUnits ? null : _createAllUnits,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            child: _isCreatingUnits
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Create All Units"),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text("Continue to Project Media"),
          ),
        ],
      ),
    );
  }
}