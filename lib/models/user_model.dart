// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final List<String> favoriteRoutes;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.favoriteRoutes = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:            doc.id,
      name:           data['name'] ?? '',
      email:          data['email'] ?? '',
      favoriteRoutes: List<String>.from(data['favoriteRoutes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name':           name,
      'email':          email,
      'favoriteRoutes': favoriteRoutes,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid:            json['uid'] ?? '',
      name:           json['name'] ?? '',
      email:          json['email'] ?? '',
      favoriteRoutes: List<String>.from(json['favoriteRoutes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid':            uid,
      'name':           name,
      'email':          email,
      'favoriteRoutes': favoriteRoutes,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    List<String>? favoriteRoutes,
  }) {
    return UserModel(
      uid:            uid ?? this.uid,
      name:           name ?? this.name,
      email:          email ?? this.email,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
    );
  }
}
