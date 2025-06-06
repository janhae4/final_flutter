import 'package:final_flutter/data/models/label_model.dart';

class UserModel {
  final String uid;
  final String phone;
  final String? name;
  final String? email;
  final String? birthdate;
  final String? avatarUrl;
  final bool? twoStepVerification;
  final String? tempToken;
  final List<LabelModel>? labels;

  UserModel({
    required this.uid,
    required this.phone,
    this.name,
    this.email,
    this.birthdate,
    this.avatarUrl,
    this.twoStepVerification,
    this.tempToken,
    this.labels,
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
      tempToken: json['tempToken'],
      labels:
          json['labels'] != null
              ? List<LabelModel>.from(
                json['labels'].map((label) => LabelModel.fromJson(label)),
              )
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'phone': phone};
  }

  UserModel copyWith({
    String? uid,
    String? phone,
    String? name,
    String? email,
    String? birthdate,
    String? avatarUrl,
    bool? twoStepVerification,
    String? tempToken,
    List<LabelModel>? labels,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      birthdate: birthdate ?? this.birthdate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      twoStepVerification: twoStepVerification ?? this.twoStepVerification,
      tempToken: tempToken ?? this.tempToken,
      labels: labels ?? this.labels,
    );
  }
}
