class ProfileModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String bio;
  final String city;
  final List<String> photoUrls;
  final String lookingFor;
  final int minAge;
  final int maxAge;

  const ProfileModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.bio,
    required this.city,
    required this.photoUrls,
    required this.lookingFor,
    required this.minAge,
    required this.maxAge,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'bio': bio,
      'city': city,
      'photoUrls': photoUrls,
      'lookingFor': lookingFor,
      'minAge': minAge,
      'maxAge': maxAge,
      'profileCompleted': true,
    };
  }
}