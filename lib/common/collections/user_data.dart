class UserData {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? profilePictureUrl;
  final bool isAppAdmin;
  final List<String> clubsAdminOf;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    required this.isAppAdmin,
    required this.clubsAdminOf,
  });

  factory UserData.fromMap(String uid, Map<String, dynamic> data) {
    return UserData(
      uid: uid,
      name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      isAppAdmin: data['isAppAdmin'] ?? false,
      clubsAdminOf: List<String>.from(data['clubsAdminOf'] ?? []),
    );
  }

  bool isClubAdmin(String clubId) => clubsAdminOf.contains(clubId);
}
