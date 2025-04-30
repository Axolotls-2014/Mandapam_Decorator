class Version {
  final int? id;
  final String key;
  final String value;
  final dynamic created_at;
  final dynamic updated_at;
  final List<dynamic> storage;

  Version({
    this.id,
    required this.key,
    required this.value,
    this.created_at,
    this.updated_at,
    this.storage = const [],
  });

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      id: json['id'],
      key: json['key'],
      value: json['value'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      storage: json['storage'] != null ? List<dynamic>.from(json['storage']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'created_at': created_at,
      'updated_at': updated_at,
      'storage': storage,
    };
  }
}