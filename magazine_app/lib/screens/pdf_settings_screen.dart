import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PdfSettingsScreen extends StatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _organizationController = TextEditingController();
  bool _includeSignature = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/pdf_settings.json');
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        setState(() {
          _headerController.text = data['header'] ?? '';
          _footerController.text = data['footer'] ?? '';
          _organizationController.text = data['organization'] ?? '';
          _includeSignature = data['include_signature'] ?? true;
        });
      }
    } catch (e) {
      // Ignore error on first load
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      try {
        final file = await _getSettingsFile();
        final data = {
          'header': _headerController.text,
          'footer': _footerController.text,
          'organization': _organizationController.text,
          'include_signature': _includeSignature,
        };
        await file.writeAsString(json.encode(data));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving settings: $e')),
          );
        }
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize PDF Appearance',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization Name',
                        helperText: 'Displayed at the top of the PDF',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _headerController,
                      decoration: const InputDecoration(
                        labelText: 'Header Text',
                        helperText: 'Additional text in the header',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _footerController,
                      decoration: const InputDecoration(
                        labelText: 'Footer Text',
                        helperText: 'Copyright or contact info in the footer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Include Signature Section'),
                      subtitle: const Text('Add space for digital or physical signatures'),
                      value: _includeSignature,
                      onChanged: (value) {
                        setState(() {
                          _includeSignature = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
