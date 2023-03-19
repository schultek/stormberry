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

---

<p align="right"><a href="../topics/Migration-topic.html">Next: Migration</a></p>
