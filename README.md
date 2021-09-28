
# Stormberry

Stormberry is a strongly-typed ORM-like code-generation package to provide easy bindings between your dart classes and postgres database.
It supports all kinds of relations without any complex configuration.

# Outline

- [Get Started](#get-started)
- [Code Annotations](#code-annotations)
    - [Table Classes](#table-classes)
    - [Views](#views)
    - [Queries](#queries)
    - [Actions](#actions)
    - [Indexes](#indexes)
- [Database migration tool](#database-migration-tool)

> This package is still in active development. If you have any feedback or feature requests, write me and issue on github.

### Roadmap

- Features
    - Action constructor parameters
    - Query constructor parameters
- Documentation
    - Improve Readme
    - Improve example
- Testing & Maintenance
    - Improve code structure
    - Write tests
- Long Term
    - Be database agnostic (sub-packages)

# Get Started

To get started, add the following lines to your `pubspec.yaml`:

```yaml
dependencies:
  stormberry: ^0.2.3
```

In your code, specify a class that should act as a table like this:

```dart
@Table()
class User {
	@PrimaryKey()
	String id;
	String name;
	
	User(this.id, this.name);
}
```

Next, create a `build.yaml` in the root directory of your package and add this snippet:

```yaml
targets:
  $default:
    builders:
      stormberry:
        generate_for:
          # library that exposes all your table classes
          # modify this if to match your library file
          - lib/tables.dart 
```

In order to generate the serialization code, run the following command:

```shell script
pub run build_runner build
```

You'll need to re-run code generation each time you are making changes to your code. So for development time, use `watch` like this

```shell script
pub run build_runner watch
```

This will generate a `.schema.g.dart` file along with a `.schema.g.json` file.

Last step is to `import` the generated dart file wherever you want / need them.

# Code Annotations

You specify your database configuration by annotating some dart classes with the `@Table()` annotation. Your class then represents a single entity from this table.

## Views

For each table you can define a series of `View`s, which you can query for. A view is a subset of fields of the table and resolved relations.
When you have two-way relations in your models, with `View`s you have to make sure not to have any cyclic relations.

You specify the modified fields of the a `View` using the `@Field` annotation, more specific one of its three constructors.

- `@Field.hidden()` hides a specific field from the table
- `@Field.view()` specifies which view to use for this field (which has to be a relation to another table)
- `@Field.filtered()` specifies a filter (where clause) on this field (*TODO*)

## Queries

For querying a table or view, set a `Query` to your table. 
For each query you will have a custom `query()` method to call on your table.

Most of the time you will want to use the default `SingleQuery` or `MultiQuery` classes.
When wanting to query a view, use the `SingleQuery.forView()` or `MultiQuery.forView()` constructors.

You can specify a custom query with custom sql by extending the `Query<T, U>` class. 
You will then need to implement the `Future<T> apply(Database db, U params)` method.

## Actions

You can specify `Action`s to perform on your table. 
Similar to the queries, for each action a custom `doAction()` method is generated for you to use later.

Again you can choose from the default `Action`s or write a custom class. 
The available default actions are `SingleInsertAction`, `SingleUpdateAction` and `SingleDeleteAction` as well as their `Multi` variants.

## Indexes

As an advanced configuration you can specify indexes on your table using the `TableIndex` class.

# Database migration tool

Stormberry comes with a database migration tool, to create or update the schema of your database.

To use this run the following command from the root folder of your project.
```
flutter pub run stormberry
```

In order to connect to your database, provide the following environment variables: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` and `DB_SSL`. 
