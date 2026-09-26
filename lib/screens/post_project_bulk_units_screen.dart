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
  bool _isLoading = true;
  String? _loadError;

  int? _propertyTypeId;
  String _projectListingType = 'rent';
  double? _startingPrice;
  List<AttributeDefinitionModel> _attributeDefinitions = [];
  Map<int, String> _commonAttributeValues = {}; // attrId -> display value
  List<Map<String, dynamic>> _existingUnits = [];
  final List<UnitDraft> _draftUnits = [];

  bool _isCreatingUnits = false;
  bool _isChangingListingType = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      _propertyTypeId = project['property_type_pk'];
      _projectListingType = project['listing_type'] ?? 'rent';
      _startingPrice = (project['starting_price'] as num?)?.toDouble();

      final allAttrs = await PropertyTypeService.fetchAttributeDefinitions(_propertyTypeId!);
      final filteredAttrs = allAttrs.where((a) {
        final applicable = a.applicableTo == 'all' || a.applicableTo == _projectListingType;
        return applicable && a.attributeType != 'file';
      }).toList();

      // Project-level Common Amenities values (jo already set hain)
      final projectAttrValues = project['attribute_values'] as List<dynamic>? ?? [];
      final Map<int, String> commonValues = {};
      for (final av in projectAttrValues) {
        final value = av['value'];
        if (value != null && value.toString().isNotEmpty) {
          commonValues[av['attribute_definition']] = value.toString();
        }
      }

      final units = await PropertyService.fetchUnitsForProject(widget.projectId);

      setState(() {
        _attributeDefinitions = filteredAttrs;
        _commonAttributeValues = commonValues;
        _existingUnits = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load units. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  List<int> get _checkboxAttributeIds =>
      _attributeDefinitions.where((a) => a.attributeType == 'checkbox').map((a) => a.id).toList();

  // ---------- Point 1: Listing Type change popup (koi navigation nahi) ----------
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
      setState(() => _draftUnits.clear());
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update listing type. Please try again.")),
      );
    }
  }

  Future<void> _addNewUnit() async {
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: UnitDraft(listingType: _projectListingType),
          attributeDefinitions: _attributeDefinitions,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits.add(result));
  }

  Future<void> _editDraftUnit(int index) async {
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: _draftUnits[index],
          attributeDefinitions: _attributeDefinitions,
          fixedListingType: _projectListingType,
          commonAttributeValues: _commonAttributeValues,
        ),
      ),
    );
    if (result != null) setState(() => _draftUnits[index] = result);
  }

  // ---------- Point 4: Duplicate ab turant Edit screen kholta hai naam poochne ke liye ----------
  Future<void> _duplicateDraftUnit(int index) async {
    final duplicated = _draftUnits[index].duplicate();
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: duplicated,
          attributeDefinitions: _attributeDefinitions,
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
    final draft = UnitDraft.fromExistingUnitJson(unit, _checkboxAttributeIds);
    final result = await Navigator.push<UnitDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitEditScreen(
          initialDraft: draft,
          attributeDefinitions: _attributeDefinitions,
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

  Future<void> _createAllUnits() async {
    if (_draftUnits.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Add at least one unit first.")));
      return;
    }

    setState(() => _isCreatingUnits = true);

    final unitsJson = _draftUnits.map((d) => d.toApiJson()).toList();
    final result = await ProjectService.bulkCreateUnits(projectId: widget.projectId, units: unitsJson);

    setState(() => _isCreatingUnits = false);

    if (!mounted) return;

    if (result["success"] == true) {
      final message = result["data"]["message"] ?? "Units created.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _draftUnits.clear());
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["error"].toString())),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bulk Units")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ---------- Project Listing Type header ----------
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Project Listing Type: ${_projectListingType == 'rent' ? 'Rent' : 'Sale'}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _isChangingListingType
                              ? const SizedBox(
                                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : TextButton(
                                  onPressed: _showChangeListingTypeDialog,
                                  child: const Text("Change"),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_existingUnits.isNotEmpty) ...[
                      const Text("Existing Units", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._existingUnits.map(_existingUnitCard),
                      const SizedBox(height: 20),
                    ],

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
                      onPressed: _addNewUnit,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Unit"),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isCreatingUnits ? null : _createAllUnits,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                      child: _isCreatingUnits
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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