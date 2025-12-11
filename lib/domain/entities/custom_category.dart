/// Custom category entity for user-defined link categories
class CustomCategory {
  final int? id;
  final String name;
  final String? iconName;
  final int colorValue;
  final DateTime createdAt;

  CustomCategory({
    this.id,
    required this.name,
    this.iconName,
    required this.colorValue,
    required this.createdAt,
  });

  CustomCategory copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
