import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final FeedbackModel? existingFeedback;

  const SubmitFeedbackScreen({super.key, this.existingFeedback});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late double _rating;
  late String _category;
  
  File? _selectedImageFile;
  String? _remotePhotoUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['bug', 'feature', 'praise', 'complaint', 'general'];

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.existingFeedback?.comment ?? '');
    _rating = widget.existingFeedback?.rating ?? 5.0;
    _category = widget.existingFeedback?.category ?? 'general';
    _remotePhotoUrl = widget.existingFeedback?.photoUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _remotePhotoUrl = null;
    });
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final storageService = context.read<StorageService>();
      final feedbackService = context.read<FeedbackService>();

      final user = authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? finalPhotoUrl = _remotePhotoUrl;

      // Upload if a new local image is chosen
      if (_selectedImageFile != null) {
        finalPhotoUrl = await storageService.uploadFeedbackPhoto(user.uid, _selectedImageFile!.path);
      }

      if (widget.existingFeedback != null) {
        await feedbackService.updateFeedback(
          id: widget.existingFeedback!.id,
          rating: _rating,
          comment: _commentController.text.trim(),
          category: _category,
          photoUrl: finalPhotoUrl,
        );
      } else {
        await feedbackService.addFeedback(
          rating: _rating,
          comment: _commentController.text.trim(),
          category: _category,
          photoUrl: finalPhotoUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingFeedback != null 
                ? 'Feedback updated successfully!' 
                : 'Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingFeedback != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Feedback' : 'Submit Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How would you rate your experience?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Center(
                  child: RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  children: _categories.map((cat) {
                    final isSelected = _category == cat;
                    return ChoiceChip(
                      label: Text(cat[0].toUpperCase() + cat.substring(1)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _category = cat;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Comments or Suggestions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Provide details here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide comments';
                    }
                    if (value.trim().length < 10) {
                      return 'Must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Attach Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (_selectedImageFile != null || _remotePhotoUrl != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: _selectedImageFile != null 
                                ? FileImage(_selectedImageFile!) as ImageProvider
                                : NetworkImage(_remotePhotoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _removeImage,
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _showImageSourceActionSheet,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitFeedback,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEditing ? 'Save Changes' : 'Submit', style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
