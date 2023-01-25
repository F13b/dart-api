import 'package:conduit/conduit.dart';
import 'category.dart';

class Note extends ManagedObject<_Note> implements _Note {}

class _Note {
  @primaryKey
  int? id;
  @Column(nullable: true)
  String? title;
  @Column(nullable: true)
  String? text;
  @Relate(#category, isRequired: true, onDelete: DeleteRule.cascade)
  Category? category;
  DateTime? createdAt;
  DateTime? updatedAt;
}