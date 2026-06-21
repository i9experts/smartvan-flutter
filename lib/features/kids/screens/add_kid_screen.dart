import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/network/api_service.dart';

class AddKidScreen extends ConsumerStatefulWidget {
  const AddKidScreen({super.key});

  @override
  ConsumerState<AddKidScreen> createState() => _AddKidScreenState();
}

class _AddKidScreenState extends ConsumerState<AddKidScreen> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSchools = false;
  File? _selectedImage;
  List<dynamic> _schools = [];
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  String _selectedGender = 'male';

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
  setState(() => _isLoadingSchools = true);
  try {
    final response = await ApiService.get('/school/getAllSchools');
    if (response.statusCode == 200) {
      final data = response.data;
      final schools = data is List ? data : (data['data'] ?? data['schools'] ?? []);
      setState(() => _schools = schools);
    }
  } catch (e) {
  } finally {
    if (mounted) setState(() => _isLoadingSchools = false);
  }
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _addKid() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter child\'s name');
      return;
    }
    if (_selectedSchoolId == null) {
      _showError('Please select a school');
      return;
    }
    if (_gradeController.text.isEmpty) {
      _showError('Please enter grade/class');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = FormData.fromMap({
        'fullname': _nameController.text.trim(),
        'schoolId': _selectedSchoolId,
        'grade': _gradeController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        if (_selectedImage != null)
          'image': await MultipartFile.fromFile(
             _selectedImage!.path,
             filename: 'kid_image.jpg',
          ),
  });

      final dio = Dio();
      final prefs =
          await ApiService.getPrefs();
      final token = prefs.getString('auth_token');

      final response = await dio.post(
        'https://smartvanride.com/backend/kid/addKid',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Kid added successfully!'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          context.go('/home');
        }
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to add kid. Try again.';
      _showError(message.toString());
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () => context.go('/home'),
                    ),
                    const Text(
                      'Add Kid',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF1B2B6B),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFF1B2B6B),
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1B2B6B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Child Name
                  _buildLabel('Child\'s Full Name *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Enter child\'s full name',
                    icon: Icons.person_outlined,
                  ),
                  const SizedBox(height: 16),

                  // School Dropdown
                  _buildLabel('Select School *'),
                  const SizedBox(height: 8),
                  _buildSchoolDropdown(),
                  const SizedBox(height: 16),

                  // Grade
                  _buildLabel('Grade / Class *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _gradeController,
                    hint: 'e.g. Grade 3, Class 5',
                    icon: Icons.class_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Age
                  _buildLabel('Age'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _ageController,
                    hint: 'Enter child\'s age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  _buildLabel('Gender'),
                  const SizedBox(height: 8),
                  _buildGenderSelector(),
                  const SizedBox(height: 16),

                  // Address
                  _buildLabel('Home Address'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Enter home address',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addKid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Add Kid',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF8A94A6),
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1B2B6B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAECF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B2B6B), width: 2),
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    if (_isLoadingSchools) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1B2B6B),
            ),
          ),
        ),
      );
    }

    if (_schools.isEmpty) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.school_outlined, color: Color(0xFF8A94A6)),
            SizedBox(width: 12),
            Text(
              'No schools available',
              style: TextStyle(
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedSchoolId != null
              ? const Color(0xFF1B2B6B)
              : const Color(0xFFEAECF0),
          width: _selectedSchoolId != null ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSchoolId,
          hint: const Row(
            children: [
              Icon(Icons.school_outlined, color: Color(0xFF1B2B6B)),
              SizedBox(width: 12),
              Text(
                'Select School',
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF1B2B6B)),
          items: _schools.map<DropdownMenuItem<String>>((school) {
            return DropdownMenuItem<String>(
              value: school['_id'] ?? school['id'],
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      color: Color(0xFF1B2B6B), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      school['name'] ?? 'Unknown School',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSchoolId = value;
              _selectedSchoolName = _schools
                  .firstWhere((s) =>
                      (s['_id'] ?? s['id']) == value)['name'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = 'male'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedGender == 'male'
                    ? const Color(0xFF1B2B6B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedGender == 'male'
                      ? const Color(0xFF1B2B6B)
                      : const Color(0xFFEAECF0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.male,
                    color: _selectedGender == 'male'
                        ? Colors.white
                        : const Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Male',
                    style: TextStyle(
                      color: _selectedGender == 'male'
                          ? Colors.white
                          : const Color(0xFF8A94A6),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = 'female'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedGender == 'female'
                    ? const Color(0xFF1B2B6B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedGender == 'female'
                      ? const Color(0xFF1B2B6B)
                      : const Color(0xFFEAECF0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.female,
                    color: _selectedGender == 'female'
                        ? Colors.white
                        : const Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Female',
                    style: TextStyle(
                      color: _selectedGender == 'female'
                          ? Colors.white
                          : const Color(0xFF8A94A6),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}