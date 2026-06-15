import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

import 'components/user_avatar.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String name;
  final String? profilePictureId;
  const ProfilePage({super.key, required this.username, required this.name, this.profilePictureId});

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
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a new password")));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', widget.username)],
      );

      if (result.documents.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username not found")));
        return;
      }

      final docId = result.documents.first.$id;
      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        documentId: docId,
        data: {'password': AppwriteService.hashPassword(_newPasswordController.text.trim())},
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
                    UserAvatar(
                      profilePictureId: widget.profilePictureId,
                      fallbackName: widget.name,
                      radius: 50,
                      backgroundColor: AppTheme.kGreen.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.kGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: AppTheme.sectionTitle.copyWith(fontSize: 22),
                    ),
                    Text(
                      widget.username,
                      style: AppTheme.subheadingGrey.copyWith(fontSize: 14),
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
                      readOnly: true,
                      decoration: AppTheme.inputDecoration("Username", Icons.person_outline).copyWith(
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        filled: true,
                      ),
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


