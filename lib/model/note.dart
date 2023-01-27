import 'package:conduit/conduit.dart';
import 'user.dart';

class Note extends ManagedObject<_Note> implements _Note {}

class _Note {
  @primaryKey
  int? id;
  @Column(nullable: true)
  String? title;
  @Column(nullable: true)
  String? text;
  @Column(nullable: true)
  String? category;
  @Relate(#noteList, isRequired: true, onDelete: DeleteRule.cascade)
  User? author;
  @Column(defaultValue: "now()", indexed: true)
  DateTime? createdAt;
  @Column(nullable: true)
  DateTime? updatedAt;
}