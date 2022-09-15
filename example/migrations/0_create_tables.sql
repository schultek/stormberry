CREATE TABLE IF NOT EXISTS "accounts" (
  "id" serial NOT NULL,
  "first_name" text NOT NULL,
  "last_name" text NOT NULL,
  "location" point NOT NULL,
  "data" serial NOT NULL,
  "company_id" text NULL
);

CREATE TABLE IF NOT EXISTS "billing_addresses" (
  "account_id" int8 NULL,
  "company_id" text NULL,
  "city" text NOT NULL,
  "postcode" text NOT NULL,
  "name" text NOT NULL,
  "street" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "companies" (
  "id" text NOT NULL,
  "name" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "invoices" (
  "account_id" int8 NULL,
  "company_id" text NULL,
  "id" text NOT NULL,
  "title" text NOT NULL,
  "invoice_id" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "parties" (
  "sponsor_id" text NULL,
  "id" text NOT NULL,
  "name" text NOT NULL,
  "date" int8 NOT NULL
);

CREATE TABLE IF NOT EXISTS "accounts_parties" (
  "account_id" int8 NOT NULL,
  "party_id" text NOT NULL
);