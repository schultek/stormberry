# Stormberry

Stormberry is a strongly-typed ORM-like code-generation package to provide easy bindings between
your dart classes and postgres database. It supports all kinds of relations without any complex
configuration.

# Outline

- [Get Started](#get-started)
- [Setup](#setup)
  - [Models](#models)
    - [Relations](#relations)
  - [Views](#views)
  - [Indexes](#indexes)
  - [TypeConverters](#typeconverters)
- [Usage](#usage)
  - [Repositories](#repositories)
  - [Queries](#queries)
  - [Actions](#actions)
- [Database Migration](#database-migration)

> This package is still in active development. If you have any feedback or feature requests,
> write me and issue on github.

## Roadmap

- Documentation
  - Improve Readme
  - Improve example
- Testing & Maintenance
  - Improve code structure
  - Write tests
- Long Term
  - Be database agnostic (sub-packages)

# Get Started

To get started, add `stormberry` as a dependency and `build_runner` as a dev dependency:

```shell
dart pub add stormberry
dart pub add build_runner --dev
```

In your code, specify an abstract class that should act as a table like this:

```dart
@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
}
```

Next, create a `build.yaml` in the root directory of your package and add this snippet:

```yaml
targets:
  $default:
    builders:
      stormberry:
        generate_for:
          # library that exposes all your table classes
          # modify this if to match your library file
          - lib/models.dart
```

In order to generate the serialization code, run the following command:

```shell script
dart pub run build_runner build
```

You'll need to re-run code generation each time you are making changes to your code. So for development time, use `watch` like this

```shell script
dart pub run build_runner watch
```

This will generate a `.schema.g.dart` file.

Last step is to `import` the generated dart file wherever you want / need them.

# Setup

## Models

Models are the key entities for your database mapping. All tables in your database will be deducted from your model classes,
and the columns of a table will be deducted from the fields of a model.

You define a model by using the `@Model()` annotation on an abstract class. This class should only contain getters and have no constructor.

```dart
@Model()
abstract class Book {
  @PrimaryKey()
  String get id;

  String get title;
}
```

This model uses an additional `@PrimaryKey()` annotation on its `id` field. It will be translated into the following sql table:

```sql
TABLE "books" (
  "id" text NOT NULL,
  "title" text NOT NULL,
  PRIMARY KEY ("id")
);
```

You can also make any field **auto-increment** by using the `@AutoIncrement()` annotation. Auto-increment fields
must be of type **int**.

```dart
@Model()
abstract class Book {
  @PrimaryKey()
  @AutoIncrement()
  int get id;

  @AutoIncrement()
  int get someOtherValue;
}
```

### Relations

When using relational database systems, you model your data using relations, namely one-to-one,
one-to-many, or many-to-many relations.

When you want to specify a relation to another model, you simply use that model as the type of any field.
`stormberry` analyzes your models and automatically determines the correct relation types.

```dart

@Model()
abstract class Author {
  @PrimaryKey()
  String get id;

  String get name;
}

@Model()
abstract class Book {
  @PrimaryKey()
  String get id;

  String get title;
  Author get author;
}
```

The above code specifies a many-to-one relation between `Book` and `Author`. It is ok to specify
a relation only in one of the two models, but you could also specify the `List<Book> get books;`
in the `Author` model.

When only one side is specified, `stormberry` will default to a many-to-one or one-to-many relation.
To instead specify a one-to-one relation, simply specify `Book get book;` on the author side.

Generally, the correct relation type is determined by whether you use `List<...>` on one or both sides of the relation.
Depending on the relation type, it is also mandatory to specify a primary key field.

Notice how when you specify both sides of a relation, querying one of the models would lead to a
cyclic dependency. You can solve this by using `Views`.

## Views

For each table you can define a series of `View`s, which you can query for. A view is a modified
subset of fields of the table and resolved relations.

A `View` is helpful, when you have different points in your application where you want to query the
same model, but with different access demands, like privacy.

As an easy example take a typical `User` model. In the database, you might want to store some public
information for a user, like the username, together with some private information, like the address.
When a user requests its own data, you want to return all available data, public and private. But when
a user requests the information for another user, you want to only return the public information.
With `stormberry` you can handle this automatically by defining separate `View`s on the `User` model.

You define `View`s like this:

```dart
@Model(views: [
  View('Complete', [
    Field.view('posts', as: 'Info')
  ]),
  View('Reduced', [
    Field.hidden('address'),
    Field.hidden('posts'),
  ]),
])
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
  String get address;

  List<Post> get posts;
}

@Model(views: [
  View('Base', [
    Field.view('author', as: 'Reduced')
  ]),
  View('Info', [
    Field.hidden('author'),
  ]),
])
abstract class Post {
  @PrimaryKey()
  String get id;

  String get content;

  User get author;
}
```

Each `View` expects a name and an optional list of field modifiers:

- `Field.hidden()` hides a field from this view.
- `Field.view()` specifies a view to use for this field (which has to be a relation to another table)

The above model would result in the following view classes:

```dart
class CompleteUserView {
  String id;
  String name;
  String address;
  List<InfoPostView> posts;
}

class ReducedUserView {
  String id;
  String name;
}

class BasePostView {
  String id;
  String content;
  ReducedUserView author;
}

class InfoPostView {
  String id;
  String content;
}
```

As mentioned before, when you have two-way relations in your models you must use `View`s to resolve
any cyclic dependencies. `stormberry` can't resolve them for you, however it will warn you if it
detects any when trying to [migrate your database schema](#database-migration-tool).

### Serialization

When using views, you may need serialization capabilities to send them through an api. While stormberry does
not do serialization by itself, it enables you to use your favorite serialization package through custom annotations.

When specifying a view, add a target annotation to its constructor:

```dart
@Model(
  views: [
    View('SomeView', [/*field modififers*/], MappableClass())
  ]
)
```

This uses the '@MappableClass()' annotation from the [`dart_mappable`](https://pub.dev/packages/dart_mappable) package,
which will be placed on the resulting `SomeView` entity class. Check out [this example](https://github.com/schultek/stormberry/tree/develop/test/packages/serialization) to see
how this can be used to generate serialization extensions for these classes.

## Indexes

As an advanced configuration you can specify indexes on your table using the `TableIndex` class.
You can add indexes to your `@Model()` annotation like this:

```dart
@Model(
  views: [...],
  indexes: [
    TableIndex(name: 'my_index', columns: ['my_column'], unique: true)
  ],
)
abstract class MyModel {
  ...
}
```

Checkout the api documentation [here](https://pub.dev/documentation/stormberry/latest/stormberry/TableIndex-class.html)
for a description of the available parameters you can specify on an index.

## TypeConverters

When using a custom type for a model field, you need to create a custom `TypeConverter` for this
type. Implement a custom type converter like this:

```dart
@TypeConverter('point')
class LatLngConverter extends TypeConverter<LatLng> {

  @override
  dynamic encode(LatLng value) => PgPoint(value.latitude, value.longitude);

  @override
  LatLng decode(dynamic value) {
    if (value is PgPoint) {
      return LatLng(value.latitude, value.longitude);
    } else {
      var m = RegExp(r'\((.+),(.+)\)').firstMatch(value.toString());
      var lat = double.parse(m!.group(1)!.trim());
      var lng = double.parse(m.group(2)!.trim());
      return LatLng(lat, lng);
    }
  }
}
```

This transforms a value of type `LatLng` to the postgres data type `point`.
Note the usage of `PgPoint` as the encoded object, which comes from the `postgres` package.
For decoding, we also cover the case that the value is returned as a point literal instead of an
point object.

# Usage

When running the build using `dart pub run build_runner build`, `stormberry` will
generate a `Repository` for each model which you can use to query, insert, update or delete data
related to this model.

`Repositories` are extensions to the `Database` object, which you can create like this:

```dart
final db = Database(
  host: '127.0.0.1',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'root',
);
```

All parameters are optional. When a parameter is not provided, it is taken from the related
environment variable, or the shown default value.

## Repositories

A `Repository` exists for each `Model` on which you can

- **query** the model table and each of its views
- **insert** an entry to the model table
- **update** an entry of the model table
- **delete** an entry of the model table

You can get a models repository through its property accessor on the `Database` instance:
`var userRepo = db.users;`.

For the above example with two views `Complete` and `Reduced`, this would have the following
methods:

- `Future<CompleteUserView?> queryCompleteView(String id)`
- `Future<List<CompleteUserView>> queryCompleteViews()`
- `Future<ReducedUserView?> queryReducedView(String id)`
- `Future<List<ReducedUserView>> queryReducedViews()`
- `Future<void> insertOne(UserInsertRequest request)`
- `Future<void> insertMany(List<UserInsertRequest> requests)`
- `Future<void> updateOne(UserUpdateRequest request)`
- `Future<void> updateMany(List<UserUpdateRequest> requests)`
- `Future<void> deleteOne(String id)`
- `Future<void> updateMany(List<String> ids)`

Each method has a single and multi variant. `UserInsertRequest` and `UserUpdateRequest` are
special generated classes that enable type-safe inserts and updates while respecting data relations
and key constraints.

With this, `stormberry` also supports partial updates of a model. You could for example just update
the name of a user while keeping the other fields untouched like this:

```dart
await db.users.updateOne(UserUpdateRequest(id: 'abc', name: 'Tom'));
```

## Queries

You can specify a custom query with custom sql by extending the `Query<T, U>` class.
You will then need to implement the `Future<T> apply(Database db, U params)` method.

Additionally to the model tables, you can query the model views to automatically get all resolved
relations without needing to do manual joins. Table names are always plural, e.g. `users` and view
names are in the format as `complete_user_view`.

## Actions

You can also specify custom `Action`s to perform on your table.
Similar to the queries, you extend the `Action<T>` class and implement the
`Future<void> apply(Database db, T request)` method.

# Database Migration

Stormberry comes with a database migration tool, to create or update the schema of your database.

To use this run the following command from the root folder of your project.

```
dart pub run stormberry migrate
```

In order to connect to your database, provide the following environment variables:

- `DB_HOST_ADDRESS` (default: `127.0.0.1`)
- `DB_PORT` (default: `5432`)
- `DB_NAME` (default: `postgres`)
- `DB_USERNAME` (default: `postgres`)
- `DB_PASSWORD` (default: `root`)
- `DB_SSL` (default: `true`)
- `DB_SOCKET` (default: `false`)

The tool will analyze the database schema and log any needed changes. It then asks for
confirmation before applying the changes or aborting.

The tool supported the following options:

- `-h`: Shows the available options.
- `--db=<db_name>`: Specify the database name. Tool will ask if not specified.
- `--dry-run`: Logs any changes to the schema without writing to the database, and exists
  with code 1 if there are any.
- `--apply-changes`: Apply any changes without asking for confirmation.
- `-o=<folder>`: Specify an output folder. When used, this will output all migration statements to
  `.sql` files in this folder instead of applying them to the database.
