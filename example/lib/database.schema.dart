// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint
// dart format off

import 'package:stormberry/migrate.dart';

final DatabaseSchema schema = DatabaseSchema.fromMap({
  "invoices": {
    "columns": {
      "id": {
        "type": "text"
      },
      "title": {
        "type": "text"
      },
      "invoice_id": {
        "type": "text"
      },
      "created_at": {
        "type": "timestamp",
        "default": "CURRENT_TIMESTAMP"
      },
      "account_id": {
        "type": "int8",
        "isNullable": true
      },
      "company_id": {
        "type": "text",
        "isNullable": true
      }
    },
    "constraints": [
      {
        "type": "primary_key",
        "column": "id"
      },
      {
        "type": "foreign_key",
        "column": "account_id",
        "target": "accounts.id",
        "on_delete": "set_null",
        "on_update": "cascade"
      },
      {
        "type": "foreign_key",
        "column": "company_id",
        "target": "companies.id",
        "on_delete": "set_null",
        "on_update": "cascade"
      }
    ],
    "indexes": []
  },
  "parties": {
    "columns": {
      "id": {
        "type": "text"
      },
      "name": {
        "type": "text"
      },
      "sponsor_id": {
        "type": "text",
        "isNullable": true
      },
      "date": {
        "type": "int8"
      }
    },
    "constraints": [
      {
        "type": "primary_key",
        "column": "id"
      },
      {
        "type": "foreign_key",
        "column": "sponsor_id",
        "target": "companies.id",
        "on_delete": "set_null",
        "on_update": "cascade"
      }
    ],
    "indexes": []
  },
  "billing_addresses": {
    "columns": {
      "city": {
        "type": "text"
      },
      "postcode": {
        "type": "text"
      },
      "name": {
        "type": "text"
      },
      "street": {
        "type": "text"
      },
      "account_id": {
        "type": "int8",
        "isNullable": true
      },
      "company_id": {
        "type": "text",
        "isNullable": true
      }
    },
    "constraints": [
      {
        "type": "foreign_key",
        "column": "account_id",
        "target": "accounts.id",
        "on_delete": "cascade",
        "on_update": "cascade"
      },
      {
        "type": "foreign_key",
        "column": "company_id",
        "target": "companies.id",
        "on_delete": "cascade",
        "on_update": "cascade"
      },
      {
        "type": "unique",
        "column": "account_id"
      }
    ],
    "indexes": []
  },
  "accounts": {
    "columns": {
      "id": {
        "type": "serial"
      },
      "first_name": {
        "type": "text"
      },
      "last_name": {
        "type": "text"
      },
      "location": {
        "type": "point"
      },
      "company_id": {
        "type": "text",
        "isNullable": true
      }
    },
    "constraints": [
      {
        "type": "primary_key",
        "column": "id"
      },
      {
        "type": "foreign_key",
        "column": "company_id",
        "target": "companies.id",
        "on_delete": "set_null",
        "on_update": "cascade"
      }
    ],
    "indexes": []
  },
  "accounts_parties": {
    "columns": {
      "account_id": {
        "type": "int8"
      },
      "party_id": {
        "type": "text"
      }
    },
    "constraints": [
      {
        "type": "primary_key",
        "column": "account_id\", \"party_id"
      },
      {
        "type": "foreign_key",
        "column": "account_id",
        "target": "accounts.id",
        "on_delete": "cascade",
        "on_update": "cascade"
      },
      {
        "type": "foreign_key",
        "column": "party_id",
        "target": "parties.id",
        "on_delete": "cascade",
        "on_update": "cascade"
      }
    ]
  },
  "companies": {
    "columns": {
      "id": {
        "type": "text"
      },
      "name": {
        "type": "text"
      }
    },
    "constraints": [
      {
        "type": "primary_key",
        "column": "id"
      }
    ],
    "indexes": []
  }
});
