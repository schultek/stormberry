
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

---

<p align="right"><a href="../topics/Queries--Actions-topic.html">Next: Queries & Actions</a></p>

