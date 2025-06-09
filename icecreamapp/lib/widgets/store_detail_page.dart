import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class StoreDetailPage extends StatefulWidget {
  final StoreLocation store;

  const StoreDetailPage({Key? key, required this.store}) : super(key: key);

  @override
  _StoreDetailPageState createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  String _selectedTimezone = "WIB";
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<String> _timezones = [
    "WIB",
    "WITA",
    "WIT",
    "Europe/London",
    "Asia/Tokyo",
    "America/New_York"
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimezone = widget.store.timeZoneIdentifier ?? "WIB";
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _locationService.isStoreOpen(widget.store);
    final currentStoreTime =
        _locationService.getCurrentTimeInStoreTimezone(widget.store);
    final convertedHours =
        _locationService.convertOpeningHours(widget.store, _selectedTimezone);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink[50]!, Colors.orange[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Column(
              children: [
                _buildHeader(isOpen),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStoreInfo(currentStoreTime),
                        const SizedBox(height: 16),
                        _buildOpeningHours(convertedHours),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isOpen) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[400]!, Colors.orange[400]!],
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              Expanded(
                child: Text(
                  widget.store.name ?? "Store Detail",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? "OPEN" : "CLOSED",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${widget.store.city ?? 'Unknown'}, ${widget.store.country ?? 'Unknown'}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.store.description ?? "No description available",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(String currentStoreTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.pink[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                "Store Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(Icons.location_on, "Address",
              widget.store.address ?? "Address not available"),
          _buildInfoItem(Icons.phone, "Phone",
              widget.store.phoneNumber ?? "Phone not available"),
          _buildInfoItem(Icons.email, "Email",
              widget.store.email ?? "Email not available"),
          _buildInfoItem(Icons.public, "Timezone",
              widget.store.timeZoneIdentifier ?? "Unknown"),
          _buildInfoItem(Icons.access_time, "Local Time", currentStoreTime),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.pink[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHours(String convertedHours) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                "Opening Hours",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("Show in timezone: ", style: TextStyle(fontSize: 16)),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimezone,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimezone = newValue;
                          });
                        }
                      },
                      items: _timezones
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.orange[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange[600]),
                const SizedBox(width: 12),
                Text(
                  convertedHours,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text("($_selectedTimezone)",
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                "Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.call,
                  label: "Call",
                  color: Colors.green,
                  onPressed: _callStore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.email,
                  label: "Email",
                  color: Colors.orange,
                  onPressed: _emailStore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.directions,
              label: "Get Directions",
              color: Colors.blue,
              onPressed: _openRoute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  void _callStore() async {
    final phoneNumber = widget.store.phoneNumber;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        final Uri phoneUri = Uri.parse("tel:$phoneNumber");
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          _showSnackBar("Cannot open phone app");
        }
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    } else {
      _showSnackBar("Phone number not available");
    }
  }

  void _emailStore() async {
    final email = widget.store.email;
    if (email != null && email.isNotEmpty) {
      try {
        final Uri emailUri = Uri.parse("mailto:$email");
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          _showSnackBar("Cannot open email app");
        }
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    } else {
      _showSnackBar("Email not available");
    }
  }

  void _openRoute() async {
    try {
      await _locationService.launchRouteInMapApp(
        widget.store.latitude,
        widget.store.longitude,
      );
    } catch (e) {
      _showSnackBar("Error opening route: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.pink[400],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
