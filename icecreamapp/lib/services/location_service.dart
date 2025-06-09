import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class StoreLocation {
  final String? name;
  final String? city;
  final String? country;
  final double latitude; // Remove nullable since these are required
  final double longitude; // Remove nullable since these are required
  final String? timeZoneIdentifier;
  final String? address;
  final String? description;
  final String? openingHours;
  final String? phoneNumber;
  final String? email;
  final bool isActive;

  StoreLocation({
    this.name,
    this.city,
    this.country,
    required this.latitude, // Keep required
    required this.longitude, // Keep required
    this.timeZoneIdentifier,
    this.address,
    this.description,
    this.openingHours,
    this.phoneNumber,
    this.email,
    this.isActive = true,
  });
}

class LocationService {
  // Lokasi statis toko
  final List<StoreLocation> _storeLocations = [
    StoreLocation(
        name: "Ice Cream Jogja",
        city: "Yogyakarta",
        country: "Indonesia",
        latitude: -7.7956,
        longitude: 110.3695,
        timeZoneIdentifier: "WIB",
        address: "Jl. Malioboro No. 123, Yogyakarta",
        description:
            "Toko es krim terbaik di Yogyakarta dengan berbagai rasa tradisional",
        openingHours: "08:00-22:00",
        phoneNumber: "+62274123456",
        email: "jogja@icecream.com"),
    StoreLocation(
        name: "Ice Cream Jakarta",
        city: "Jakarta",
        country: "Indonesia",
        latitude: -6.2088,
        longitude: 106.8456,
        timeZoneIdentifier: "WIB",
        address: "Jl. Thamrin No. 456, Jakarta Pusat",
        description: "Flagship store dengan koleksi rasa premium dan modern",
        openingHours: "09:00-23:00",
        phoneNumber: "+62211234567",
        email: "jakarta@icecream.com"),
    StoreLocation(
        name: "Ice Cream Papua (WIT)",
        city: "Jayapura",
        country: "Indonesia",
        latitude: -2.5307,
        longitude: 140.7140,
        timeZoneIdentifier: "WIT",
        address: "Jl. Ahmad Yani No. 789, Jayapura",
        description: "Es krim segar dengan sentuhan rasa lokal Papua",
        openingHours: "07:00-21:00",
        phoneNumber: "+62967123456",
        email: "papua@icecream.com"),
    StoreLocation(
        name: "Ice Cream Bali (WITA)",
        city: "Denpasar",
        country: "Indonesia",
        latitude: -8.6705,
        longitude: 115.2126,
        timeZoneIdentifier: "WITA",
        address: "Jl. Sunset Road No. 321, Denpasar",
        description: "Es krim tropical dengan view sunset yang menawan",
        openingHours: "10:00-24:00",
        phoneNumber: "+62361123456",
        email: "bali@icecream.com"),
    StoreLocation(
        name: "Ice Cream London",
        city: "London",
        country: "UK",
        latitude: 51.5074,
        longitude: -0.1278,
        timeZoneIdentifier: "Europe/London",
        address: "123 Oxford Street, London",
        description: "Classic British ice cream with international flavors",
        openingHours: "09:00-21:00",
        phoneNumber: "+442071234567",
        email: "london@icecream.com"),
    StoreLocation(
        name: "Ice Cream Tokyo",
        city: "Tokyo",
        country: "Japan",
        latitude: 35.6895,
        longitude: 139.6917,
        timeZoneIdentifier: "Asia/Tokyo",
        address: "1-1-1 Shibuya, Tokyo",
        description:
            "Artisan ice cream with Japanese matcha and seasonal flavors",
        openingHours: "08:00-20:00",
        phoneNumber: "+81312345678",
        email: "tokyo@icecream.com"),
    StoreLocation(
        name: "Ice Cream New York",
        city: "New York",
        country: "US",
        latitude: 40.7128,
        longitude: -74.0060,
        timeZoneIdentifier: "America/New_York",
        address: "456 5th Avenue, New York",
        description: "Premium ice cream in the heart of Manhattan",
        openingHours: "07:00-23:00",
        phoneNumber: "+12129876543",
        email: "newyork@icecream.com"),
  ];

  List<StoreLocation> getStoreLocations() {
    return _storeLocations;
  }

  // Mendapatkan lokasi terkini pengguna
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Layanan lokasi tidak aktif, jangan lanjutkan.
      // Mungkin tampilkan pesan ke pengguna.
      print("Location services are disabled.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin ditolak, jangan lanjutkan.
        print("Location permissions are denied.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Izin ditolak permanen, arahkan pengguna ke pengaturan.
      print(
          "Location permissions are permanently denied, we cannot request permissions.");
      return null;
    }

    // Ketika izin sudah diberikan.
    return await Geolocator.getCurrentPosition();
  }

