import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile_model.dart';
import '../../services/image_helper.dart';
import '../squad/squad_teams_screen.dart';

/// Entry Form Screen — User profile details
class EntryFormScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const EntryFormScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _selectedProvince;
  File? _imageFile;
  bool _saving = false;

  final List<String> _provinces = [
    'Sindh',
    'Punjab',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Jammu & Kashmir',
    'Islamabad',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final profile = UserProfileModel.fromMap(user.uid, doc.data()!);
        setState(() {
          _nameCtrl.text = profile.name;
          _phoneCtrl.text = profile.phone;
          _cityCtrl.text = profile.city;
          _addressCtrl.text = profile.address;
          if (_provinces.contains(profile.province)) {
            _selectedProvince = profile.province;
          }
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  String? _validateInputs() {
    if (_imageFile == null) return 'Please upload your profile picture';
    if (_nameCtrl.text.trim().length < 3) {
      return 'Please enter your full name (min 3 chars)';
    }
    if (_phoneCtrl.text.trim().length < 10) {
      return 'Please enter a valid phone number';
    }
    if (_cityCtrl.text.trim().isEmpty) return 'Please enter your city';
    if (_selectedProvince == null) return 'Please select your province';
    if (_addressCtrl.text.trim().length < 10) {
      return 'Please enter your full address (min 10 chars)';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validateInputs();
    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please login first', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final base64String = await ImageHelper.fileToBase64(_imageFile!);

      if (!ImageHelper.isSafeForFirestore(base64String)) {
        throw Exception('Image too large. Please choose a smaller image.');
      }

      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<String> entered = [];
      if (profileDoc.exists) {
        final existing =
            UserProfileModel.fromMap(user.uid, profileDoc.data()!);
        entered = List<String>.from(existing.enteredTournaments);
      }

      if (!entered.contains(widget.tournamentId)) {
        entered.add(widget.tournamentId);
      }

      final profile = UserProfileModel(
        userId: user.uid,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        province: _selectedProvince!,
        address: _addressCtrl.text.trim(),
        profilePhotoBase64: base64String,
        enteredTournaments: entered,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));

      if (!mounted) return;

      _snack('Profile saved! Now select your squad.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SquadTeamsScreen(
            tournamentId: widget.tournamentId,
            tournamentName: widget.tournamentName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _snack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF00C9A7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.tournamentName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Tournament',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please provide your details to enter',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2D2D44),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  color: Colors.white54, size: 32),
                              SizedBox(height: 4),
                              Text(
                                'Tap to upload',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Profile Picture *',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            _label('Full Name *'),
            _textField(_nameCtrl, 'Enter your full name'),
            const SizedBox(height: 16),

            _label('Phone Number *'),
            _textField(_phoneCtrl, '+92 3XX XXXXXXX',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            _label('City *'),
            _textField(_cityCtrl, 'e.g. Karachi'),
            const SizedBox(height: 16),

            _label('Province *'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvince,
                  hint: const Text(
                    'Select Province',
                    style: TextStyle(color: Colors.white38),
                  ),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2D2D44),
                  style: const TextStyle(color: Colors.white),
                  items: _provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProvince = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('Full Address * (for gifts)'),
            _textField(
              _addressCtrl,
              'House #, Street, Area, City',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'ENTER TOURNAMENT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2D2D44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }
}