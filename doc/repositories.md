When running the build using `dart run build_runner build`, `stormberry` will
generate a `Repository` for each model which you can use to query, insert, update or delete data
related to this model.

You can get a models repository through its property accessor on the `Database` instance:
`var userRepository = db.users;`.

A `Repository` exists for each `Model` on which you can

- **query** the model table and each of its views
- **insert** an entry to the model table
- **update** an entry of the model table
- **delete** an entry of the model table

For the above example with two views `Complete` and `Reduced`, this would have the following
methods:

- `Future<CompleteUserView?> queryCompleteView(String id)`
- `Future<List<CompleteUserView>> queryCompleteViews([QueryParams? params])`
- `Future<ReducedUserView?> queryReducedView(String id)`
- `Future<List<ReducedUserView>> queryReducedViews([QueryParams? params])`
- `Future<void> insertOne(UserInsertRequest request)`
- `Future<void> insertMany(List<UserInsertRequest> requests)`
- `Future<void> updateOne(UserUpdateRequest request)`
- `Future<void> updateMany(List<UserUpdateRequest> requests)`
- `Future<void> deleteOne(String id)`
- `Future<void> deleteMany(List<String> ids)`

Each method has a single and multi variant. `UserInsertRequest` and `UserUpdateRequest` are
special generated classes that enable type-safe inserts and updates while respecting data relations
and key constraints.

With this, `stormberry` also supports partial updates of a model. You could for example just update
the name of a user while keeping the other fields untouched like this:

```dart
await db.users.updateOne(UserUpdateRequest(id: 'abc', name: 'Tom'));
```

#### QueryParams

Query methods that return a list of models will accept a `QueryParams` argument 
where you can set conditions for you query like where conditions for example.

```dart
// Check if user already exists
final matchingUser = (await db.users.queryUsers(const QueryParams(
  where: "email='test@test.de'",
)));
```

**NOTE**: Alternatively to avoid SQL injection it is recommended to use `values` property of `QueryParams` like below example

```dart
// Check if user already exists
final matchingUser = (await db.users.queryUsers(const QueryParams(
  where: 'email=@email',
  values: {'email': 'test@test.de'},
)));
```

---

<p align="right"><a href="../topics/Queries%20&%20Actions-topic.html">Next: Queries & Actions</a></p>

