
# Stormberry

Stormberry is an strongly-typed ORM-like code-generation package to provide easy bindings between your dart classes and postgres database.
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

To get started import `stormberry` and run the code-generation.
You also have to annotate your classes used as database tables.

# Code Annotations

You specify your database configuration by annotating some dart classes

## Table Classes

The `@Table()` annotation is the main point for your configuration.

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
