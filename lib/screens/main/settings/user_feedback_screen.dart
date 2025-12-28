import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/user_feedback.dart';
import 'package:meditrack/style/colors.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  bool _isSubmitting = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = UserFeedback(
        id: '', // Firestore will generate
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        category: _selectedCategory,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        submittedAt: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('feedback').add(feedback.toFirestore());

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text('Thank You!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your feedback has been submitted successfully.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'We appreciate you taking the time to help us improve MediTrack.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Our team will review your feedback shortly.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to settings
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.feedback, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We value your feedback!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help us improve MediTrack',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Category Selection
              Text(
                'Feedback Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FeedbackCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.icon),
                        const SizedBox(width: 6),
                        Text(category.displayName),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    backgroundColor: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDarkMode ? Colors.grey[400] : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Subject Field
              Text(
                'Subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Brief description of your feedback',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  prefixIcon: Icon(Icons.subject, color: AppColors.primary),
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF2F4F8),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFC8D1DC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFC8D1DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00B9E4),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  if (value.trim().length < 5) {
                    return 'Subject must be at least 5 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Message Field
              Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Please provide details about your feedback...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF2F4F8),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFC8D1DC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFC8D1DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00B9E4),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[900]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your feedback is confidential and will only be used to improve MediTrack.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}