CREATE VIEW billing_addresses_view AS 
SELECT "billing_addresses".*
FROM "billing_addresses"
WHERE '_#dbf42d5d7461f07a564bb43b6e8d38ff097ba5ea#_' IS NOT NULL;

CREATE VIEW owner_invoices_view AS 
SELECT "invoices".*
FROM "invoices"
WHERE '_#e5f94a9602353fec4c4d2e04c795cf62ca4b1226#_' IS NOT NULL;

CREATE VIEW company_parties_view AS 
SELECT "parties".*
FROM "parties"
WHERE '_#088e3580cd83cc28fd25aa3ff86b9fc46addc894#_' IS NOT NULL;

CREATE VIEW member_companies_view AS 
SELECT "companies".*, "addresses"."data" as "addresses"
FROM "companies"
LEFT JOIN (
  SELECT "billing_addresses"."company_id",
    to_jsonb(array_agg("billing_addresses".*)) as data
  FROM "billing_addresses_view" "billing_addresses"
  GROUP BY "billing_addresses"."company_id"
) "addresses"
ON "companies"."id" = "addresses"."company_id"
WHERE '_#63bb7d78bea9d92382206080c274b26e8c3e3f1a#_' IS NOT NULL;

CREATE VIEW company_accounts_view AS 
SELECT "accounts".*, array_to_json(ARRAY ((
  SELECT *
  FROM jsonb_array_elements("parties".data) AS "parties"
  WHERE (parties -> 'sponsor_id') = to_jsonb (accounts.company_id)
)) ) AS "parties"
FROM "accounts"
LEFT JOIN (
  SELECT "accounts_parties"."account_id",
    to_jsonb(array_agg("parties".*)) as data
  FROM "accounts_parties"
  LEFT JOIN "company_parties_view" "parties"
  ON "parties"."id" = "accounts_parties"."party_id"
  GROUP BY "accounts_parties"."account_id"
) "parties"
ON "accounts"."id" = "parties"."account_id"
WHERE '_#e3332abebaed52c92240088408cde459d4269cd1#_' IS NOT NULL;

CREATE VIEW guest_parties_view AS 
SELECT "parties".*, row_to_json("sponsor".*) as "sponsor"
FROM "parties"
LEFT JOIN "member_companies_view" "sponsor"
ON "parties"."sponsor_id" = "sponsor"."id"
WHERE '_#ead223f933e4d5e9d76e71517fdce0d1621491c5#_' IS NOT NULL;

CREATE VIEW admin_companies_view AS 
SELECT "companies".*, "members"."data" as "members", "addresses"."data" as "addresses", "invoices"."data" as "invoices", "parties"."data" as "parties"
FROM "companies"
LEFT JOIN (
  SELECT "accounts"."company_id",
    to_jsonb(array_agg("accounts".*)) as data
  FROM "company_accounts_view" "accounts"
  GROUP BY "accounts"."company_id"
) "members"
ON "companies"."id" = "members"."company_id"
LEFT JOIN (
  SELECT "billing_addresses"."company_id",
    to_jsonb(array_agg("billing_addresses".*)) as data
  FROM "billing_addresses_view" "billing_addresses"
  GROUP BY "billing_addresses"."company_id"
) "addresses"
ON "companies"."id" = "addresses"."company_id"
LEFT JOIN (
  SELECT "invoices"."company_id",
    to_jsonb(array_agg("invoices".*)) as data
  FROM "owner_invoices_view" "invoices"
  GROUP BY "invoices"."company_id"
) "invoices"
ON "companies"."id" = "invoices"."company_id"
LEFT JOIN (
  SELECT "parties"."sponsor_id",
    to_jsonb(array_agg("parties".*)) as data
  FROM "company_parties_view" "parties"
  GROUP BY "parties"."sponsor_id"
) "parties"
ON "companies"."id" = "parties"."sponsor_id"
WHERE '_#466c9600172ef6af2874adf687244613a5a75add#_' IS NOT NULL;

CREATE VIEW user_accounts_view AS 
SELECT "accounts".*, row_to_json("billingAddress".*) as "billingAddress", "invoices"."data" as "invoices", row_to_json("company".*) as "company", "parties"."data" as "parties"
FROM "accounts"
LEFT JOIN "billing_addresses_view" "billingAddress"
ON "accounts"."id" = "billingAddress"."account_id"
LEFT JOIN (
  SELECT "invoices"."account_id",
    to_jsonb(array_agg("invoices".*)) as data
  FROM "owner_invoices_view" "invoices"
  GROUP BY "invoices"."account_id"
) "invoices"
ON "accounts"."id" = "invoices"."account_id"
LEFT JOIN "member_companies_view" "company"
ON "accounts"."company_id" = "company"."id"
LEFT JOIN (
  SELECT "accounts_parties"."account_id",
    to_jsonb(array_agg("parties".*)) as data
  FROM "accounts_parties"
  LEFT JOIN "guest_parties_view" "parties"
  ON "parties"."id" = "accounts_parties"."party_id"
  GROUP BY "accounts_parties"."account_id"
) "parties"
ON "accounts"."id" = "parties"."account_id"
WHERE '_#afa18427bb7f6bd4f6cf5872d9ae8ecccf56e227#_' IS NOT NULL;

CREATE VIEW admin_accounts_view AS 
SELECT "accounts".*, row_to_json("billingAddress".*) as "billingAddress", "invoices"."data" as "invoices", row_to_json("company".*) as "company", "parties"."data" as "parties"
FROM "accounts"
LEFT JOIN "billing_addresses_view" "billingAddress"
ON "accounts"."id" = "billingAddress"."account_id"
LEFT JOIN (
  SELECT "invoices"."account_id",
    to_jsonb(array_agg("invoices".*)) as data
  FROM "owner_invoices_view" "invoices"
  GROUP BY "invoices"."account_id"
) "invoices"
ON "accounts"."id" = "invoices"."account_id"
LEFT JOIN "member_companies_view" "company"
ON "accounts"."company_id" = "company"."id"
LEFT JOIN (
  SELECT "accounts_parties"."account_id",
    to_jsonb(array_agg("parties".*)) as data
  FROM "accounts_parties"
  LEFT JOIN "guest_parties_view" "parties"
  ON "parties"."id" = "accounts_parties"."party_id"
  GROUP BY "accounts_parties"."account_id"
) "parties"
ON "accounts"."id" = "parties"."account_id"
WHERE '_#afa18427bb7f6bd4f6cf5872d9ae8ecccf56e227#_' IS NOT NULL;