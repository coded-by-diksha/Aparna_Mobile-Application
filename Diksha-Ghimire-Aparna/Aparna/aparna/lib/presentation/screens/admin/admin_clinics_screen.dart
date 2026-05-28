import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/expert_help_model.dart';
import '../../../core/constant/apiConstant.dart';
import '../../../core/guards/auth_guard.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../widgets/location_picker.dart';

class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({Key? key}) : super(key: key);

  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen> {
  final AdminService _adminService = AdminService();
  List<ExpertHelp> _experts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ExpertHelp> get _filteredExperts {
    if (_searchQuery.isEmpty) return _experts;
    final q = _searchQuery.toLowerCase();
    return _experts.where((expert) {
      return expert.associateName.toLowerCase().contains(q) ||
          (expert.address?.toLowerCase().contains(q) ?? false) ||
          (expert.description?.toLowerCase().contains(q) ?? false) ||
          (expert.contactInfo?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadExperts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExperts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final expertMaps = await _adminService.fetchExperts();
      if (mounted) {
        setState(() {
          _experts = expertMaps.map((e) => ExpertHelp.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading experts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final verticalPadding = (size.height * 0.05).clamp(16.0, 32.0);
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                    ),
                  )
                : _filteredExperts.isEmpty
                    ? _buildEmptyState()
                    : _buildExpertList(),
          ),
          const SizedBox(height: 80), // Space for nav bar
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final verticalPadding = (size.height * 0.05).clamp(16.0, 32.0);
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: doctor illustration + titles
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/expert.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.medical_services, size: 56, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.expertClinics,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.managePartnerClinics,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar + Add button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchForClinics,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddEditExpertDialog(),
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                label: Text(l10n.add, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.noExpertsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFirstExpertRegistration,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertList() {
    return RefreshIndicator(
      onRefresh: _loadExperts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _filteredExperts.length,
        itemBuilder: (context, index) {
          final expert = _filteredExperts[index];
          return _buildExpertCard(expert);
        },
      ),
    );
  }

  Widget _buildExpertCard(ExpertHelp expert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic icon/image (mint-green background, medical cross or image)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: expert.clinicImage != null && expert.clinicImage!.isNotEmpty
                ? _buildClinicImageWidget(expert.clinicImage!)
                : Icon(
                    Icons.medical_services,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 12),
          // Name, description, location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert.associateName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (expert.description != null && expert.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expert.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expert.address ?? AppLocalizations.of(context)!.noAddressProvided,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit and Delete icon buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAddEditExpertDialog(expert: expert),
                icon: Icon(Icons.edit, size: 22, color: Colors.grey.shade700),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: () => _confirmDelete(expert),
                icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditExpertDialog({ExpertHelp? expert}) {
    final nameController = TextEditingController(text: expert?.associateName ?? '');
    final contactController = TextEditingController(text: expert?.contactInfo ?? '');
    final addressController = TextEditingController(text: expert?.address ?? '');
    final descController = TextEditingController(text: expert?.description ?? '');
    final latController = TextEditingController(text: expert?.latitude?.toString() ?? '');
    final lngController = TextEditingController(text: expert?.longitude?.toString() ?? '');
    XFile? pickedClinicImage;
    bool removeClinicImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(expert == null ? AppLocalizations.of(context)!.addExpert : AppLocalizations.of(context)!.editExpert),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.associateName),
              ),
              TextField(
                controller: contactController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contactInfoPhoneEmail),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.address),
              ),
              // Clinic image
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.clinicImage, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setDialogState(() {
                          pickedClinicImage = image;
                          removeClinicImage = false;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedClinicImage != null
                          ? Image.file(File(pickedClinicImage!.path), fit: BoxFit.cover)
                          : (!removeClinicImage && expert != null && expert.clinicImage != null && expert.clinicImage!.isNotEmpty)
                              ? _buildClinicImageWidget(expert.clinicImage!)
                              : Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TextButton.icon(
                      //   label: Text(AppLocalizations.of(context)!.pickImage, style: TextStyle(fontSize: 9)),
                      //   onPressed: () async {
                      //     final XFile? image = await ImagePicker().pickImage(
                      //       source: ImageSource.gallery,
                      //       maxWidth: 800,
                      //       imageQuality: 85,
                      //     );
                      //     if (image != null) {
                      //       setDialogState(() {
                      //         pickedClinicImage = image;
                      //         removeClinicImage = false;
                      //       });
                      //     }
                      //   },
                      //   icon: const Icon(Icons.photo_library, size: 10),
                      //   // label: Text(AppLocalizations.of(context)!.pickImage),
                      // ),
                      if (pickedClinicImage != null || (expert != null && expert.clinicImage != null && expert.clinicImage!.isNotEmpty && !removeClinicImage))
                        TextButton.icon(
                          onPressed: () => setDialogState(() {
                            pickedClinicImage = null;
                            removeClinicImage = true;
                          }),
                          icon: const Icon(Icons.delete_outline, size: 10),
                          label: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontSize: 9)),
                        ),
                    ],
                  ),
                ],
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                maxLines: 3,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: latController,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.latitude),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        TextField(
                          controller: lngController,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.longitude),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map, color: AppTheme.primaryColor, size: 30),
                        tooltip: AppLocalizations.of(context)!.pickOnMap,
                        onPressed: () async {
                        final initialLat = double.tryParse(latController.text);
                        final initialLng = double.tryParse(lngController.text);
                        final picked = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPicker(
                              initialLocation: (initialLat != null && initialLng != null)
                                  ? LatLng(initialLat, initialLng)
                                  : null,
                            ),
                          ),
                        );

                        if (picked != null) {
                          latController.text = picked.latitude.toString();
                          lngController.text = picked.longitude.toString();
                          final address = await _addressFromCoordinates(picked.latitude, picked.longitude);
                          if (address != null && address.isNotEmpty) {
                            addressController.text = address;
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 26),
                      tooltip: AppLocalizations.of(context)!.getAddressFromCoordinates,
                      onPressed: () async {
                        final lat = double.tryParse(latController.text);
                        final lng = double.tryParse(lngController.text);
                        final l10n = AppLocalizations.of(context)!;
                        if (lat == null || lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.enterValidLatLngFirst)),
                          );
                          return;
                        }
                        final address = await _addressFromCoordinates(lat, lng);
                        if (address != null && address.isNotEmpty) {
                          addressController.text = address;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.addressFilledFromCoordinates)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.couldNotGetAddressForCoordinates)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final expertData = {
                'associatename': nameController.text,
                'contactinfo': contactController.text,
                'address': addressController.text,
                'description': descController.text,
                'latitude': double.tryParse(latController.text),
                'longitude': double.tryParse(lngController.text),
              };

              if (pickedClinicImage != null) {
                try {
                  final bytes = await pickedClinicImage!.readAsBytes();
                  expertData['clinic_image'] = base64Encode(bytes);
                } catch (e) {
                  debugPrint('Error reading clinic image: $e');
                }
              } else if (removeClinicImage && expert != null) {
                expertData['clinic_image'] = null;
              }

              bool success;
              if (expert == null) {
                final userId = await AuthService.getUserId();
                if (userId != null) {
                  expertData['userid'] = userId;
                }
                success = await _adminService.createExpert(expertData);
              } else {
                success = await _adminService.updateExpert(expert.exid.toString(), expertData);
              }

              if (success) {
                Navigator.pop(context);
                _loadExperts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.expertSavedSuccess)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
        },
      ),
    );
  }

  Widget _buildClinicImageWidget(String clinicImage) {
    if (clinicImage.startsWith('http')) {
      return Image.network(clinicImage, fit: BoxFit.cover);
    }
    if (clinicImage.startsWith('/')) {
      final baseUrl = ApiConstant.baseUrl.endsWith('/') ? ApiConstant.baseUrl : '${ApiConstant.baseUrl}/';
      final url = '$baseUrl${clinicImage.replaceFirst(RegExp(r'^/'), '')}';
      return Image.network(url, fit: BoxFit.cover);
    }
    try {
      final bytes = base64Decode(clinicImage);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey.shade500);
    }
  }

  /// Reverse geocode coordinates to a readable address (used when admin sets location).
  /// Tries native geocoding first (Android/iOS); falls back to OpenStreetMap Nominatim on failure or unsupported platforms (e.g. Windows).
  Future<String?> _addressFromCoordinates(double latitude, double longitude) async {
    // 1. Try native geocoding (works on Android/iOS only)
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        final address = parts.join(', ');
        if (address.isNotEmpty) return address;
      }
    } catch (e) {
      debugPrint('Reverse geocode (native) error: $e');
    }

    // 2. Fallback: OpenStreetMap Nominatim (works on all platforms, no API key)
    try {
      final uri = Uri.parse(
        '${ApiConstant.nominatimReverseBaseUrl}?lat=$latitude&lon=$longitude&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AparnaApp/1.0 (contact@example.com)'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) return displayName;
      }
    } catch (e) {
      debugPrint('Reverse geocode (Nominatim) error: $e');
    }
    return null;
  }

  Future<void> _confirmDelete(ExpertHelp expert) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpertTitle),
        content: Text(l10n.expertDeleteConfirmation(expert.associateName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.deleteExpert(expert.exid.toString());
      if (success) {
        _loadExperts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expertDeletedSuccess)),
        );
      }
    }
  }
}
