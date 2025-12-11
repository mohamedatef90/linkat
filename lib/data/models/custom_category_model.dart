import 'package:isar/isar.dart';
import '../../domain/entities/custom_category.dart';

part 'custom_category_model.g.dart';

@collection
class CustomCategoryModel {
  Id id = Isar.autoIncrement;

  late String name;
  String? iconName;
  late int colorValue;
  late DateTime createdAt;

  CustomCategory toEntity() {
    return CustomCategory(
      id: id,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      createdAt: createdAt,
    );
  }

  static CustomCategoryModel fromEntity(CustomCategory category) {
    return CustomCategoryModel()
      ..id = category.id ?? Isar.autoIncrement
      ..name = category.name
      ..iconName = category.iconName
      ..colorValue = category.colorValue
      ..createdAt = category.createdAt;
  }
}
