import 'package:cloud_firestore/cloud_firestore.dart';

/// User Profile Model
/// Firestore path: users/{userId}
class UserProfileModel {
  final String userId;
  final String name;
  final String phone;
  final String city;
  final String province;
  final String address;
  final String profilePhotoBase64;
  final List<String> enteredTournaments;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.city,
    required this.province,
    required this.address,
    this.profilePhotoBase64 = '',
    this.enteredTournaments = const [],
    this.updatedAt,
  });

  factory UserProfileModel.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfileModel(
      userId: userId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      address: map['address'] ?? '',
      profilePhotoBase64: map['profilePhotoBase64'] ?? '',
      enteredTournaments:
          List<String>.from(map['enteredTournaments'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'city': city,
      'province': province,
      'address': address,
      'profilePhotoBase64': profilePhotoBase64,
      'enteredTournaments': enteredTournaments,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? phone,
    String? city,
    String? province,
    String? address,
    String? profilePhotoBase64,
    List<String>? enteredTournaments,
  }) {
    return UserProfileModel(
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      province: province ?? this.province,
      address: address ?? this.address,
      profilePhotoBase64: profilePhotoBase64 ?? this.profilePhotoBase64,
      enteredTournaments: enteredTournaments ?? this.enteredTournaments,
      updatedAt: updatedAt,
    );
  }
}