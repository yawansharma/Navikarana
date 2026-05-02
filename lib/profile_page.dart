import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: 'main_db',
        collectionId: 'users',
        queries: [Query.equal('username', _usernameController.text.trim())],
      );

      if (result.documents.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username not found")));
        return;
      }

      final docId = result.documents.first.$id;
      await AppwriteService.databases.updateDocument(
        databaseId: 'main_db',
        collectionId: 'users',
        documentId: docId,
        data: {'password': _newPasswordController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        title: const Text("Profile Settings"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: AppTheme.bottomSheet,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppTheme.sheetHandle,
                    const Icon(Icons.shield_outlined, size: 60, color: AppTheme.kGreen),
                    const SizedBox(height: 16),
                    Text(
                      widget.username,
                      style: AppTheme.sectionTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Security Center",
                      textAlign: TextAlign.center,
                      style: AppTheme.subheadingGrey,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: AppTheme.inputDecoration("Confirm Username", Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: AppTheme.inputDecoration("New Password", Icons.lock_outline),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
