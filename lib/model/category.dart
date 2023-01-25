import 'package:api_project/model/note.dart';
import 'package:conduit/conduit.dart';

class Category extends ManagedObject<_Category> implements _Category {}

class _Category {
  @primaryKey
  int? id;
  @Column(unique: true, nullable: false, indexed: true)
  String? categoryName;

  ManagedSet<Note>? category;
}