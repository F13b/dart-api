import 'dart:io';

import 'package:api_project/model/model_response.dart';
import 'package:api_project/model/note.dart';
import 'package:api_project/model/user.dart';
import 'package:api_project/utils/api_utils.dart';
import 'package:api_project/utils/app_response.dart';
import 'package:conduit/conduit.dart';

class AppNoteController extends ResourceController {
  AppNoteController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get("page")
  Future<Response> getNotes(
    @Bind.path("page") int page, @Bind.header(HttpHeaders.authorizationHeader) String header
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);

      final qGetNotes = Query<Note>(managedContext)
        ..where((x) => x.author!.id).equalTo(id)
        ..offset = (page - 1) * 20
        ..fetchLimit = 20;

      final List<Note> list = await qGetNotes.fetch();

      if(list.isEmpty) return Response.notFound(body: ModelResponse(data: [], message: "Нет заметок"));

      final data = list.map((e) => e.asMap()).toList();

      return Response.ok(data);
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.post()
  Future<Response> createNote(@Bind.header(HttpHeaders.authorizationHeader) String header, @Bind.body() Note note) async {
    try {
      if (note.title!.isEmpty || note.text!.isEmpty) return Response.serverError(body: "Не все данные заполнены");

      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<User>(id);
      if (author == null) return Response.serverError(body: "У вас нет прав на создание заметки");

      final qCreateNote = Query<Note>(managedContext)
        ..values.title = note.title
        ..values.text = note.text
        ..values.category = note.category
        ..values.author!.id = id
        ..values.createdAt = DateTime.now();

      await qCreateNote.insert();

      return AppResponse.ok(message: "Заметка создана");
      
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.get()
  Future<Response> searchNotes (
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    {@Bind.query('name') String? title}
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<User>(id);
      if (author == null) return Response.serverError(body: "У вас нет прав");

      final qSearchNotes = Query<Note>(managedContext)
        ..where((x) => x.title).contains(title ?? '')
        ..where((x) => x.author!.id).equalTo(id);
      final List<Note> list = await qSearchNotes.fetch();
      if(list.isEmpty) return Response.notFound(body: ModelResponse(data: [], message: "Нет заметок"));

      final data = list.map((e) => e.asMap()).toList();

      return Response.ok(data);
    } on QueryException catch (e) {
      return Response.serverError(body: e.response.body);
    }
  }

  @Operation.put("page")
  Future<Response> updateNote(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("page") int noteID,
    @Bind.body() Note updNote
  ) async {
    try {
      final userId = AppUtils.getIdFromHeader(header);
      final note = await managedContext.fetchObjectWithID<Note>(noteID);
      if (note == null) return Response.serverError(body: "Заметка не найдена");
      if (note.author?.id != userId) return Response.serverError(body: "Нет прав для удаления заметки");
      final qUpdatePost = Query<Note>(managedContext)
        ..where((x) => x.id).equalTo(noteID)
        ..values.title = updNote.title
        ..values.text = updNote.text
        ..values.category = updNote.category
        ..values.updatedAt = DateTime.now();
      await qUpdatePost.updateOne();
      return AppResponse.ok(message: "Заметка обновлена");
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.delete("page")
  Future<Response> deleteNote(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("page") int id
  ) async {
    try {
      final userId = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(userId);
      if (user == null) return Response.serverError(body: "У вас нет прав");
      final note = await managedContext.fetchObjectWithID<Note>(id);
      if (note?.author?.id != userId) return Response.serverError(body: "Нет доступа к посту");
      final qDeleteNote = Query<Note>(managedContext)
        ..where((x) => x.id).equalTo(id);
      await qDeleteNote.delete();
      return AppResponse.ok(message: "Заметка удалена");        
    } on QueryException catch (e) {
      return Response.serverError(body: e.response.body);
    }
  }
}