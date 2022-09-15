import 'models.dart';

Future<void> main() async {
  var user = DefaultUserView(id: 'abc', name: 'Tom', securityNumber: '12345');

  print(user.toJson());
  print(Mapper.asString(user.copyWith(name: 'Alex')));

  var company = DefaultCompanyView(id: '01', member: PublicUserView(id: 'def', name: 'Susan'));

  print(company.toJson());

  var request = UserUpdateRequest(id: 'abc', securityNumber: '007');
  print(request.toJson());
}
