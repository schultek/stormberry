## Queries

You can specify a custom query with custom sql by extending the `Query<T, U>` class.
You will then need to implement the `Future<T> apply(Database db, U params)` method.

```dart
class FindInfoPostByTitleQuery extends Query<InfoPostView?, QueryParams> {
  final String title;

  FindInfoPostByTitleQuery({required this.title});

  @override
  Future<InfoPostView?> apply(Database db, QueryParams params) async {
    final queryable = InfoPostViewQueryable();
    final tableName = queryable.tableAlias;
    final customQuery = """
      SELECT * FROM $tableName
      WHERE title='$title' 
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """;

    var postgreSQLResult = await db.query(customQuery, params.values);

    var objects = postgreSQLResult.map((row) => queryable.decode(TypedMap(row.toColumnMap()))).toList();
    return objects.isNotEmpty ? objects.first : null;
  }
}


```
then you can query via `db` like below

```dart
final postWithId = await db.posts.query(
    FindInfoPostByTitleQuery(title: 'post title'),
    QueryParams(),
);
```

## Actions

You can also specify custom `Action`s to perform on your table.
Similar to the queries, you extend the `Action<T>` class and implement the
`Future<void> apply(Database db, T request)` method.

```dart
class UpdateTitleAction extends Action<InfoPostView> {
  final String title;

  UpdateTitleAction(this.title);

  @override
  Future<void> apply(Database db, InfoPostView request) async {
    await db.query("""
      UPDATE posts
      SET title = @title
      WHERE id = @id
    """, {
      'title': title,
      'id': request.id,
    });
  }
}
```

then you can run the action via `db` like below

```dart
await db.posts.run(UpdateTitleAction(newTitle), infoPost);
```

Optionally you can define extension functions on Model Repositories for your custom Queries and Actions, just to make it more clear and concise. here is an extension function for the action we defined above on `PostRepository`

```dart
extension PostRespositoryX on PostRepository {
  Future<void> updatePostTitle(InfoPostView post, String newTitle) async {
    await run(UpdateTitleAction(title: newTitle), post);
  }
}
```

and this would be how you run that method via `db` object

```dart
await db.posts.updatePostTitle(infoPost, newTitle);
```

---

<p align="right"><a href="../topics/Migration-topic.html">Next: Migration</a></p>
