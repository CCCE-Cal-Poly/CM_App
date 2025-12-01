import 'package:cloud_functions/cloud_functions.dart';

enum UserRole { admin, clubAdmin, student, faculty }
extension UserRoleExtension on UserRole {
  String enumToString() {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.clubAdmin:
        return 'Club Admin';
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty';
    }
  }
}

class UserData {
  final String uid;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final List<String> clubsAdminOf;
  final UserRole role;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    required this.clubsAdminOf,
    required this.role,
  });

  factory UserData.fromMap(String uid, Map<String, dynamic> data) {
    return UserData(
      uid: uid,
      name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      clubsAdminOf: List<String>.from(data['clubsAdminOf'] ?? []),
      role: (data['role'] is String) ? (data['role'] as String).toEnum() : data['role'] ?? 'unknown role',
    );
  }

  bool isClubAdmin(String clubId) => clubsAdminOf.contains(clubId);
}

extension on String {
  UserRole toEnum() {
    switch (this.toLowerCase()){
      case('student') : return UserRole.student;
      case('admin') : return UserRole.admin;
      case('faculty') : return UserRole.faculty;
      case('club admin') : return UserRole.clubAdmin;
      default : return UserRole.student;
    }
  }
}

Future<void> setUserRole(String uid, String role, [List<String>? clubs]) async {
  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
  final payload = <String, dynamic>{'uid': uid, 'role': role};
  if (clubs != null) payload['clubs'] = clubs;
  final result = await callable.call(payload);
  print(result.data);
}
