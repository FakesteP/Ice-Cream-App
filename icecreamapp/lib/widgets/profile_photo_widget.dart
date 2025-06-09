import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:icecreamapp/models/user_model.dart';
import 'package:icecreamapp/services/user_service.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final User user;
  final double size;
  final bool showEditButton;
  final VoidCallback? onPhotoUpdated;

  const ProfilePhotoWidget({
    super.key,
    required this.user,
    this.size = 100,
    this.showEditButton = true,
    this.onPhotoUpdated,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _currentPhotoBase64;

  @override
  void initState() {
    super.initState();
    _currentPhotoBase64 = widget.user.profilePhotoBase64;
    if (_currentPhotoBase64 == null) {
      _loadProfilePhoto();
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final photoBase64 = await _userService.getProfilePhoto(widget.user.id);

      if (mounted) {
        setState(() {
          _currentPhotoBase64 = photoBase64;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile photo: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      // Read image as bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Convert to base64
      final String base64Image = base64Encode(imageBytes);

      // Get MIME type
      final String mimeType = image.mimeType ?? 'image/jpeg';

      // Upload to server
      await _userService.uploadProfilePhoto(
        widget.user.id,
        base64Image,
        mimeType,
      );

      // Update local state
      final String fullBase64 = 'data:$mimeType;base64,$base64Image';

      if (mounted) {
        setState(() {
          _currentPhotoBase64 = fullBase64;
          _isLoading = false;
        });

        // Notify parent widget
        widget.onPhotoUpdated?.call();

        _showSuccessSnackBar('Profile photo updated successfully!');
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to upload photo: $e');
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      final bool? confirm = await _showDeleteConfirmDialog();
      if (confirm != true) return;

      setState(() {
        _isLoading = true;
      });

      await _userService.deleteProfilePhoto(widget.user.id);

      if (mounted) {
        setState(() {
          _currentPhotoBase64 = null;
          _isLoading = false;
        });

        widget.onPhotoUpdated?.call();
        _showSuccessSnackBar('Profile photo deleted successfully!');
      }
    } catch (e) {
      print('Error deleting photo: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to delete photo: $e');
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile Photo'),
          content:
              const Text('Are you sure you want to delete your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty) {
      // Remove data:image/type;base64, prefix if present
      String base64Data = _currentPhotoBase64!;
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',')[1];
      }

      try {
        final Uint8List imageBytes = base64Decode(base64Data);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar();
              },
            ),
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildDefaultAvatar();
      }
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildProfileImage(),
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'upload':
                    _pickAndUploadImage();
                    break;
                  case 'delete':
                    if (_currentPhotoBase64 != null) {
                      _deleteProfilePhoto();
                    }
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'upload',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, size: 18),
                      SizedBox(width: 8),
                      Text('Upload Photo'),
                    ],
                  ),
                ),
                if (_currentPhotoBase64 != null)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Photo',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
