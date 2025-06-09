import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:icecreamapp/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/store_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  List<StoreLocation> _storeLocations = [];
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _showRoute = false;
  StoreLocation? _selectedStore;
  String _routeInfo = "";
  bool _isMapExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _storeLocations = _locationService.getStoreLocations();
    await _getCurrentUserLocation();
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      Position? position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
      } else if (mounted) {
        _showSnackBar(
            "Could not get current location. Showing default map view.");
      }
    } catch (e) {
      print("Error getting current location: $e");
      if (mounted) {
        _showSnackBar("Error getting location: $e");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.pink[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _calculateRoute(StoreLocation store) async {
    if (_currentPosition == null) {
      if (mounted) {
        _showSnackBar("Your location not found yet");
      }
      return;
    }

    setState(() {
      _selectedStore = store;
      _showRoute = true;
      _routeInfo = "Calculating route...";
    });

    try {
      bool routeFound = false;

      if (!routeFound) {
        routeFound = await _tryOSRM(store);
      }

      if (!routeFound) {
        _createStraightLineRoute(store);
      }
    } catch (e) {
      print("Error calculating route: $e");
      if (mounted) {
        _createStraightLineRoute(store);
      }
    }
  }

  Future<bool> _tryOSRM(StoreLocation store) async {
    if (_currentPosition == null) return false;

    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/${_currentPosition!.longitude},${_currentPosition!.latitude};${store.longitude},${store.latitude}';

      final response = await http.get(
        Uri.parse('$url?overview=full&geometries=geojson'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']?['coordinates'] as List?;

          if (coordinates != null && mounted) {
            setState(() {
              _routePoints = coordinates
                  .map<LatLng>((coord) => LatLng(
                      coord[1]?.toDouble() ?? 0.0, coord[0]?.toDouble() ?? 0.0))
                  .toList();

              final distance =
                  ((route['distance'] ?? 0) / 1000).toStringAsFixed(1);
              final duration =
                  ((route['duration'] ?? 0) / 60).toStringAsFixed(0);
              _routeInfo =
                  "Distance: ${distance} km, Time: ${duration} minutes";
            });

            _fitMapToRoute();
            return true;
          }
        }
      }
    } catch (e) {
      print("OSRM failed: $e");
    }
    return false;
  }

  void _createStraightLineRoute(StoreLocation store) {
    if (_currentPosition == null || !mounted) return;

    setState(() {
      _routePoints = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(store.latitude, store.longitude)
      ];

      final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            store.latitude,
            store.longitude,
          ) /
          1000;

      _routeInfo =
          "Estimated distance: ${distance.toStringAsFixed(1)} km (straight line)";
    });

    _fitMapToRoute();
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty || !mounted) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    try {
      _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    } catch (e) {
      print("Error fitting map to route: $e");
    }
  }

  void _clearRoute() {
    if (!mounted) return;

    setState(() {
      _routePoints.clear();
      _showRoute = false;
      _selectedStore = null;
      _routeInfo = "";
    });
  }

  void _toggleMapSize() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink[50]!,
                Colors.purple[50]!,
                Colors.blue[50]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(10, (index) => _buildParticle(index, size)),

              // Loading content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading Ice Cream Stores...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[50]!,
              Colors.purple[50]!,
              Colors.blue[50]!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(12, (index) => _buildParticle(index, size)),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    if (_showRoute && _routeInfo.isNotEmpty) _buildRouteInfo(),
                    _buildMapSection(),
                    _buildStoresSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = (index * 1234567) % 100;
    final left = (random / 100) * size.width;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final progress = (_fadeAnimation.value + (random / 100)) % 1.0;
        final top = size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.05 + (0.1 * (1 - progress)),
            child: Container(
              width: 3 + (random % 2),
              height: 3 + (random % 2),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.pink[300] : Colors.purple[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.icecream, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ice Cream Stores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Find your favorite ice cream nearby',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _getCurrentUserLocation,
              tooltip: 'Get My Location',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _routeInfo,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_selectedStore != null)
                  Text(
                    "To: ${_selectedStore!.name ?? 'Unknown Store'}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearRoute,
            color: Colors.red.shade600,
            tooltip: 'Close Route',
          ),
        ],
      ),
    );
  }

  Widget _buildStoresSection() {
    return Expanded(
      flex: _isMapExpanded ? 1 : 2,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade100, Colors.orange.shade100],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.store_mall_directory,
                      color: Colors.pink.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Ice Cream Stores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_storeLocations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _storeLocations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _storeLocations.length,
                      itemBuilder: (context, index) =>
                          _buildStoreCard(_storeLocations[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(StoreLocation store) {
    final isSelected = _selectedStore == store;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  Colors.orange[50] ?? Colors.orange.shade50,
                  Colors.orange[100] ?? Colors.orange.shade100
                ]
              : [Colors.white, Colors.pink[25] ?? Colors.pink.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (Colors.orange[300] ?? Colors.orange.shade300)
              : (Colors.grey[200] ?? Colors.grey.shade200),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? Colors.orange : Colors.pink).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          Colors.orange[400] ?? Colors.orange.shade400,
                          Colors.orange[600] ?? Colors.orange.shade600
                        ]
                      : [
                          Colors.pink[400] ?? Colors.pink.shade400,
                          Colors.pink[600] ?? Colors.pink.shade600
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.storefront, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name ?? 'Unknown Store',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? (Colors.orange[800] ?? Colors.orange.shade800)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.city ?? 'Unknown'}, ${store.country ?? 'Unknown'}',
                    style: TextStyle(
                        color: Colors.grey[600] ?? Colors.grey.shade600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Timezone: ${store.timeZoneIdentifier ?? 'Unknown'}',
                    style: TextStyle(
                        color: Colors.grey[500] ?? Colors.grey.shade500,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildActionButton(
                  icon:
                      _selectedStore == store ? Icons.close : Icons.directions,
                  color: _selectedStore == store ? Colors.red : Colors.green,
                  onPressed: () {
                    if (_selectedStore == store) {
                      _clearRoute();
                    } else {
                      _calculateRoute(store);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreDetailPage(store: store),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showRoute)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "clearRoute",
              onPressed: _clearRoute,
              backgroundColor: Colors.transparent,
              elevation: 0,
              mini: true,
              child: const Icon(Icons.clear, color: Colors.white),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.pink.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "myLocation",
            onPressed: _getCurrentUserLocation,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Expanded(
      flex: _isMapExpanded ? 4 : 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)
                      : _storeLocations.isNotEmpty
                          ? LatLng(_storeLocations[0].latitude,
                              _storeLocations[0].longitude)
                          : const LatLng(-7.7956, 110.3695),
                  initialZoom: _currentPosition != null ? 13.0 : 5.0,
                  minZoom: 3,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.ice_cream_app',
                  ),
                  if (_showRoute && _routePoints.isNotEmpty) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 8.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: _routeInfo.contains("straight line")
                              ? Colors.orange.shade600
                              : Colors.pink.shade500,
                        ),
                      ],
                    ),
                  ],
                  MarkerLayer(
                    markers: [
                      if (_currentPosition != null)
                        Marker(
                          width: 60.0,
                          height: 60.0,
                          point: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.my_location,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ..._storeLocations.map((store) {
                        final isSelected = _selectedStore == store;
                        return Marker(
                          width: 60.0,
                          height: 60.0,
                          point: LatLng(store.latitude, store.longitude),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StoreDetailPage(store: store),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600
                                        ]
                                      : [
                                          Colors.pink.shade400,
                                          Colors.pink.shade600
                                        ],
                                ),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected
                                            ? Colors.orange
                                            : Colors.pink)
                                        .withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.store,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(_isMapExpanded
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen),
                  onPressed: _toggleMapSize,
                  color: Colors.pink.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No store locations available.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
