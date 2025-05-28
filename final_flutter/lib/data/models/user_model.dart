class UserModel {
  final String uid;
  final String phone;

  UserModel({required this.uid, required this.phone});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(uid: json['_id'] ?? json['id'], phone: json['phone']);
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'phone': phone};
  }
}
