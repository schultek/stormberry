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
@Model(views: [#Complete, #Reduced])
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
  
  @HiddenIn(#Reduced)
  String get address;

  @ViewedIn(#Complete, as: #Info)
  @HiddenIn(#Reduced)
  List<Post> get posts;
}

@Model(views: [#Base, #Info])
abstract class Post {
  @PrimaryKey()
  String get id;

  String get content;

  @ViewedIn(#Base, as: #Reduced)
  @HiddenIn(#Info)
  User get author;
}
```

First define all views that you want of a model as a list of symbols. Then
you can modify specific fields for a view using these annotations

- `@HiddenIn(#SomeView)` removes the field from the view
- `@ViewedIn(#SomeView, as: #SomeOtherView)` modifies the field to use the specified view of the
  target type

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
detects any when trying to [migrate your database schema](../topics/Migration-topic.html).

---

<p align="right"><a href="../topics/Database-topic.html">Next: Database</a></p>
