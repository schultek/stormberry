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

***Note**: The model class acts mostly as a blueprint for your database tables. It is recommended to not use
this class directly in you application, but rather one of the generated entity classes. More on this later.* 

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

## Default Values

You can specify a SQL default value for a model field using the `@Default()` annotation.
The annotation takes a raw SQL expression string which will be emitted verbatim into the generated `CREATE TABLE` statement.

```dart
@Model()
abstract class Book {
  @PrimaryKey()
  String get id;

  // string default (note the single quotes are part of the value)
  @Default("'untitled'")
  String get title;

  // numeric default (no quotes)
  @Default('0')
  int get pageCount;

  // datetime default using the provided convenience constructor
  @Default.currentTimestamp()
  DateTime get createdAt;
}
```

When inserting a new value, any property that is not provided will be set to the default value.

```dart
db.books.insertOne(BookInsertRequest(
  id: 'book0' 
  // title, pageCount and createdAt are optional and 
  // will be set to their default values if not provided
));
```

## Relations

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
cyclic dependency. You can solve this by using [Views](../topics/Views-topic.html).

## Bindings

When you have multiple relations between the same types, it may be ambiguous fields refer to each other.
In those cases, you can use the `@BindTo(#otherField)` annotation like this:

```dart
@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  @BindTo(#author)
  List<Post> get posts;
  @BindTo(#likes)
  List<Post> get liked;
}

@Model()
abstract class Post {
  @PrimaryKey()
  String get id;

  @BindTo(#posts)
  User get author;
  @BindTo(#liked)
  List<User> get likes;
}
```

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

Checkout the api documentation [here](../stormberry/TableIndex-class.html)
for a description of the available parameters you can specify on an index.

## Converters

When using a custom type for a model field, you need to create a custom `TypeConverter` for this
type. Implement a custom type converter like this:

```dart
class LatLngConverter extends TypeConverter<LatLng> {
  const LatLngConverter() : super('point');
  
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
For decoding, we also cover the case that the value is returned as a point string literal instead of a
point object.

To use this converter specify it for a field of your model with:

```dart
@Model(...)
abstract class MyModel {
  ...

  // Custom Type
  @UseConverter(LatLngConverter())
  LatLng get location;
}
```

---

<p align="right"><a href="../topics/Views-topic.html">Next: Views</a></p>
