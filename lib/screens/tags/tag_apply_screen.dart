import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';

class TagApplyScreen extends StatefulWidget {
  final Tag tag;

  const TagApplyScreen({super.key, required this.tag});

  @override
  State<TagApplyScreen> createState() => _TagApplyScreenState();
}

class _TagApplyScreenState extends State<TagApplyScreen> {
  // Holds the current answer for each requirement ID.
  // Value is a String for text-based fields, or a File for file uploads.
  final Map<int, dynamic> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final req in widget.tag.requirements) {
      if (!req.requiresFile) {
        _textControllers[req.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

Future<void> _pickFile(int requirementId) async {
  final PlatformFile? file = await FilePicker.pickFile();
  if (file != null && file.path != null) {
    setState(() {
      _answers[requirementId] = File(file.path!);
    });
  }
}

  Future<void> _handleSubmit() async {
    // Validate required fields
    final missing = <String>[];
    for (final req in widget.tag.requirements) {
      if (!req.isRequired) continue;
      if (req.requiresFile) {
        if (_answers[req.id] == null) missing.add(req.label);
      } else {
        final text = _textControllers[req.id]?.text.trim() ?? '';
        if (text.isEmpty) missing.add(req.label);
      }
    }

    if (missing.isNotEmpty) {
      setState(() => _errorMessage = "Please fill: ${missing.join(', ')}");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Build final answers map from text controllers + file selections
    final finalAnswers = <int, dynamic>{};
    for (final req in widget.tag.requirements) {
      if (req.requiresFile) {
        if (_answers[req.id] != null) finalAnswers[req.id] = _answers[req.id];
      } else {
        final text = _textControllers[req.id]?.text.trim() ?? '';
        if (text.isNotEmpty) finalAnswers[req.id] = text;
      }
    }

    final result = await TagService.submitTagRequest(
      tagId: widget.tag.id,
      answers: finalAnswers,
    );

    setState(() => _isSubmitting = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted! You'll be notified once it's reviewed.")),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  Widget _buildRequirementField(TagRequirement req) {
    switch (req.requirementType) {
      case 'textarea':
        return TextField(
          controller: _textControllers[req.id],
          maxLines: 3,
          decoration: InputDecoration(
            labelText: req.isRequired ? "${req.label} *" : req.label,
            border: const OutlineInputBorder(),
          ),
        );

      case 'number':
        return TextField(
          controller: _textControllers[req.id],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: req.isRequired ? "${req.label} *" : req.label,
            border: const OutlineInputBorder(),
          ),
        );

      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: _textControllers[req.id]!.text.isEmpty
              ? null
              : _textControllers[req.id]!.text,
          decoration: InputDecoration(
            labelText: req.isRequired ? "${req.label} *" : req.label,
            border: const OutlineInputBorder(),
          ),
          items: req.optionsList
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (value) {
            setState(() => _textControllers[req.id]!.text = value ?? '');
          },
        );

      case 'radio':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req.isRequired ? "${req.label} *" : req.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ...req.optionsList.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _textControllers[req.id]!.text,
                  onChanged: (value) {
                    setState(() => _textControllers[req.id]!.text = value ?? '');
                  },
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        );

      case 'checkbox':
        final selected = _textControllers[req.id]!.text.isEmpty
            ? <String>[]
            : _textControllers[req.id]!.text.split(',');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req.isRequired ? "${req.label} *" : req.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ...req.optionsList.map((option) => CheckboxListTile(
                  title: Text(option),
                  value: selected.contains(option),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                      _textControllers[req.id]!.text = selected.join(',');
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        );

      case 'file':
        final file = _answers[req.id] as File?;
        return OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: Text(
            file != null
                ? file.path.split('/').last
                : (req.isRequired ? "${req.label} * (Upload)" : "${req.label} (Upload)"),
          ),
          onPressed: () => _pickFile(req.id),
        );

      default: // textbox
        return TextField(
          controller: _textControllers[req.id],
          decoration: InputDecoration(
            labelText: req.isRequired ? "${req.label} *" : req.label,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = widget.tag;
    final sortedRequirements = [...tag.requirements]..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: Text(tag.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tag.description.isNotEmpty) ...[
              Text(tag.description, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
            ],
            if (tag.benefits.isNotEmpty) ...[
              const Text("Benefits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(tag.benefits),
              const SizedBox(height: 16),
            ],
            if (tag.termsConditions.isNotEmpty) ...[
              const Text("Terms & Conditions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(tag.termsConditions),
              const SizedBox(height: 24),
            ],
            if (sortedRequirements.isNotEmpty) ...[
              const Text("Application Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...sortedRequirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildRequirementField(req),
                  )),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Submit Application"),
                  ),
          ],
        ),
      ),
    );
  }
}