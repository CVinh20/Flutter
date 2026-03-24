// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';

class MapScreen extends StatefulWidget {
  final List<Branch> branches;
  const MapScreen({super.key, required this.branches});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late MapController _mapController;
  GeoPoint? _userLocation;
  bool _isLoading = true;

  late AnimationController _cardAnimationController;
  late Animation<Offset> _cardAnimation;
  Branch? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 16.047079, longitude: 108.206230),
    );
    _initializeMap();

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    await _checkAndRequestLocationPermission();
    await _getCurrentLocation();
    await _addBranchMarkers();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dịch vụ định vị đã bị tắt. Vui lòng bật để tiếp tục.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn, chúng tôi không thể yêu cầu quyền.')));
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);

      if (mounted) {
        setState(() {
          _userLocation = GeoPoint(latitude: position.latitude, longitude: position.longitude);
        });

        await _mapController.moveTo(_userLocation!);
        await _mapController.setZoom(zoomLevel: 16.0);

        await _mapController.addMarker(
          _userLocation!,
           markerIcon: MarkerIcon(
             iconWidget: _buildUserLocationMarker(),
           ),
        );
      }
    } catch (e) {
      print("Lỗi khi lấy vị trí: $e");
    }
  }

  Future<void> _addBranchMarkers() async {
    for (var i = 0; i < widget.branches.length; i++) {
      var branch = widget.branches[i];
      GeoPoint branchPoint = GeoPoint(latitude: branch.latitude, longitude: branch.longitude);
      try {
        await _mapController.addMarker(
          branchPoint,
          markerIcon: MarkerIcon(
            iconWidget: _buildBranchMarker(),
          ),
        );
        
        // Set static position callback để handle tap
        await _mapController.setStaticPosition(
          [branchPoint],
          "branch_$i",
        );
      } catch (e) {
        print("Lỗi khi thêm marker chi nhánh: $e");
      }
    }
  }

  Future<void> _drawRoute(Branch destinationBranch) async {
    if (_userLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy vị trí của bạn.')),
      );
      return;
    }

    setState(() { _selectedBranch = destinationBranch; });
    _cardAnimationController.forward();

    try {
      await _mapController.clearAllRoads();

      GeoPoint destinationPoint = GeoPoint(
        latitude: destinationBranch.latitude,
        longitude: destinationBranch.longitude,
      );

      // Vẽ đường đi trên bản đồ OSM
      final roadInfo = await _mapController.drawRoad(
        _userLocation!,
        destinationPoint,
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 10,
          roadColor: Colors.blue,
          zoomInto: true,
        ),
      );

      if (!mounted) return;
      
      // Hiển thị thông tin khoảng cách và thời gian
      final distance = roadInfo.distance ?? 0;
      final duration = roadInfo.duration ?? 0;
      
      if (distance > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Khoảng cách: ${(distance / 1000).toStringAsFixed(1)} km - '
              'Thời gian: ${(duration / 60).toStringAsFixed(0)} phút',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi vẽ đường đi: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tìm đường đi. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Chỉ đường trực tiếp trên OSM (không cần Google Maps)
  Future<void> _startNavigation(Branch branch) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy vị trí của bạn.')),
      );
      return;
    }

    await _drawRoute(branch);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản đồ chi nhánh',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0891B2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: _mapController,
            osmOption: OSMOption(
              zoomOption: ZoomOption(
                initZoom: 8,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userTrackingOption: UserTrackingOption(
                enableTracking: false,
              ),
              staticPoints: widget.branches.asMap().entries.map((entry) {
                final branch = entry.value;
                return StaticPositionGeoPoint(
                  "branch_${entry.key}",
                  MarkerIcon(
                    iconWidget: _buildBranchMarker(),
                  ),
                  [
                    GeoPoint(
                      latitude: branch.latitude,
                      longitude: branch.longitude,
                    ),
                  ],
                );
              }).toList(),
            ),
            onGeoPointClicked: (geoPoint) async {
              // Tìm branch tương ứng với marker được tap
              for (var branch in widget.branches) {
                if ((branch.latitude - geoPoint.latitude).abs() < 0.0001 &&
                    (branch.longitude - geoPoint.longitude).abs() < 0.0001) {
                  await _mapController.moveTo(geoPoint);
                  await _mapController.setZoom(zoomLevel: 16.5);
                  await _drawRoute(branch);
                  break;
                }
              }
            },
            mapIsLoading: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  const SizedBox(height: 20),
                  const Text(
                    'Đang tải bản đồ...',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    const SizedBox(height: 20),
                    const Text(
                      'Đang tìm vị trí của bạn...',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildBranchesList(),
          ),

          if (_selectedBranch != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildSelectedBranchCard(),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          onPressed: () {
            if (_userLocation != null) {
              _mapController.moveTo(_userLocation!);
              _mapController.setZoom(zoomLevel: 16.0);
            }
          },
          backgroundColor: Theme.of(context).primaryColor, 
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }
  
  // === PHẦN SỬA LỖI: Sử dụng Stack với kích thước cụ thể ===
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Vòng tròn hào quang bên ngoài
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        // Chấm tròn vị trí ở giữa
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
  // =========================================================

  Widget _buildBranchMarker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.store,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildBranchesList() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _selectedBranch == null ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: _selectedBranch != null,
        child: SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: widget.branches.length,
            itemBuilder: (context, index) {
              final branch = widget.branches[index];
              return GestureDetector(
                onTap: () {
                  _mapController.moveTo(
                    GeoPoint(latitude: branch.latitude, longitude: branch.longitude),
                  );
                  _mapController.setZoom(zoomLevel: 16.5);
                  _drawRoute(branch);
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          branch.image,
                          width: 100,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                branch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                branch.address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedBranchCard() {
    if (_selectedBranch == null) return const SizedBox.shrink();
    return SlideTransition(
      position: _cardAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBranch!.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBranch!.address,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    _cardAnimationController.reverse();
                    _mapController.clearAllRoads();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        _selectedBranch = null;
                      });
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(_selectedBranch!),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Chỉ đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Mở Google Maps làm lựa chọn phụ
                      final lat = _selectedBranch!.latitude;
                      final long = _selectedBranch!.longitude;
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$long';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0891B2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF0891B2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}