Stormberry comes with a database migration system, to create or update the schema of your database.

You can either call the migration tool from your terminal, or use the programmatic migration API.

## Migration CLI

To use the migration CLI run the following command from the root folder of your project:

```
dart run stormberry migrate
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
- `--host=<host_address>`: Specify the database host address. Tool will ask if not specified.
- `--port=<port>`: Specify the database port. Tool will ask if not specified.
- `--username=<username>`: Specify the database username. Tool will ask if not specified.
- `--password=<password>`: Specify the database password. Tool will ask if not specified.
- `--[no-]ssl`: Specify whether or not this connection should connect securely.
- `--[no-]unix-socket`: Specify Whether or not the connection is made via unix socket.
- `--defaults`: Specify Whether to use default values except for the values provided via arguments or environment variables.
- `--dry-run`: Logs any changes to the schema without writing to the database, and exists
  with code 1 if there are any.
- `--apply-changes`: Apply any changes without asking for confirmation.
- `-o=<folder>`: Specify an output folder. When used, this will output all migration statements to
  `.sql` files in this folder instead of applying them to the database.

---

## Migration API

To migrate your database from your own code, first enable the `database_schema` builder like this:

```yaml
// build.yaml
targets:
  $default:
    builders:
      stormberry|database_schema:
        enabled: true
```

This will generate a `lib/database.schema.dart` file next time you run code generation, containing a global `DatabaseSchema schema` variable of your current schema.

To migrate your database to this schema, do the following:

```dart
// Import the 'migrate.dart' library.
import 'package:stormberry/migrate.dart';

Future<void> migrate() async {
  // 1. Connect to your database
  final Database db = ...

  // 2. Compute the schema diff between your live database schema and the generated target `schema`.
  final diff = await schema.computeDiff(db);

  // 3. (Optional) Print the schema diff to stdout.
  diff.printToConsole();

  try {
    // Always use a transaction to not break your database!!
    await db.runTx((session) async {

      // 4. Apply the necessary patches to migrate to the target schema.
      await diff.patch(session);
    });
    print('Migration succeeded');
  } catch (e) {
    print('Migration failed. All changes reverted.');
  }
}
```
