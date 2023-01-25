
import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:api_project/model/user.dart';
import 'package:api_project/utils/app_response.dart';
import 'package:api_project/utils/api_utils.dart';

class AppUserControllers extends ResourceController {
  AppUserControllers(this.managedContext);
  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      final id = AppUtils.getIdFromToken(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      return AppResponse.ok(
          message: 'Succful taken user profile', body: user.backing.contents);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Error to taken user profile');
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user,
  ) async {
    try {
      final id = AppUtils.getIdFromToken(header);
      final fUser = await managedContext.fetchObjectWithID<User>(id);
      final qUpdateUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.username = user.username ?? fUser!.username
        ..values.email = user.email ?? fUser!.email;
      await qUpdateUser.updateOne();
      final findUser = await managedContext.fetchObjectWithID<User>(id);
      findUser!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      return AppResponse.ok(
        message: 'Succful update',
        body: findUser.backing.contents,
      );
    } catch (e) {
      return AppResponse.serverError(e, message: 'Error update');
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query('newPassword') String newPassword,
    @Bind.query('oldPassword') String oldPassword,
  ) async {
    try {
      final id = AppUtils.getIdFromToken(header);
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..returningProperties(
          (element) => [
            element.salt,
            element.hashPassword,
          ],
        );
      //Данные одного пользователя
      final fUser = await qFindUser.fetchOne();
      //Хеш старого пароля
      final oldHashPassword =
          generatePasswordHash(oldPassword, fUser!.salt ?? "");

      //Проверка старого пароля с паролем бдшки
      if (oldHashPassword != fUser.hashPassword) {
        return AppResponse.badrequest(message: 'Not true last password');
      }

      //Новый хеш пароля
      final newHashPassword =
          generatePasswordHash(newPassword, fUser.salt ?? "");

      //Запрос на обновление
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newHashPassword;

      await qUpdateUser.fetchOne();

      return AppResponse.ok(body: 'Succ password change');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Error updating password');
    }
  }
}
