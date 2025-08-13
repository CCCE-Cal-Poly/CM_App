enum UserRole { admin, clubAdmin, student, faculty }

class UserData {
  final String uid;
  final String name;
  final bool isAppAdmin;
  final List<String> clubsAdminOf;
  final UserRole role;

  UserData({
    required this.uid,
    required this.name,
    required this.isAppAdmin,
    required this.clubsAdminOf,
    required this.role,
  });

  factory UserData.fromMap(String uid, Map<String, dynamic> data) {
    return UserData(
      uid: uid,
      name: data['firstName'] + ' ' + data['lastName'] ?? '',
      isAppAdmin: data['isAppAdmin'] ?? false,
      clubsAdminOf: List<String>.from(data['clubsAdminOf'] ?? []),
      role: data['role'] ?? 'unknown role',
    );
  }

  bool isClubAdmin(String clubId) => clubsAdminOf.contains(clubId);
}