class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? name;
  final String?
      profilePhotoBase64; // base64 encoded image with data:image/type;base64, prefix
  final String? profilePhotoType; // MIME type like image/jpeg
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.name,
    this.profilePhotoBase64,
    this.profilePhotoType,
    this.createdAt,
    this.updatedAt,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? json['name'] ?? '',
      email: json['email'],
      role: json['role'],
      name: json['name'],
      profilePhotoBase64: json['profilePhotoBase64'], // Will be set by service
      profilePhotoType: json['profilePhotoType'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'name': name,
      'profilePhotoBase64': profilePhotoBase64,
      'profilePhotoType': profilePhotoType,
    };
  }

  // Helper method to check if user has profile photo
  bool get hasProfilePhoto =>
      profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty;
}
