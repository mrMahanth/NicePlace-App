import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/property_service.dart';
import '../data/india_states_districts.dart';
import 'post_property_pricing_screen.dart';

class PostPropertyBasicDetailsScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyBasicDetailsScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyBasicDetailsScreen> createState() =>
      _PostPropertyBasicDetailsScreenState();
}

class _PostPropertyBasicDetailsScreenState
    extends State<PostPropertyBasicDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "India");
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final FocusNode _localityFocusNode = FocusNode();

  String? _selectedState;
  String? _selectedDistrict;

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
      // Best-effort convenience - chup-chaap fail hone dete hain
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

    // Keyboard pehle band karte hain, taaki layout resize scroll-position ko disturb na kare
    FocusScope.of(context).unfocus();

    setState(() => _locationConfirmed = true);

    // Keyboard-close animation aur naye layout ko settle hone ka time dete hain
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    final targetContext = _bottomSectionKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        alignment: 1.0, // viewport ke bottom tak laata hai
      );
    }
  }

  Future<void> _saveAndContinue() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title is required.")));
      return;
    }
    if (!_locationConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please confirm the location.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await PropertyService.updateBasicDetails(
      propertyId: widget.propertyId,
      title: _titleController.text.trim(),
      locality: _localityController.text.trim(),
      city: _cityController.text.trim(),
      district: _selectedDistrict ?? '',
      state: _selectedState ?? '',
      country: _countryController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _selectedPoint?.latitude,
      longitude: _selectedPoint?.longitude,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostPropertyPricingScreen(propertyId: widget.propertyId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save. Please try again.")),
      );
    }
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
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
      appBar: AppBar(title: const Text("Basic Details")),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                hintText: "e.g. 2BHK Flat near Boring Road",
                border: OutlineInputBorder(),
              ),
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
                hintText: "e.g. Flat No 4B, XYZ Apartment, Boring Road",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Ye poora section (confirmed-status + button) key se wrapped hai
            // taaki confirm karne ke baad exactly yahan tak scroll ho sake
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