<h1 align="center">Stormberry</h1>

<p align="center">
  <a href="https://pub.dev/packages/stormberry">
    <img src="https://img.shields.io/pub/v/stormberry?label=pub.dev&labelColor=333940&logo=dart&color=00589B">
  </a>
  <a href="https://github.com/schultek/stormberry/actions/workflows/test.yaml">
    <img src="https://img.shields.io/github/actions/workflow/status/schultek/stormberry/test.yaml?branch=main&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://app.codecov.io/gh/schultek/stormberry">
    <img src="https://img.shields.io/codecov/c/github/schultek/stormberry?logo=codecov&logoColor=fff&labelColor=333940">
  </a>
  <br/>
  <a href="https://twitter.com/schultek_dev">
    <img src="https://img.shields.io/badge/follow-%40schultek__dev-1DA1F2?style=flat&label=follow&color=1DA1F2&labelColor=333940&logo=twitter&logoColor=fff">
  </a>
  <a href="https://github.com/schultek/stormberry">
    <img src="https://img.shields.io/github/stars/schultek/stormberry?style=flat&label=stars&labelColor=333940&color=8957e5&logo=github">
  </a>
</p>

<p align="center">
A <b>strongly-typed postgres ORM</b> to provide easy bindings between your dart classes and postgres database. 
It supports all kinds of <b>relations without any complex configuration</b>.
</p>

---

# Quick Start

To get started, add `stormberry` as a dependency and `build_runner` as a dev dependency:

```shell
dart pub add stormberry
dart pub add build_runner --dev
```

In your code, specify an abstract class that should act as a table like this:

```dart
// This file is "model.dart"
import 'package:stormberry/stormberry.dart';

// Will be generated by stormberry
part 'model.schema.dart';

@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
}
```

In order to generate the database code, run the following command:

```shell script
dart run build_runner build
```

***Tip**: You'll need to re-run code generation each time you are making changes to your models.
During development, you can use `watch` to automatically watch your changes: `dart pub run build_runner watch`.*

This will generate a `.schema.dart` file that you should add as a `part` to the original model file.

---

Before running your application, you have to migrate your database. To do this run:

```shell
dart run stormberry migrate
```

This will ask you for the connection details of your postgres database and then migrate
the database schema by adding the `users` table.

---

To access your database from your application, create a `Database` instance and use the `users`
repository like this:

```dart
void main() async {
  
  var db = Database(
    // connection parameters go here
  );
  
  // adds a user to the 'users' table
  await db.users.insertOne(UserInsertRequest(id: 'abc', name: 'Alex'));
  
  // finds a user by its 'id'
  var user = await db.users.queryUser('abc');
  
  assert(user.name == 'Alex');
}
```

## Full Documentation

See the full documentation [here](https://pub.dev/documentation/stormberry/latest/topics/Introduction-topic.html)
or jump directly to the topic you are looking for:

- [**Models**](https://pub.dev/documentation/stormberry/latest/topics/Models-topic.html)
- [**Views**](https://pub.dev/documentation/stormberry/latest/topics/Views-topic.html)
- [**Database**](https://pub.dev/documentation/stormberry/latest/topics/Database-topic.html)
- [**Repositories**](https://pub.dev/documentation/stormberry/latest/topics/Repositories-topic.html)
- [**Queries & Actions**](https://pub.dev/documentation/stormberry/latest/topics/Queries%20&%20Actions-topic.html)
- [**Migration**](https://pub.dev/documentation/stormberry/latest/topics/Migration-topic.html)


