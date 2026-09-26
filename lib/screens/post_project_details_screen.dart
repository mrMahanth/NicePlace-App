import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/project_service.dart';
import '../services/property_type_service.dart';
import '../data/india_states_districts.dart';
import 'post_project_amenities_screen.dart';

class PostProjectDetailsScreen extends StatefulWidget {
  final int projectId;

  const PostProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<PostProjectDetailsScreen> createState() => _PostProjectDetailsScreenState();
}

class _PostProjectDetailsScreenState extends State<PostProjectDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _builderController = TextEditingController();
  final TextEditingController _totalUnitsController = TextEditingController();
  final TextEditingController _startingPriceController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "India");
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final FocusNode _localityFocusNode = FocusNode();

  String? _selectedState;
  String? _selectedDistrict;
  String _listingType = 'rent';
  String _startingPriceUnit = 'per_month';

  static const List<Map<String, String>> _rentUnitOptions = [
    {'value': 'per_day', 'label': 'Per Day'},
    {'value': 'per_month', 'label': 'Per Month'},
    {'value': 'per_year', 'label': 'Per Year'},
  ];

  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bottomSectionKey = GlobalKey();

  static const LatLng _patnaCenter = LatLng(25.5941, 85.1376);

  LatLng? _selectedPoint;
  String? _detectedAddress;

  List<LocationResult> _searchResults = [];

  bool _isSearching = false;
  bool _isFetchingLocation = false;
  bool _isLookingUpPincode = false;
  bool _locationConfirmed = false;
  bool _isSaving = false;
  bool _showStateDistrictMismatchNote = false;

  @override
  void initState() {
    super.initState();
    _localityFocusNode.addListener(_onLocalityFocusChanged);
    _loadDefaultStartingPriceUnit();
  }

  // Project banate waqt property_type already set ho chuka hai (draft create ke time) -
  // uska is_bookable/naam check karke Starting Price ka smart default unit set karte hain.
  Future<void> _loadDefaultStartingPriceUnit() async {
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      final propertyTypeId = project['property_type_pk'];
      if (propertyTypeId == null) return;

      final types = await PropertyTypeService.fetchPropertyTypes();
      final matchingType = types.where((t) => t.id == propertyTypeId).toList();
      if (matchingType.isEmpty) return;

      final isBookable = matchingType.first.isBookable;
      final typeName = matchingType.first.name.toLowerCase();

      String computedDefault;
      if (isBookable) {
        computedDefault = 'per_day';
      } else if (typeName.contains('plot')) {
        computedDefault = 'per_year';
      } else {
        computedDefault = 'per_month';
      }

      if (mounted) setState(() => _startingPriceUnit = computedDefault);
    } catch (e) {
      // best-effort - default 'per_month' hi rahega agar ye fail ho jaye
    }
  }

  void _onLocalityFocusChanged() {
    if (!_localityFocusNode.hasFocus) {
      _autoFetchPincodeIfNeeded();
    }
  }

  Future<void> _autoFetchPincodeIfNeeded() async {
    if (_pincodeController.text.trim().isNotEmpty) return;
    if (_selectedState == null || _selectedDistrict == null) return;
    if (_cityController.text.trim().isEmpty || _localityController.text.trim().isEmpty) return;
    if (_locationConfirmed) return;

    final query =
        "${_localityController.text.trim()}, ${_cityController.text.trim()}, $_selectedDistrict, $_selectedState, India";

    try {
      final results = await LocationService.searchAddress(query);
      if (results.isNotEmpty && results.first.pincode.isNotEmpty) {
        setState(() {
          _pincodeController.text = results.first.pincode;
          _selectedPoint ??= LatLng(results.first.latitude, results.first.longitude);
        });
      }
    } catch (e) {
      // best-effort
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _builderController.dispose();
    _totalUnitsController.dispose();
    _startingPriceController.dispose();
    _searchController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    _scrollController.dispose();
    _localityFocusNode.dispose();
    super.dispose();
  }

  String? _matchState(String rawState) {
    final normalized = rawState.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final key in indiaStatesList) {
      if (key.toLowerCase() == normalized) return key;
    }
    return null;
  }

  String? _matchDistrict(String state, String rawDistrict) {
    final normalized = rawDistrict.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final districts = indiaStatesDistricts[state];
    if (districts == null) return null;
    for (final d in districts) {
      if (d.toLowerCase() == normalized) return d;
    }
    return null;
  }

  void _applyLocationResult(LocationResult result, {LatLng? point}) {
    final matchedState = _matchState(result.state);
    final matchedDistrict =
        matchedState != null ? _matchDistrict(matchedState, result.district) : null;

    setState(() {
      if (point != null) _selectedPoint = point;
      _detectedAddress = result.displayAddress;
      _countryController.text = result.country;
      _cityController.text = result.city;
      if (result.pincode.isNotEmpty) {
        _pincodeController.text = result.pincode;
      }
      _selectedState = matchedState;
      _selectedDistrict = matchedDistrict;
      _showStateDistrictMismatchNote = matchedState == null || matchedDistrict == null;
      _locationConfirmed = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      final result = await LocationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      final point = LatLng(position.latitude, position.longitude);
      _applyLocationResult(result, point: point);
      _mapController.move(point, 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await LocationService.searchAddress(query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Search failed. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(LocationResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _searchResults = [];
      _searchController.text = result.displayAddress;
    });
    _applyLocationResult(result, point: point);
    _mapController.move(point, 16);
  }

  Future<void> _onMapTapped(LatLng point) async {
    if (_locationConfirmed) return;
    setState(() => _isFetchingLocation = true);
    try {
      final result = await LocationService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      _applyLocationResult(result, point: point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not fetch address. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _onPincodeChanged(String value) async {
    if (value.length != 6) return;

    setState(() => _isLookingUpPincode = true);
    try {
      final result = await LocationService.lookupPincode(value);
      final matchedState = _matchState(result.state);
      final matchedDistrict =
          matchedState != null ? _matchDistrict(matchedState, result.district) : null;
      setState(() {
        _selectedState = matchedState;
        _selectedDistrict = matchedDistrict;
        _cityController.text = result.city;
        _countryController.text = result.country;
        _showStateDistrictMismatchNote = matchedState == null || matchedDistrict == null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLookingUpPincode = false);
    }
  }

  Future<void> _confirmLocation() async {
    if (_selectedState == null || _selectedDistrict == null || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("State, District and City are required.")),
      );
      return;
    }
    if (_localityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Locality / Complete Address is required.")),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _locationConfirmed = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    final targetContext = _bottomSectionKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        alignment: 1.0,
      );
    }
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Project Name is required.")));
      return;
    }
    if (!_locationConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please confirm the location.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final detailsResult = await ProjectService.updateProjectDetails(
      projectId: widget.projectId,
      name: _nameController.text.trim(),
      builderName: _builderController.text.trim(),
      locality: _localityController.text.trim(),
      city: _cityController.text.trim(),
      district: _selectedDistrict ?? '',
      state: _selectedState ?? '',
      country: _countryController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _selectedPoint?.latitude,
      longitude: _selectedPoint?.longitude,
      totalUnits: int.tryParse(_totalUnitsController.text.trim()),
      listingType: _listingType,
      startingPrice: double.tryParse(_startingPriceController.text.trim()),
      startingPriceUnit: _listingType == 'rent' ? _startingPriceUnit : 'per_sqft',
    );

    if (detailsResult["success"] != true) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save details. Please try again.")),
      );
      return;
    }

    final finalizeResult = await ProjectService.finalizeDetails(widget.projectId);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (finalizeResult["success"] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostProjectAmenitiesScreen(projectId: widget.projectId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(finalizeResult["error"]?.toString() ?? "Could not finalize details.")),
      );
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districtOptions =
        _selectedState != null ? (indiaStatesDistricts[_selectedState] ?? []) : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text("Project Details")),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Project Name",
                hintText: "e.g. Green Valley Apartments",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _builderController,
              decoration: const InputDecoration(
                labelText: "Builder Name (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text("Listing Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              "This applies to the whole project. All units will follow this.",
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _listingType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'rent', child: Text('Rent')),
                DropdownMenuItem(value: 'sale', child: Text('Sale')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _listingType = value);
              },
            ),
            const SizedBox(height: 10),

            _buildField("Total Units (optional)", _totalUnitsController,
                keyboardType: TextInputType.number),

            // ---------- Starting Price + unit ----------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: _listingType == 'rent' ? 3 : 1,
                  child: TextField(
                    controller: _startingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _listingType == 'rent'
                          ? "Starting Rent From (optional)"
                          : "Starting Price From (optional)",
                      suffixText: _listingType == 'sale' ? "/Sq.Ft." : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_listingType == 'rent') ...[
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _startingPriceUnit,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: _rentUnitOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt['value'],
                                child: Text(opt['label']!, style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _startingPriceUnit = value);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "This is a display-only reference (e.g. \"Starting from ₹X\"). Actual pricing is set per unit.",
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),

            const SizedBox(height: 16),
            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              "Enter Pincode or set location on the map. Locality must be entered manually.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _pincodeController,
              enabled: !_locationConfirmed,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onPincodeChanged,
              decoration: InputDecoration(
                labelText: "Pincode",
                border: const OutlineInputBorder(),
                suffixIcon: _isLookingUpPincode
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),

            _buildField("Country", _countryController, enabled: !_locationConfirmed),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  labelText: "State",
                  border: OutlineInputBorder(),
                ),
                items: indiaStatesList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: _locationConfirmed
                    ? null
                    : (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedDistrict = null;
                          _showStateDistrictMismatchNote = false;
                        });
                      },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: _selectedState == null ? "District (select State first)" : "District",
                  border: const OutlineInputBorder(),
                ),
                items: districtOptions
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (_selectedState == null || _locationConfirmed)
                    ? null
                    : (value) => setState(() => _selectedDistrict = value),
              ),
            ),

            if (_showStateDistrictMismatchNote)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Could not auto-match State/District exactly — please select them manually above.",
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),

            _buildField("City", _cityController, enabled: !_locationConfirmed),

            const SizedBox(height: 4),
            const Text("Or set location using the map:", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: !_locationConfirmed,
                    decoration: const InputDecoration(
                      hintText: "Search address...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _locationConfirmed ? null : _runSearch,
                  icon: _isSearching
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: _searchResults.map((r) {
                    return ListTile(
                      title: Text(r.displayAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectSearchResult(r),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _locationConfirmed || _isFetchingLocation ? null : _useCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: const Text("Use Current Location"),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint ?? _patnaCenter,
                  initialZoom: 13,
                  onTap: (tapPosition, point) => _onMapTapped(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.niceplace.niceplace_app',
                  ),
                  if (_selectedPoint != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _selectedPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ]),
                ],
              ),
            ),
            if (_detectedAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Detected: $_detectedAddress",
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _localityController,
              focusNode: _localityFocusNode,
              enabled: !_locationConfirmed,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Locality / Complete Address",
                hintText: "e.g. Near Boring Road Chauraha",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              key: _bottomSectionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_locationConfirmed)
                    ElevatedButton(
                      onPressed: _confirmLocation,
                      child: const Text("Confirm Location"),
                    )
                  else
                    Row(
                      children: [
                        const Expanded(
                          child: Text("✅ Location Confirmed", style: TextStyle(color: Colors.green)),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _locationConfirmed = false),
                          child: const Text("Edit"),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Save & Continue"),
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