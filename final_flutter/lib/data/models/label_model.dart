class LabelModel {
  final String id;
  final String label;

  LabelModel({
    required this.id,
    required this.label,
  });

  factory LabelModel.fromJson(Map<String, dynamic> json) {
    return LabelModel(
      id: json['_id'] ?? json['id'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'label': label,
    };
  }
}