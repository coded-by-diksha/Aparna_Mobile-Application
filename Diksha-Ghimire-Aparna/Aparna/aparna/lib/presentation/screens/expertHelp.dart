import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constant/apiConstant.dart';
import '../../core/di/dependency_injection.dart';
import '../bloc/expert_help/expert_help_bloc.dart';
import '../bloc/expert_help/expert_help_event.dart';
import '../bloc/expert_help/expert_help_state.dart';
import '../../domain/entities/clinic_entity.dart';

class ExpertHelp extends StatelessWidget {
  const ExpertHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DependencyInjection.createExpertHelpBloc()..add(LoadExpertHelpMap()),
      child: const ExpertHelpView(),
    );
  }
}

class ExpertHelpView extends StatefulWidget {
  const ExpertHelpView({Key? key}) : super(key: key);

  @override
  State<ExpertHelpView> createState() => _ExpertHelpViewState();
}

class _ExpertHelpViewState extends State<ExpertHelpView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  double? _selectedDistanceFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final verticalPadding = (size.height * 0.05).clamp(16.0, 32.0);
    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          BlocConsumer<ExpertHelpBloc, ExpertHelpState>(
            listener: (context, state) {
              if (state is ExpertHelpError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is ExpertHelpLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ExpertHelpLoaded) {
                final clinicsToShow = state.filteredClinics;
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      state.userLocation.latitude,
                      state.userLocation.longitude,
                    ),
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ApiConstant.openStreetMapTileUrlTemplate,
                      userAgentPackageName: 'com.example.aparna', // Recommended by OSM policy
                    ),
                    // Line following streets from user to selected clinic (or straight line fallback)
                    if (state.selectedClinic != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: state.routePoints != null && state.routePoints!.length >= 2
                                ? state.routePoints!
                                : [
                                    LatLng(state.userLocation.latitude, state.userLocation.longitude),
                                    LatLng(state.selectedClinic!.latitude, state.selectedClinic!.longitude),
                                  ],
                            color: const Color(0xFFE91E63),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // User Location Marker
                        Marker(
                          point: LatLng(
                            state.userLocation.latitude,
                            state.userLocation.longitude,
                          ),
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Clinic Markers
                        ...clinicsToShow.map((clinic) => Marker(
                              point: LatLng(clinic.latitude, clinic.longitude),
                              width: 64,
                              height: 72,
                              child: GestureDetector(
                                onTap: () {
                                  context.read<ExpertHelpBloc>().add(SelectClinic(clinic));
                                  _showClinicDetails(context, clinic).then((_) {
                                    if (mounted) {
                                      context.read<ExpertHelpBloc>().add(ClearSelectedClinic());
                                    }
                                  });
                                },
                                child: _buildCustomClinicMarker(clinic),
                              ),
                            )),
                      ],
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),

SizedBox(height: verticalPadding),
          // Top Search Bar Area
          Positioned(
            top: verticalPadding,
            left: 20,
            right: 20,
            child: Column(
             
              children: [
                Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A8A), // Light red/pinkish
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),

                    SizedBox(width: verticalPadding),
                    // Search Box
                    Expanded(
                      child: Container(
                          height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            context.read<ExpertHelpBloc>().add(SearchClinics(value));
                          },
                          decoration: InputDecoration(
                            hintText: "Find nearby clinics",
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.black54),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.black54),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<ExpertHelpBloc>().add(const SearchClinics(''));
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: horizontalPadding),
                // Distance Filter Chips
                _buildFilterChips(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final state = context.read<ExpertHelpBloc>().state;
          if (state is ExpertHelpLoaded) {
            _mapController.move(
              LatLng(state.userLocation.latitude, state.userLocation.longitude),
              14.5,
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildCustomClinicMarker(ClinicEntity clinic) {
    final imageUrl = clinic.clinicImage;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? _buildClinicMarkerImage(imageUrl)
              : Container(
                  color: const Color(0xFFFF5252),
                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
                ),
        ),
        // Small Triangle at the bottom to mimic a pin
         ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: const Color(0xFFFF5252),
            width: 10,
            height: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicMarkerImage(String imageUrl) {
    String url = imageUrl;
    if (imageUrl.startsWith('/')) {
      final baseUrl = ApiConstant.baseUrl.endsWith('/') ? ApiConstant.baseUrl : '${ApiConstant.baseUrl}/';
      url = '$baseUrl${imageUrl.replaceFirst(RegExp(r'^/'), '')}';
    }

    final isNetworkOrPath = imageUrl.startsWith('http') || imageUrl.startsWith('/');
    return isNetworkOrPath
        ? Image.network(
            url,
            fit: BoxFit.cover,
            width: 42,
            height: 42,
            errorBuilder: (_, __, ___) {
              return Container(
                color: const Color(0xFFFF5252),
                child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
              );
            },
          )
        : _buildBase64Image(imageUrl, 42);
  }

  Future<void> _showClinicDetails(BuildContext context, ClinicEntity clinic) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Highlighted distance chip
              if (clinic.distance.isNotEmpty) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.straighten, color: const Color(0xFFE91E63), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${clinic.distance} from your place',
                          style: const TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone, clinic.phone),
                        const SizedBox(height: 5),
                        _buildInfoRow(Icons.description_outlined, clinic.description),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Clinic image from backend (or placeholder)
                  _buildClinicImage(clinic),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Address:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                   Expanded(
                    child: Text(
                      clinic.address,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: const Color(0xFFFFCDD2), // Light Pink/Red
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.local_shipping, color: Colors.black, size: 20), // Ambulance icon
                         const SizedBox(width: 8),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text("Helpline:", style: TextStyle(fontSize: 10, color: Colors.black87)),
                             Text(clinic.phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                           ],
                         )
                       ],
                     ),
                   ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClinicImage(ClinicEntity clinic) {
    const size = 100.0;
    const height = 80.0;
    final imageUrl = clinic.clinicImage;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: size,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.local_hospital_outlined, size: 36, color: Colors.grey[400]),
      );
    }
    String url = imageUrl;
    if (imageUrl.startsWith('/')) {
      final baseUrl = ApiConstant.baseUrl.endsWith('/') ? ApiConstant.baseUrl : '${ApiConstant.baseUrl}/';
      url = '$baseUrl${imageUrl.replaceFirst(RegExp(r'^/'), '')}';
    }
    final isNetworkOrPath = imageUrl.startsWith('http') || imageUrl.startsWith('/');
    return Container(
      width: size,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isNetworkOrPath
          ? Image.network(url, fit: BoxFit.cover)
          : _buildBase64Image(imageUrl, height),
    );
  }

// Base64 image handling with error fallback

  Widget _buildBase64Image(String base64String, double height) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
      );
    }
  }

// Helper method to build info rows with icons
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      {'label': 'All', 'distance': null},
      {'label': '< 1 km', 'distance': 1.0},
      {'label': '< 2 km', 'distance': 2.0},
      {'label': '< 5 km', 'distance': 5.0},
      {'label': '< 10 km', 'distance': 10.0},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final distance = filter['distance'] as double?;
          final isSelected = _selectedDistanceFilter == distance;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDistanceFilter = selected ? distance : null;
                });
                context.read<ExpertHelpBloc>().add(FilterByDistance(selected ? distance : null));
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFF8A8A),
              checkmarkColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFFF8A8A) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}



class TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}