Stormberry comes with a database migration tool, to create or update the schema of your database.

To use this run the following command from the root folder of your project.

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

*🎉 Congrats, you followed the tour until the end. Now you know everything about this package.*
