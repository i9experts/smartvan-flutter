import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';

class KidsScreen extends ConsumerStatefulWidget {
  const KidsScreen({super.key});

  @override
  ConsumerState<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends ConsumerState<KidsScreen> {
  List<dynamic> _kids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKids();
  }

  Future<void> _loadKids() async {
    try {
      final response = await ApiService.get('/kid/getKids');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw['data'] ?? raw;
        setState(() => _kids = data is List ? data : []);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Kids',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/add-kid'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Add Kid',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B2B6B)),
                  )
                : _kids.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadKids,
                        color: const Color(0xFF1B2B6B),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _kids.length,
                          itemBuilder: (context, index) {
                            return _buildKidCard(_kids[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2B6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care, size: 50,
                color: Color(0xFF1B2B6B)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Kids Added Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your child to start tracking\ntheir school van journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8A94A6),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/add-kid'),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Kid',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidCard(Map<String, dynamic> kid) {
    final String name =
        kid['fullname'] ?? kid['name'] ?? kid['kidName'] ?? 'Unknown';
    final String grade = kid['grade']?.toString() ?? 'N/A';
    final String schoolName =
        kid['school']?['schoolName'] ?? kid['schoolName'] ?? 'N/A';
    final String? image = kid['image'] ?? kid['profileImage'];
    final String status = kid['status'] ?? 'pending';
    final bool isActive = status.toLowerCase() == 'active';
    final String vanNumber =
        kid['van']?['carNumber'] ?? kid['van']?['vanNumber'] ?? 'Not assigned';
    final String driverName = kid['driver']?['fullname'] ?? 'Not assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1B2B6B).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: image != null
                        ? Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(name))
                        : _buildAvatarFallback(name),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Poppins',
                          )),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 14, color: Color(0xFF8A94A6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(schoolName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A94A6),
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.class_outlined,
                              size: 14, color: Color(0xFF8A94A6)),
                          const SizedBox(width: 4),
                          Text('Grade: $grade',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A94A6),
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF27AE60).withOpacity(0.1)
                        : const Color(0xFFFFB800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFFFB800),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          size: 16, color: Color(0xFF1B2B6B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Van: $vanNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A2E),
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outlined,
                          size: 16, color: Color(0xFF1B2B6B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Driver: $driverName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A2E),
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.map_outlined,
                  label: 'Track',
                  color: const Color(0xFF1B2B6B),
                  onTap: () => context.go('/tracking'),
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'History',
                  color: const Color(0xFF8A94A6),
                  onTap: () => _showTripHistory(kid),
                ),
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFFFFB800),
                  onTap: () => _showEditKid(kid),
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: const Color(0xFFFF4B4B),
                  onTap: () => _confirmDelete(kid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF1B2B6B).withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2B6B),
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripHistory(Map<String, dynamic> kid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEAECF0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trip History - ${kid['fullname'] ?? 'Kid'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.history, size: 48, color: Color(0xFF8A94A6)),
            const SizedBox(height: 12),
            const Text(
              'Trip history coming soon!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditKid(Map<String, dynamic> kid) {
    final nameController =
        TextEditingController(text: kid['fullname'] ?? '');
    final gradeController =
        TextEditingController(text: kid['grade']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAECF0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Kid',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Full Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  )),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter full name',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
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
                    borderSide: const BorderSide(
                        color: Color(0xFF1B2B6B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Grade',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  )),
              const SizedBox(height: 8),
              TextFormField(
                controller: gradeController,
                decoration: InputDecoration(
                  hintText: 'Enter grade',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
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
                    borderSide: const BorderSide(
                        color: Color(0xFF1B2B6B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final kidId = kid['_id'] ?? kid['id'];
                      await ApiService.post('/kid/update-kid', {
                        'kidId': kidId,
                        'fullname': nameController.text.trim(),
                        'grade': gradeController.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kid updated successfully!'),
                            backgroundColor: Color(0xFF27AE60),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _loadKids();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update kid'),
                            backgroundColor: Color(0xFFFF4B4B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      )),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> kid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Kid',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to remove ${kid['fullname'] ?? 'this kid'}?',
            style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove',
                style:
                    TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final kidId = kid['_id'] ?? kid['id'];
        await ApiService.post('/kid/deleteKidByParent', {'kidId': kidId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kid removed successfully'),
              backgroundColor: Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadKids();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove kid'),
              backgroundColor: Color(0xFFFF4B4B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}