
When running the build using `dart run build_runner build`, `stormberry` will
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

---

<p align="right"><a href="../topics/Repositories-topic.html">Next: Repositories</a></p>
