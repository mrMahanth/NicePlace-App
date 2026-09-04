import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLookingUpPincode = false;
  String? _errorMessage;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _localityController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressLineController.dispose();
    _pincodeController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await UserProfileService.fetchMyProfile();

    if (result['success']) {
      final UserProfileModel profile = result['data'];
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _emailController.text = profile.email;
      _addressLineController.text = profile.addressLine;
      _pincodeController.text = profile.pincode;
      _localityController.text = profile.locality;
      _cityController.text = profile.city;
      _districtController.text = profile.district;
      _stateController.text = profile.state;
      _countryController.text = profile.country.isEmpty ? 'India' : profile.country;
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _errorMessage = "Could not load profile.";
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePincodeLookup() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) return;

    setState(() => _isLookingUpPincode = true);

    final result = await UserProfileService.lookupPincode(pincode);

    setState(() => _isLookingUpPincode = false);

    if (result != null) {
      setState(() {
        _cityController.text = result['city'] ?? '';
        _districtController.text = result['district'] ?? '';
        _stateController.text = result['state'] ?? '';
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not find details for this PIN code.")),
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await UserProfileService.updateMyProfile({
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "address_line": _addressLineController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "locality": _localityController.text.trim(),
      "city": _cityController.text.trim(),
      "district": _districtController.text.trim(),
      "state": _stateController.text.trim(),
      "country": _countryController.text.trim(),
    });

    setState(() => _isSaving = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _errorMessage = "Could not save profile. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Personal Details",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                        labelText: "First Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                        labelText: "Last Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: "Email", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),

                  const Text("Address",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressLineController,
                    decoration: const InputDecoration(
                        labelText: "House No. / Street",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "PIN Code",
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLookingUpPincode
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (value.length == 6) _handlePincodeLookup();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _localityController,
                    decoration: const InputDecoration(
                        labelText: "Locality / Area",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                        labelText: "City", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                        labelText: "District", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                        labelText: "State", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                        labelText: "Country", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),

                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text("Save Profile"),
                        ),
                ],
              ),
            ),
    );
  }
}