  // Membuat rute menggunakan TomTom (via URL Launch)
  // Anda perlu API Key TomTom jika ingin menggunakan API rute mereka secara langsung.
  // Untuk membuka di aplikasi peta:
  Future<void> launchRouteInMapApp(
      double destinationLatitude, double destinationLongitude,
      {Position? startLocation}) async {
    Position? currentPos = startLocation ?? await getCurrentLocation();
    String url;

    if (currentPos != null) {
      // Rute dari lokasi terkini ke tujuan
      // TomTom URL:
      // url = 'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
      url =
          'tomtomgo://route?daddr=$destinationLatitude,$destinationLongitude&saddr=${currentPos.latitude},${currentPos.longitude}&nav=drive';

      // Alternatif: Google Maps URL (lebih umum terinstall)
      // url = 'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
    } else {
      // Hanya tampilkan lokasi tujuan jika lokasi saat ini tidak tersedia
      // url = 'https://www.google.com/maps/search/?api=1&query=$destinationLatitude,$destinationLongitude';
      url =
          'tomtomgo://map?center=$destinationLatitude,$destinationLongitude&zoom=15';
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Jika TomTom Go tidak terinstall, coba Google Maps atau buka di browser
      String fallbackUrl;
      if (currentPos != null) {
        fallbackUrl =
            'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
      } else {
        fallbackUrl =
            'https://www.google.com/maps/search/?api=1&query=$destinationLatitude,$destinationLongitude';
      }
      final Uri fallbackUri = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url or $fallbackUrl';
      }
    }
  }

  int _getTimezoneOffset(String? timeZoneIdentifier) {
    final timeZone = timeZoneIdentifier ?? "WIB";
    switch (timeZone) {
      case "WIB":
        return 7; // UTC+7
      case "WITA":
        return 8; // UTC+8
      case "WIT":
        return 9; // UTC+9
      case "Europe/London":
        return 0; // UTC+0 (GMT)
      case "Asia/Tokyo":
        return 9; // UTC+9
      case "America/New_York":
        return -5; // UTC-5 (EST)
      default:
        return 7; // Default to WIB (UTC+7)
    }
  }

  // Convert opening hours to different time zones
  String convertOpeningHours(StoreLocation store, String targetTimeZone) {
    final openingHours = store.openingHours;
    if (openingHours == null) return "Hours not available";

    final storeHours = openingHours.split('-');
    if (storeHours.length != 2) return openingHours;

    final openTime = storeHours[0];
    final closeTime = storeHours[1];

    // Get timezone offset differences
    final storeOffset = _getTimezoneOffset(store.timeZoneIdentifier);
    final targetOffset = _getTimezoneOffset(targetTimeZone);
    final hourDifference = targetOffset - storeOffset;

    // Convert times
    final convertedOpenTime = _convertTime(openTime, hourDifference);
    final convertedCloseTime = _convertTime(closeTime, hourDifference);

    return "$convertedOpenTime-$convertedCloseTime";
  }

  String _convertTime(String time, int hourDifference) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    hour += hourDifference;

    // Handle day overflow
    if (hour >= 24) {
      hour -= 24;
    } else if (hour < 0) {
      hour += 24;
    }

    return "${hour.toString().padLeft(2, '0')}:$minute";
  }

  // Get current time in store's timezone
  String getCurrentTimeInStoreTimezone(StoreLocation store) {
    final now = DateTime.now();
    final storeOffset = _getTimezoneOffset(store.timeZoneIdentifier);
    final localOffset = now.timeZoneOffset.inHours;
    final hourDifference = storeOffset - localOffset;

    final storeTime = now.add(Duration(hours: hourDifference));
    return "${storeTime.hour.toString().padLeft(2, '0')}:${storeTime.minute.toString().padLeft(2, '0')}";
  }

  // Check if store is currently open
  bool isStoreOpen(StoreLocation store) {
    final openingHours = store.openingHours;
    if (openingHours == null) return false;

    final currentTime = getCurrentTimeInStoreTimezone(store);
    final storeHours = openingHours.split('-');

    if (storeHours.length != 2) return false;

    final openTime = storeHours[0];
    final closeTime = storeHours[1];

    return _isTimeBetween(currentTime, openTime, closeTime);
  }

  bool _isTimeBetween(String currentTime, String openTime, String closeTime) {
    final current = _timeToMinutes(currentTime);
    final open = _timeToMinutes(openTime);
    final close = _timeToMinutes(closeTime);

    if (close < open) {
      // Store closes after midnight
      return current >= open || current <= close;
    } else {
      return current >= open && current <= close;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }
}
