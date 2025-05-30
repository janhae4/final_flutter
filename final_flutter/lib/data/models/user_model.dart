class UserModel {
  final String uid;
  final String phone;
  final String? name;
  final String? email;
  final String? birthdate;
  final String? avatarUrl;
  final bool? twoStepVerification;
  final String? tempToken;

  UserModel({
    required this.uid,
    required this.phone,
    this.name,
    this.email,
    this.birthdate,
    this.avatarUrl,
    this.twoStepVerification,
    this.tempToken
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['_id'] ?? json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      birthdate: json['birthdate'],
      avatarUrl: json['avatarUrl'],
      twoStepVerification: json['twoStepVerification'],
      tempToken: json['tempToken']
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'phone': phone};
  }
}
