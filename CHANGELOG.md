# Unreleased

- Added support for default column values via the `@Default` annotation.
- Added support for creating and updating many-to-many relations through the normal `insert` and `update` methods.

# 0.17.0

- Require dart sdk `>=3.7.0`.
- Update analyzer to `^8.1.0`, build to `^4.0.0` and source_gen to `^4.0.0`.
- Disable linting and formatting for generated files.
- Expose the programmatic migration api through the `'package:stormberry/migrate.dart'` import.

# 0.16.0

- Update analyzer dependency to `^7.0.0`
- Update dart_style dependency to `^3.0.0`
- Update source_gen dependency to `^2.0.0`

# 0.15.0

- Update `postgres` dependency to version `^3.4.5` (by [@alexandrim0](https://github.com/alexandrim0)).

# 0.14.0

- **BREAKING** Updated the `postgres` package to version `3.0.0` (by [@BreX900](https://github.com/BreX900)).

  To visit all the breaking changes see [their changelog](https://pub.dev/packages/postgres).
   
  - You no longer need to use the `Database` class, you can use `Connection.open` or `Pool` directly.
  - `Database` class now implements `Session` and `SessionExecutor` classes from `postgres` package.
  - Removed `Database.query` method in favour of `Session.execute` method.
  - Extension methods for accessing repositories now extend `Session`.
  - `Action` and `Query` now accept a `Session`
  
- **BREAKING** Generated repository methods are no longer wrapped in a transaction.

  Instead, wrap your database calls in a transaction yourself, e.g. by using `db.runTx()`.

- Added the ability to create a Pool for your database-

- Updated analyzer dependency to `^6.0.0`.
- Updated dart sdk constraints to `>=3.0.0 <4.0.0`.

# 0.13.1

- Fixed bug with boolean column in migration.

# 0.13.0

- Added `Table.defaultView` flag for referring to the default view of a table.
- [BREAKING] Removed model mixin from default view classes.
  - If needed this can now be specified manually using `ModelMeta` annotations.

- Fixed bug with using `@HiddenIn` on normal fields.
- Corrected naming of bool sql type to `boolean`.
- Fixed type cast for parameters in update queries.

- Moved documentation to dartdoc topics.
- Increased test coverage.

# 0.12.1

- Support generic type converters.

# 0.12.0

- Support self-joins. Models can now have relations to itself.
- Added `value` property to `QueryParams` to supply custom query parameters.
- Added `@BindTo()` annotation to resolve ambiguous field relations.

# 0.11.0

- Fixed wrong column types in update query.
- Improved handling of auto-increment ids.
- Added `ModelMeta` annotation to customize generated entity classes.

# 0.10.0

- [BREAKING] Switched to generating `part` files for each model.
  - Migrate by adding `part <myfile>.schema.dart` on top of each model file.
- [BREAKING] Changed how **View**s are defined.
  - The `@Model()` annotation now only defines the names of existing views as `Symbol`s: 
    `@Model(views: [#Full, #Reduced, #Other])`.
  - Field modifications are done by annotating the specific field with either `@HiddenIn(#MyView)`, 
    `@ViewedIn(#MyView, as: #OtherView)` and `@TransformedIn(#MyView, by: MyTransformer())`.
- The CLI supports setting connection values via command args or prompts missing values.
- Views are now virtual (queries) and not written to the database. This enables more flexibility for queries 
  and fixes some migration issues.
- All query inputs are now properly parameterized to prevent sql injections.
- [BREAKING] The `on conflict` clause for inserts is removed. Inserts now fail when a given key already exists.
- Added proper testing.

# 0.9.2

- Fixed bug with email encoding.

# 0.9.1

- Fixed bug with one-to-many relations.
- Added `DB_SOCKET` environment connection variable.

# 0.9.0

- Added support for enum serialization in models (by [@TimWhiting](https://github.com/TimWhiting))
- Api and documentation fixes

# 0.8.0

- Added support for serialization through custom annotations
- Improved migration cli and added support for manual migration output to .sql files
- Fixed bug with default views and value decoding

# 0.7.0

- Added `@AutoIncrement()` annotation for auto incrementing values
- Added support for multiple schemas when using the migration tool
- Fixed escaping of strings

# 0.6.4

- Fix data encoding

# 0.6.3

- Move QueryParams to public library

# 0.6.2

- Allow models to inherit fields from other classes

# 0.6.1

- Fix deep insert bug

# 0.6.0

- Update dependencies
- Cleanup lints

# 0.5.0

- Internal rewrite (again)
- Added documentation to README

# 0.4.0

- Rewrote view system
- Internal refactoring

# 0.3.0

- Update dependencies

# 0.2.3

- Fix encoding bug

# 0.2.2

- Update tool: Read json schema location from build.yaml

# 0.2.1

- Added delete actions

# 0.2.0

- Refactor and cleanup, first published version
- Added first README draft

# 0.1.1

- Use joins only for many-to-many
- Fix some generation bugs

# 0.1.0

- Initial development release
