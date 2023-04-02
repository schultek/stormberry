You can create a database object like this:

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
